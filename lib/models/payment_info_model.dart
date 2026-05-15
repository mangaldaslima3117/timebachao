import 'package:bookmyservice/core/utils/app_constants.dart';

class PaymentInfoModel {
  final String paymentId;
  final String orderId;
  final String signature;
  final String bookingId;
  String message;
  double amount;
  String currency;
  String status;
  String method; // 🔥 This field
  DateTime createdAt;

  PaymentInfoModel({
    required this.paymentId,
    required this.orderId,
    required this.signature,
    required this.bookingId,
    required this.message,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
    required this.createdAt,
  });

  factory PaymentInfoModel.fromMap(Map<String, dynamic> map) {
    return PaymentInfoModel(
      paymentId: map.containsKey('paymentId') ? map['paymentId'] ?? '' : '',
      orderId: map.containsKey('orderId') ? map['orderId'] ?? '' : '',
      signature: map.containsKey('signature') ? map['signature'] ?? '' : '',
      bookingId: map.containsKey('bookingId') ? map['bookingId'] ?? '' : '',
      message: map.containsKey('message') ? map['message'] ?? '' : '',
      amount: map.containsKey('amount') ? (map['amount'] ?? 0).toDouble() : 0.0,
      currency: map.containsKey('currency') ? map['currency'] ?? 'INR' : 'INR',
      status:
          map.containsKey('status') ? map['status'] ?? 'pending' : 'pending',
      method: map.containsKey('method') ? map['method'] ?? '' : '',
      createdAt: map.containsKey('createdAt') && map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'bookingId': bookingId,
      'message': message,
      'amount': amount,
      'currency': currency,
      'status': status,
      'method': method,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static PaymentInfoModel defaultPayment() {
    return PaymentInfoModel(
      paymentId: '',
      orderId: '',
      signature: '',
      bookingId: '',
      message: '',
      amount: 0.0,
      currency: 'INR',
      status: AppConstants.pending, // Assuming '7' is for pending payment
      method: '',
      createdAt: DateTime.now(),
    );
  }
}
