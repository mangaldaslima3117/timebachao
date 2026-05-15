import 'package:bookmyservice/models/address_model.dart';
import 'package:bookmyservice/models/customer_model.dart';
import 'package:bookmyservice/models/maid_model.dart';

import 'payment_info_model.dart';
import 'service_model.dart';
import 'slot_model.dart';

class BookingModel {
  final String bookingId;
  final String appAccountId;
  final String customerId;
  String? maidId;
  final List<ServiceModel> services;
  final String status;
  final double totalPrice;
  AddressModel customerAddress;
  final DateTime bookingDate;
  final TimeSlotModel timeSlot; //Individual time slot for the booking
  final String? note;
  final bool assignedByAdmin;
  String serviceCompletedTime;
  final String serviceCompletedMarkedById;
  final String serviceCompletedMarkedByName;
  final String
      serviceStatus; // Added field for service status 1= Booking, 2= InProgress, 3= Completed, 4= Cancelled
  final String
      cancellationReason; // Added field for cancellation reason or rejection reason
  final String bookedBy; // Added field for who booked the service
  MaidModel? maid; // Added field for Maid details
  final String totalTimeTaken; //
  CustomerModel customerInfo;
  String? assignedTime; // Added field for who assigned the booking
  String? assignedBy; // Added field for who assigned the booking
  String?
      bookedOn; // Added field for when the booking was made for filtering purposes
  num commissionPercentage = 0.0; // Added field for commission percentage
  PaymentInfoModel? paymentInfo; // Added field for payment info
  final String startDate;
  final String endDate;
  List<TimeSlotModel> bookingSlots; // THIS IS USED FOR BOOKING SLOTS
  final double taxPercentage; // Added field for tax percentage
  final String parentBookingId; // Added field for parent booking ID

