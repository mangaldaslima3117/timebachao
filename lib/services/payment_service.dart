import 'package:bookmyservice/core/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/booking_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_info_model.dart';
import 'app_account_provider.dart';
import 'bookings_provider.dart';

class PaymentService {
  late Razorpay _razorpay;
  final WidgetRef ref;
  final BookingModel booking;
  final BuildContext context;

  PaymentService({
    required this.ref,
    required this.booking,
    required this.context,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  //Proceed to pay
  void razorPayAndPlaceOrder(BookingModel booking) async {
    final appAccount = ref.read(appAccountProvider);
    bool isLive = appAccount?.appConfig.isLiveMode ?? false;
    String paymentKey = isLive
        ? appAccount!.appConfig.razorpayKey
        : appAccount!.appConfig.razorpayDemoKey;

    var options = {
      'key': paymentKey,
      'amount':
          booking.totalPrice * 100, //Multiply with 100 to make this as number
      'name': 'Jhadu Pocha',
      'description': 'Booking Amount : ${booking.totalPrice}',
      'prefill': {
        'contact': booking.customerInfo.phone,
        'email': 'test@razorpay.com'
      }
    };

    try {
      _razorpay.open(options);
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $err"),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentInfo = PaymentInfoModel(
      paymentId: response.paymentId ?? '',
      orderId: response.orderId ?? '',
      signature: response.signature ?? '',
      bookingId: booking.bookingId,
      message: 'Payment successful',
      amount: booking.totalPrice,
      currency: 'INR',
      status: '6',
      method: AppConstants.PAYMENT_ONLINE,
      createdAt: DateTime.now(),
    );

    booking.paymentInfo = paymentInfo;
    ref
        .read(bookingsProvider.notifier)
        .updatePaymentInfo(booking, paymentInfo.status);
    ScaffoldMessenger.of(context)
        .showSnackBar(_showMessage('Payment successful', true));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      _showMessage(_getPaymentMessage(response.code ?? 0), false),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      _showMessage("EXTERNAL_WALLET: ${response.walletName}", false),
    );
  }

  SnackBar _showMessage(String message, bool isSuccess) {
    return SnackBar(
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      content: Text(message),
      action: SnackBarAction(label: 'OK', onPressed: () {}),
    );
  }

  String _getPaymentMessage(int code) {
    switch (code) {
      case 1:
        return "Network error occurred";
      case 2:
        return "Payment cancelled by user";
      default:
        return "Payment failed. Try again";
    }
  }

  void handleCashPayment(BookingModel booking) {
    final paymentInfo = PaymentInfoModel(
      paymentId: '',
      orderId: '',
      signature: '',
      bookingId: booking.bookingId,
      message: 'Payment successful',
      amount: booking.totalPrice,
      currency: 'INR',
      status: AppConstants.paid,
      method: AppConstants.PAYMENT_CASH,
      createdAt: DateTime.now(),
    );

    booking.paymentInfo = paymentInfo;
    ref
        .read(bookingsProvider.notifier)
        .updatePaymentInfo(booking, paymentInfo.status);
    ScaffoldMessenger.of(context)
        .showSnackBar(_showMessage('Payment successful', true));
  }

  void initiatePayment(WidgetRef ref, BookingModel booking, bool isOnline) {
    PaymentService paymentService = PaymentService(
      ref: ref,
      booking: booking,
      context: context,
    );

    isOnline
        ? paymentService.razorPayAndPlaceOrder(booking)
        : paymentService.handleCashPayment(booking);
  }
}
