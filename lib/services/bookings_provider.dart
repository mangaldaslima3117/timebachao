import 'package:bookmyservice/core/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/booking_model.dart';
import '../models/service_model.dart';

class BookingsNotifier extends StateNotifier<AsyncValue<List<BookingModel>>> {
  BookingsNotifier() : super(const AsyncValue.loading()) {
    DateFormat dateFormat2 = DateFormat('dd-MM-yyyy');
    _watchBookings();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(seconds: 1));
    loadBookingsWithDateRange(
        dateFormat2.format(start), dateFormat2.format(end));
    filterByDate(start, end);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BookingModel> _filteredBookings = [];

  // Call this when bookings are loaded
  void setBookings(List<BookingModel> bookings) {
    state = AsyncValue.data(bookings);
    _filteredBookings = bookings;
    debugPrint('Bookings loaded: ${_filteredBookings.length}');
  }

  // Watches all bookings in real-time
  void _watchBookings() {
    _firestore.collection('bookings').snapshots().listen((snapshot) {
      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        return BookingModel.fromMap({...data, 'bookingId': doc.id});
      }).toList();

      //Sort bookings by bookingDate in descending order
      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      setBookings(bookings);
      state = AsyncValue.data(bookings);
    }, onError: (e, stack) {
      state = AsyncValue.error(e, stack);
    });
  }

  /// Fetch bookings for the current month from Firestore
  Future<void> loadBookingsWithDateRange(String start, String end) async {
    try {
      debugPrint(
          'loadBookingsWithDateRange Start date:: $start, End date: $end');

      final snapshot = await _firestore
          .collection('bookings')
          .where('timeSlot.serviceDate', isGreaterThanOrEqualTo: start)
          .where('timeSlot.serviceDate', isLessThanOrEqualTo: end)
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        return BookingModel.fromMap({...data, 'bookingId': doc.id});
      }).toList();
      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      _filteredBookings = bookings;
      state = AsyncValue.data(bookings);

      debugPrint(
          'loadBookingsWithDateRange Current month bookings loaded: ${_filteredBookings.length}');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadBookingsByMaidWithDateRange(
      String start, String end, String maidId) async {
    try {
      debugPrint('Start date: $start, End date: $end');

      final snapshot = await _firestore
          .collection('bookings')
          .where('maidId', isEqualTo: maidId) // <-- Filter by maid
          .where('bookedOn', isGreaterThanOrEqualTo: start)
          .where('bookedOn', isLessThanOrEqualTo: end)
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        return BookingModel.fromMap({...data, 'bookingId': doc.id});
      }).toList();

      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      state = AsyncValue.data(bookings);
      _filteredBookings = bookings;
      debugPrint('Current month bookings loaded: ${bookings.length}');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Create a booking
  Future<void> createBooking(BookingModel booking) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(booking.bookingId)
          .set(booking.toMap());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String> createBookingsBatch(BookingModel booking) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final bookingsCollection = firestore.collection('bookings');
    List<String> duplicateMessages = [];

    for (int i = 0; i < booking.bookingSlots.length; i++) {
      final slot = booking.bookingSlots[i];

      final duplicateMsg = await checkDuplicateBooking(
        serviceDate: slot.serviceDate!,
        startTime: slot.startTime,
        endTime: slot.endTime,
        services: booking.services,
      );

      if (duplicateMsg != null) {
        duplicateMessages.add(duplicateMsg);
        continue;
      }

      final newBooking = booking.copyWith(
        bookingId: DateTime.now().millisecondsSinceEpoch.toString(),
        totalPrice: booking.services.fold(
            0,
            (total, s) =>
                total! + s.finalPrice),
        startDate: slot.assignedBy,
        timeSlot: slot,
      );

      final docRef = bookingsCollection
          .doc(newBooking.bookingId.isEmpty ? null : newBooking.bookingId);
      batch.set(docRef, newBooking.toMap());
    }

    await batch.commit();
    return duplicateMessages.isNotEmpty ? duplicateMessages.join('\n') : '';
  }

  Future<void> addOrUpdateCustomer(BookingModel booking) async {
    try {
      await _firestore
          .collection('customers')
          .doc(booking.customerInfo.phone)
          .set(booking.customerInfo.toMap());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Update a booking
  Future<void> updateBooking(BookingModel booking) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(booking.bookingId)
          .update(booking.toMap());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Accept booking (update status)
  Future<void> acceptBooking(String bookingId) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'accepted'});
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Reject booking (update status)
  Future<void> rejectBooking(String bookingId) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'rejected'});
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBookingStatus(
      BookingModel currentBooking, String status) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(currentBooking.bookingId)
          .update({
        'serviceStatus': status,
        'serviceCompletedTime': currentBooking.serviceCompletedTime,
        'assignedTime': currentBooking.assignedTime,
        'assignedBy': currentBooking.assignedBy,
        'maidId': currentBooking.maidId,
        'maid': currentBooking.maid?.toMap(),
      });

      // Optionally update local state if needed
      _updateLocalBookingStatus(currentBooking, status);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> assignMaid(BookingModel booking) async {
    try {
      await _firestore.collection('bookings').doc(booking.bookingId).update({
        'maidId': booking.maid!.id,
        'maid': booking.maid!.toMap(),
        'assignedTime': booking.assignedTime,
        'assignedBy': booking.assignedBy,
      });
      _updateLocalBookingStatus(booking, booking.serviceStatus);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _updateLocalBookingStatus(BookingModel booking, String status) {
    final currentBookings = state.valueOrNull;
    if (currentBookings == null) return;

    final updatedList = currentBookings.map((b) {
      if (b.bookingId == booking.bookingId) {
        return b.copyWith(bookingId: booking.bookingId);
      }
      return b;
    }).toList();

    state = AsyncValue.data(updatedList);
  }

  /// Filter bookings by a custom date range
  void filterByDate(DateTime start, DateTime end) {
    final allBookings = state.value ?? [];
    _filteredBookings = allBookings.where((b) {
      return b.bookingDate
              .isAfter(start.subtract(const Duration(seconds: 1))) &&
          b.bookingDate.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    // Update state with filtered list so UI reacts
    state = AsyncValue.data(_filteredBookings);
  }

  Future<BookingModel?> getLatestBookingByCustomerId(String customerId) async {
    try {
      debugPrint('Fetching latest booking for customerId: $customerId');
      BookingModel booking = BookingModel.getDefaultBookingModel();

      final bookings = state.valueOrNull;
      debugPrint(
          'getLatestBookingByCustomerId Bookings count: ${bookings?.length ?? 0}');
      booking = bookings!.isNotEmpty
          ? bookings.firstWhere(
              (element) => element.customerInfo.phone == customerId,
              orElse: BookingModel.getDefaultBookingModel)
          : booking;

      return booking;
    } catch (e) {
      debugPrint('Error fetching latest booking: $e');
      return null;
    }
  }

  List<BookingModel> get filteredBookings => _filteredBookings;

  double get totalRevenue => _filteredBookings
      .where((b) => b.serviceStatus.toLowerCase() == AppConstants.completed)
      .fold(0.0, (total, b) => total + b.totalPrice);

  double get totalCommission => _filteredBookings
      .where((b) => b.serviceStatus.toLowerCase() == AppConstants.completed)
      .fold(
          0.0,
          (total, b) =>
              total + (b.totalPrice * (b.maid!.commissionPercentage / 100)));

  double get totalProfit => totalRevenue - totalCommission;

  int get totalBookings => _filteredBookings.length;

  int get completedCount => _filteredBookings
      .where((b) => b.serviceStatus.toLowerCase() == AppConstants.completed)
      .length;

  int get cancelledCount => _filteredBookings
      .where((b) => b.serviceStatus.toLowerCase() == AppConstants.cancelled)
      .length;

  Future<void> updatePaymentInfo(
      BookingModel currentBooking, String status) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(currentBooking.bookingId)
          .update({
        'paymentInfo': currentBooking.paymentInfo!.toMap(),
      });

      // Optionally update local state if needed
      _updateLocalBookingStatus(currentBooking, status);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateMaidAssignment(BookingModel booking) async {
    try {
      await _firestore.collection('bookings').doc(booking.bookingId).update({
        'maid': booking.maid?.toMap(),
        'bookingSlots':
            booking.bookingSlots.toList().map((slot) => slot.toMap()).toList(),
      });

      _updateLocalBookingStatus(booking, booking.serviceStatus);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> checkDuplicateBooking({
    required String serviceDate,
    required String startTime,
    required String endTime,
    required List<ServiceModel> services,
  }) async {
    final bookingsCollection =
        FirebaseFirestore.instance.collection('bookings');

    final existingBookingSnapshot = await bookingsCollection
        .where('timeSlot.serviceDate', isEqualTo: serviceDate)
        .where('timeSlot.startTime', isEqualTo: startTime)
        .where('timeSlot.endTime', isEqualTo: endTime)
        .get();

    for (var doc in existingBookingSnapshot.docs) {
      final existingBooking = doc.data();
      final existingServices =
          List<Map<String, dynamic>>.from(existingBooking['services'] ?? []);

      for (var service in services) {
        final exists = existingServices
            .any((existingService) => existingService['id'] == service.id);

        if (exists) {
          return "Service '${service.name}' is already booked for $serviceDate ($startTime - $endTime)";
        }
      }
    }

    return null; // No duplicate found
  }
}

// Riverpod provider
final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingModel>>>(
  (ref) => BookingsNotifier(),
);

final bookingByIdProvider =
    Provider.family<BookingModel?, String>((ref, bookingId) {
  final bookings = ref.watch(bookingsProvider).valueOrNull;
  if (bookings == null) return null;

  return bookings.firstWhere(
    (b) => b.bookingId == bookingId,
    orElse: () => BookingModel.getDefaultBookingModel(),
  );
});

final bookingByMaidIdProvider =
    Provider.family<List<BookingModel>?, String>((ref, maidId) {
  final bookings = ref.watch(bookingsProvider).valueOrNull;
  if (bookings == null) return null;
  final maidBookings =
      bookings.where((b) => isBookingAssignedToMaid(b, maidId)).toList();
  debugPrint('Filtered bookings for maidId $maidId: ${maidBookings.length}');
  return maidBookings;
});

bool isBookingAssignedToMaid(BookingModel booking, String maidId) {
  final normalizedMaidId = maidId.trim();
  if (normalizedMaidId.isEmpty) return false;

  if ((booking.maidId ?? '').trim() == normalizedMaidId) return true;
  if ((booking.maid?.id ?? '').trim() == normalizedMaidId) return true;

  return booking.bookingSlots.any(
    (slot) => (slot.maidId ?? '').trim() == normalizedMaidId,
  );
}