  BookingModel({
    required this.bookingId,
    required this.appAccountId,
    required this.customerId,
    required this.maidId,
    required this.services,
    required this.status,
    required this.totalPrice,
    required this.customerAddress,
    required this.bookingDate,
    required this.timeSlot,
    this.note,
    this.assignedByAdmin = false,
    required this.serviceCompletedTime,
    required this.serviceCompletedMarkedById,
    required this.serviceCompletedMarkedByName,
    required this.serviceStatus,
    required this.cancellationReason,
    required this.bookedBy,
    required this.maid,
    required this.totalTimeTaken,
    required this.customerInfo,
    required this.assignedTime,
    required this.assignedBy,
    required this.bookedOn,
    required this.commissionPercentage,
    required this.paymentInfo,
    required this.startDate,
    required this.endDate,
    required this.bookingSlots,
    required this.taxPercentage,
    required this.parentBookingId,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      bookingId: map.containsKey('bookingId') ? map['bookingId'] ?? '' : '',
      appAccountId:
          map.containsKey('appAccountId') ? map['appAccountId'] ?? '' : '',
      customerId: map.containsKey('customerId') ? map['customerId'] ?? '' : '',
      maidId: map.containsKey('maidId') ? map['maidId'] ?? '' : '',
      services: map.containsKey('services') && map['services'] is List
          ? (map['services'] as List<dynamic>)
              .map((e) => ServiceModel.fromMap(e, e['id'] ?? ''))
              .toList()
          : [],
      status: map.containsKey('status') ? map['status'] ?? '' : '',
      totalPrice: map.containsKey('totalPrice')
          ? (map['totalPrice'] ?? 0).toDouble()
          : 0.0,
      customerAddress: AddressModel.fromMap(
        map.containsKey('customerAddress') ? map['customerAddress'] ?? {} : {},
      ),
      bookingDate: map.containsKey('bookingDate') && map['bookingDate'] != null
          ? DateTime.tryParse(map['bookingDate']) ?? DateTime.now()
          : DateTime.now(),
      timeSlot: map.containsKey('timeSlot')
          ? TimeSlotModel.fromMap(map['timeSlot'])
          : TimeSlotModel.defaultTimeSlot(),
      note: map.containsKey('note') ? map['note'] ?? '' : '',
      assignedByAdmin: map.containsKey('assignedByAdmin')
          ? map['assignedByAdmin'] ?? false
          : false,
      serviceCompletedTime: map.containsKey('serviceCompletedTime')
          ? map['serviceCompletedTime'] ?? ''
          : '',
      serviceCompletedMarkedById: map.containsKey('serviceCompletedMarkedById')
          ? map['serviceCompletedMarkedById'] ?? ''
          : '',
      serviceCompletedMarkedByName:
          map.containsKey('serviceCompletedMarkedByName')
              ? map['serviceCompletedMarkedByName'] ?? ''
              : '',
      serviceStatus:
          map.containsKey('serviceStatus') ? map['serviceStatus'] ?? '1' : '1',
      cancellationReason: map.containsKey('cancellationReason')
          ? map['cancellationReason'] ?? ''
          : '',
      bookedBy: map.containsKey('bookedBy') ? map['bookedBy'] ?? '' : '',
      maid: map.containsKey('maid') && map['maid'] != null
          ? MaidModel.fromMap(map['maid'], map['maid']['id'] ?? '')
          : null,
      totalTimeTaken:
          map.containsKey('totalTimeTaken') ? map['totalTimeTaken'] ?? '' : '',
      customerInfo: CustomerModel.fromMap(
        map.containsKey('customerInfo') ? map['customerInfo'] ?? {} : {},
        '',
      ),
      assignedTime:
          map.containsKey('assignedTime') ? map['assignedTime'] ?? '' : '',
      assignedBy: map.containsKey('assignedBy') ? map['assignedBy'] ?? '' : '',
      bookedOn: map.containsKey('bookedOn') ? map['bookedOn'] ?? '' : '',
      commissionPercentage: map.containsKey('commissionPercentage')
          ? (map['commissionPercentage'] as num?)?.toDouble() ?? 0.0
          : 0.0,
      paymentInfo: map.containsKey('paymentInfo') && map['paymentInfo'] != null
          ? PaymentInfoModel.fromMap(map['paymentInfo'])
          : PaymentInfoModel.defaultPayment(),
      startDate: map.containsKey('startDate') ? map['startDate'] ?? '' : '',
      endDate: map.containsKey('endDate') ? map['endDate'] ?? '' : '',
      bookingSlots:
          map.containsKey('bookingSlots') && map['bookingSlots'] is List
              ? (map['bookingSlots'] as List<dynamic>)
                  .map((e) => TimeSlotModel.fromMap(e))
                  .toList()
              : [],
          taxPercentage: map.containsKey('taxPercentage')
          ? (map['taxPercentage'] as num?)?.toDouble() ?? 0.0
          : 0.0,
      parentBookingId: map.containsKey('parentBookingId')
          ? map['parentBookingId'] ?? ''
          : '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'appAccountId': appAccountId,
      'customerId': customerId,
      'maidId': maidId,
      'services': services.map((e) => e.toMap()).toList(),
      'status': status,
      'totalPrice': totalPrice,
      'customerAddress': customerAddress.toMap(),
      'bookingDate': bookingDate.toIso8601String(),
      'timeSlot': timeSlot.toMap(),
      'note': note,
      'assignedByAdmin': assignedByAdmin,
      'serviceCompletedTime': serviceCompletedTime,
      'serviceCompletedMarkedById': serviceCompletedMarkedById,
      'serviceCompletedMarkedByName': serviceCompletedMarkedByName,
      'serviceStatus': serviceStatus,
      'cancellationReason': cancellationReason,
      'bookedBy': bookedBy,
      'maid': maid?.toMap(), // Added field for Maid details
      'totalTimeTaken': totalTimeTaken,
      'customerInfo': customerInfo.toMap(),
      'assignedTime': assignedTime,
      'assignedBy': assignedBy, // Added field for who assigned the booking
      'bookedOn': bookedOn, // Added field for when the booking was made
      'commissionPercentage': commissionPercentage,
      'paymentInfo': paymentInfo?.toMap(), // Added field for payment info
      'bookingSlots': bookingSlots.map((e) => e.toMap()).toList(),
      'startDate': startDate,
      'endDate': endDate,
      'taxPercentage': taxPercentage, // Added field for tax percentage
      'parentBookingId': parentBookingId, // Added field for parent booking ID
    };
  }

