import 'package:bookmyservice/services/customer_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../services/authentication_provider.dart';

class CustomerLoginPage extends ConsumerStatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CustomerLoginPageState();
}

class _CustomerLoginPageState extends ConsumerState<CustomerLoginPage> {
  final _phoneController = TextEditingController();
  String _verificationId = "";
  bool _otpSent = false;
  String _otpCode = "";
  String code = "";
  final _formKey = GlobalKey<FormState>(); // Add this at the top
  //final String debugToken = "B2734D79-94C6-471C-A644-58E495DBC3A6";

  @override
  void initState() {
    super.initState();
    listenForOTPCode();
  }

  listenForOTPCode() async {
    await SmsAutoFill().listenForCode();
  }

  @override
  void codeUpdated() {
    setState(() {
      _otpCode = code;
    });
    if (_otpCode.length == 6) {
      _verifyOTP(_otpCode);
    }
  }

  void _sendOTP() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text}',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        _showSnack("Logged in automatically!");
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnack("Verification failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
        });
        _showSnack("OTP Sent!");
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _verifyOTP(String code) async {
    final authService = ref.watch(authServiceProvider);
    try {
      debugPrint('DEBUG SMS CODE : $code');
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        await authService.createCustomerAccount(
          userCredential,
          _phoneController.text.trim(),
        );
        _showSnack("OTP Verified! Login Successful");
      } else {
        print("❌ Sign-in failed, user is null");
      }
    } catch (e) {
      _showSnack("Invalid OTP");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  cancel() {}

  @override
  void dispose() {
    cancel();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                  // App Logo
                  Image.asset(
                    'assets/images/Time Bachao.png', // Place your generated logo here
                    height: 180,
                  ),
                  const SizedBox(height: 1),
                  // App Name
                  Text(
                    'Time Bachao',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                  // Google Sign-In Button
                  // ElevatedButton.icon(
                  //   icon: const Icon(Icons.login),
                  //   label: const Text("Sign in with Google"),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.teal,
                  //     foregroundColor: Colors.white,
                  //     minimumSize: const Size.fromHeight(50),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //   ),
                  //   onPressed: () async {
                  //     final result = await authService.signInWithGoogle();
                  //     if (result == null) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(
                  //             content: Text("Login failed or cancelled")),
                  //       );
                  //     }
                  //   },
                  // ),
                  // GestureDetector(
                  //   onTap: () async {
                  //     final result =
                  //         await authService.signInWithGoogle_Customer();
                  //     if (result == null) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(
                  //             content: Text("Login failed or cancelled")),
                  //       );
                  //     }
                  //   },
                  //   child: Container(
                  //     height: 50,
                  //     decoration: BoxDecoration(
                  //       color: Colors.white,
                  //       border: Border.all(color: Colors.grey),
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Image.asset(
                  //           'assets/images/google_g.png',
                  //           height: 24,
                  //         ),
                  //         const SizedBox(width: 12),
                  //         const Text(
                  //           "Sign in with Google",
                  //           style: TextStyle(
                  //             fontSize: 16,
                  //             color: Colors.black87,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  if (!_otpSent) ...[
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        prefixText: '+91 ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return 'Enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.teal, // 🔵 Button background color
                        foregroundColor: Colors.white, // ⚪ Text/icon color
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _sendOTP(); // Only send OTP if valid
                        }
                      },
                      child: const Text(
                        'Login with Mobile',
                      ),
                    ),
                    const SizedBox(height: 10),
                    // const Text(
                    //   'OR',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.w500,
                    //     color: Colors.grey,
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // GestureDetector(
                    //   onTap: () async {
                    //     final result =
                    //         await authService.signInWithGoogleCustomer();
                    //     if (result == null) {
                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         const SnackBar(
                    //             content: Text("Login failed or cancelled")),
                    //       );
                    //     }
                    //   },
                    //   child: Container(
                    //     height: 50,
                    //     decoration: BoxDecoration(
                    //       color: Colors.white,
                    //       border: Border.all(color: Colors.grey),
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         Image.asset(
                    //           'assets/images/google_g.png',
                    //           height: 24,
                    //         ),
                    //         const SizedBox(width: 12),
                    //         const Text(
                    //           "Login with Google",
                    //           style: TextStyle(
                    //             fontSize: 16,
                    //             color: Colors.black87,
                    //             fontWeight: FontWeight.w600,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ] else ...[
                    PinFieldAutoFill(
                      codeLength: 6,
                      decoration: UnderlineDecoration(
                        textStyle:
                            const TextStyle(fontSize: 20, color: Colors.black),
                        colorBuilder: const FixedColorBuilder(Colors.teal),
                        gapSpace: 8,
                      ),
                      onCodeChanged: (code) {
                        _otpCode = code ?? "";
                      },
                      onCodeSubmitted: (code) {
                        _verifyOTP(code);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _verifyOTP(_otpCode),
                      child: const Text('Verify OTP'),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
