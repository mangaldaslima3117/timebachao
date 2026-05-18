import 'package:bookmyservice/core/presentation/maid/services/current_maid_provider.dart';
import 'package:bookmyservice/core/utils/app_constants.dart';
import 'package:bookmyservice/models/booking_model.dart';
import 'package:bookmyservice/models/maid_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/earnings_summary.dart';
import '../../../../services/bookings_provider.dart';

final maidEarningsProvider = FutureProvider<EarningsSummary?>((ref) async {
  final maidId = await ref.watch(maidIdProvider.future);
  final currentMaid = ref.watch(currentMaidProvider);
  final bookingsAsync = ref.watch(bookingsProvider);

  return bookingsAsync.when(
    data: (bookings) {
      if (maidId == null || maidId.isEmpty) {
        return EarningsSummary.empty();
      }

      final filtered = bookings
          .where((b) =>
              isBookingAssignedToMaid(b, maidId) &&
              b.serviceStatus == AppConstants.completed)
          .toList();

      // ── Grab commission % from the first booking's maid, ──────────────
      // fallback to 0 if maid is null on the booking
      final commissionPercent = _commissionPercentageForMaid(
        currentMaid: currentMaid,
        bookings: filtered,
      );

      final totalEarnings = filtered.fold(0.0, (sum, b) => sum + b.totalPrice);

      final commissionAmount = filtered.fold(
        0.0,
        (sum, b) =>
            sum +
            (b.totalPrice *
                (_commissionPercentageForBooking(b, commissionPercent) / 100)),
      );

      final netEarnings = totalEarnings - commissionAmount;

      final completedCount = filtered.length; // already filtered to completed

      // ── cancelledCount was wrongly counting completed — fixed ──────────
      final cancelledCount = bookings
          .where((b) =>
              isBookingAssignedToMaid(b, maidId) &&
              b.serviceStatus == AppConstants.cancelled)
          .length;

      return EarningsSummary(
        totalOrders: filtered.length,
        totalEarnings: totalEarnings,
        commissionPercent: commissionPercent, // ✅ was hardcoded 0
        commissionAmount: commissionAmount,
        netEarnings: netEarnings,
        completedCount: completedCount,
        cancelledCount: cancelledCount,
      );
    },
    error: (_, __) => null,
    loading: () => null,
  );
});

double _commissionPercentageForMaid({
  required MaidModel? currentMaid,
  required List<BookingModel> bookings,
}) {
  final currentMaidPercentage = currentMaid?.commissionPercentage ?? 0;
  if (currentMaidPercentage > 0) return currentMaidPercentage;

  for (final booking in bookings) {
    final bookingMaidPercentage = booking.maid?.commissionPercentage ?? 0;
    if (bookingMaidPercentage > 0) return bookingMaidPercentage;
    if (booking.commissionPercentage > 0) {
      return booking.commissionPercentage.toDouble();
    }
  }

  return 0;
}

double _commissionPercentageForBooking(
  BookingModel booking,
  double fallbackPercentage,
) {
  final bookingMaidPercentage = booking.maid?.commissionPercentage ?? 0;
  if (bookingMaidPercentage > 0) return bookingMaidPercentage;
  if (booking.commissionPercentage > 0) {
    return booking.commissionPercentage.toDouble();
  }
  return fallbackPercentage;
}

final maidEarningsByIdProvider =
    FutureProvider.family<EarningsSummary?, MaidModel?>((ref, maid) async {
  final bookingsAsync = ref.watch(bookingsProvider);

  return bookingsAsync.when(
    data: (bookings) {
      final filtered =
          bookings.where((b) => isBookingAssignedToMaid(b, maid!.id)).toList();
      debugPrint('Filtered bookings: ${filtered.length}');
      double totalEarnings = filtered.fold(
          0.0,
          (sum, b) =>
              sum +
              (b.serviceStatus != AppConstants.cancelled ? b.totalPrice : 0.0));

      final commissionAmount = filtered.fold(
        0.0,
        (sum, b) =>
            sum +
            (b.serviceStatus != AppConstants.cancelled
                ? (b.totalPrice * (b.maid!.commissionPercentage / 100))
                : 0.0),
      );
      //final commissionAmount = (commissionPercent / 100) * totalEarnings;
      final netEarnings = totalEarnings - commissionAmount;
      final completedCount = filtered.fold(
        0,
        (sum, b) => sum + (b.serviceStatus == AppConstants.completed ? 1 : 0),
      );
      final cancelledCount = filtered.fold(
        0,
        (sum, b) => sum + (b.serviceStatus == AppConstants.cancelled ? 1 : 0),
      );

      return EarningsSummary(
        totalOrders: filtered.length,
        totalEarnings: totalEarnings,
        commissionPercent: maid!.commissionPercentage,
        commissionAmount: commissionAmount,
        netEarnings: netEarnings,
        completedCount: completedCount,
        cancelledCount: cancelledCount,
      );
    },
    error: (_, __) => null,
    loading: () => null,
  );
});