  //Copy with method
  BookingModel copyWith({
    String? bookingId,
    String? appAccountId,
    String? customerId,
    String? maidId,
    List<ServiceModel>? services,
    String? status,
    double? totalPrice,
    AddressModel? customerAddress,
    DateTime? bookingDate,
    TimeSlotModel? timeSlot,
    String? note,
    bool? assignedByAdmin,
    String? serviceCompletedTime,
    String? serviceCompletedMarkedById,
    String? serviceCompletedMarkedByName,
    String? serviceStatus,
    String? cancellationReason,
    String? bookedBy,
    MaidModel? maid,
    String? totalTimeTaken,
    CustomerModel? customerInfo,
    String? assignedTime,
    String? assignedBy,
    String? bookedOn, // Added field for when the booking was made
    num? commissionPercentage, // Added field for commission percentage
    PaymentInfoModel? paymentInfo, // Added field for payment info
    List<TimeSlotModel>? bookingSlots, // Added field for available time slots
    String? startDate,
    String? endDate, // Added field for start and end date of the booking
    double? taxPercentage, // Added field for tax percentage
    String? parentBookingId, // Added field for parent booking ID
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      appAccountId: appAccountId ?? this.appAccountId,
      customerId: customerId ?? this.customerId,
      maidId: maidId ?? this.maidId,
      services: services ?? this.services,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      customerAddress: customerAddress ?? this.customerAddress,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      note: note ?? this.note,
      assignedByAdmin: assignedByAdmin ?? this.assignedByAdmin,
      serviceCompletedTime: serviceCompletedTime ?? this.serviceCompletedTime,
      serviceCompletedMarkedById:
          serviceCompletedMarkedById ?? this.serviceCompletedMarkedById,
      serviceCompletedMarkedByName:
          serviceCompletedMarkedByName ?? this.serviceCompletedMarkedByName,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      bookedBy: bookedBy ?? this.bookedBy,
      maid: maid ?? this.maid,
      totalTimeTaken: totalTimeTaken ?? this.totalTimeTaken,
      customerInfo: customerInfo ?? this.customerInfo,
      assignedTime: assignedTime ?? this.assignedTime,
      assignedBy: assignedBy ?? this.assignedBy,
      bookedOn: bookedOn ??
          this.bookedOn, // Added field for when the booking was made
      commissionPercentage: commissionPercentage ??
          this.commissionPercentage, // Added field for commission percentage
      paymentInfo:
          paymentInfo ?? this.paymentInfo, // Added field for payment info
      bookingSlots: bookingSlots ?? this.bookingSlots, // Added field for available time slots
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate, // Added field for start and end date
      taxPercentage: taxPercentage ?? this.taxPercentage, // Added field for tax percentage
      parentBookingId: parentBookingId ?? this.parentBookingId, // Added field for parent booking ID
    );
  }

  factory BookingModel.getDefaultBookingModel() {
    return BookingModel(
      bookingId: '',
      appAccountId: '',
      customerId: '',
      maidId: '',
      services: [],
      status: '',
      totalPrice: 0.0,
      customerAddress: AddressModel.getDefaultAddress(),
      bookingDate: DateTime.now(),
      timeSlot: TimeSlotModel.defaultTimeSlot(),
      note: '',
      assignedByAdmin: false,
      serviceCompletedTime: '',
      serviceCompletedMarkedById: '',
      serviceCompletedMarkedByName: '',
      serviceStatus: '1',
      cancellationReason: '',
      bookedBy: '',
      maid: null,
      totalTimeTaken: '',
      customerInfo: CustomerModel.getDefaultCustomer(),
      assignedTime: '',
      assignedBy: '',
      bookedOn: '',
      commissionPercentage: 0.0,
      paymentInfo: PaymentInfoModel.defaultPayment(),
      bookingSlots: [],
      startDate: '',
      endDate: '',
      taxPercentage: 0.0, // Default tax percentage
      parentBookingId: '', // Default parent booking ID
    );
  }
}
