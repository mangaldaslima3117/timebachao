class AppConfigModel {
  final String razorpayDemoKey;
  final String razorpayKey;       // Razorpay public key
  final bool isLiveMode;          // true = live, false = test/demo
  final bool isPaymentEnabled;    // feature toggle
  final bool isBookingActive;     // can be used to disable bookings temporarily
  final String? supportContact;   // phone or email for support
  final String? version;      // app version from backend
  final String? message;   

  AppConfigModel({
    required this.razorpayDemoKey,
    required this.razorpayKey,
    required this.isLiveMode,
    required this.isPaymentEnabled,
    required this.isBookingActive,
    this.supportContact,
    this.version,
    this.message,
  });

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      razorpayDemoKey: map['razorpayDemoKey'] ?? '',
      razorpayKey: map['razorpayKey'] ?? '',
      isLiveMode: map['isLiveMode'] ?? false,
      isPaymentEnabled: map['isPaymentEnabled'] ?? true,
      isBookingActive: map['isBookingActive'] ?? true,
      supportContact: map['supportContact'],
      version: map['version'],
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'razorpayDemoKey': razorpayDemoKey,
      'razorpayKey': razorpayKey,
      'isLiveMode': isLiveMode,
      'isPaymentEnabled': isPaymentEnabled,
      'isBookingActive': isBookingActive,
      'supportContact': supportContact,
      'version': version,
      'message': message,
    };
  }

  factory AppConfigModel.defaultConfig() {
    return AppConfigModel(
      razorpayDemoKey: '',
      razorpayKey: '',
      isLiveMode: false,
      isPaymentEnabled: true,
      isBookingActive: true,
      supportContact: null,
      version: null,
      message: null,
    );
  }
}
