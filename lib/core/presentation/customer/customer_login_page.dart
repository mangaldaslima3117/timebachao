import 'package:bookmyservice/services/customer_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../services/authentication_provider.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const teal = Color(0xFF0FA97A);
  static const tealDark = Color(0xFF097A59);
  static const tealDeep = Color(0xFF054D38);
  static const tealLight = Color(0xFFD4F5EB);
  static const tealMid = Color(0xFF1DC995);
  static const bg = Color(0xFFF5FAF8);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0D1F1A);
  static const textSecondary = Color(0xFF5C7A6E);
  static const border = Color(0xFFD0EBE2);
  static const shadow = Color(0x14097A59);
}
// ─────────────────────────────────────────────────────────────────────────────

class CustomerLoginPage extends ConsumerStatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CustomerLoginPageState();
}

class _CustomerLoginPageState extends ConsumerState<CustomerLoginPage>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  String _verificationId = "";
  bool _otpSent = false;
  String _otpCode = "";
  String code = "";
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _heroController;
  late AnimationController _cardController;
  late Animation<double> _heroFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    listenForOTPCode();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOut,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));
    _cardFade = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _heroController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
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
    setState(() => _isLoading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text}',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        _showSnack("Logged in automatically!");
        setState(() => _isLoading = false);
      },
      verificationFailed: (FirebaseAuthException e) {
        _showSnack("Verification failed: ${e.message}", error: true);
        setState(() => _isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
        _showSnack("OTP sent to +91 ${_phoneController.text}");
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _verifyOTP(String code) async {
    if (code.length < 6) return;
    setState(() => _isLoading = true);
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
        _showSnack("Sign-in failed. Please try again.", error: true);
      }
    } catch (e) {
      _showSnack("Invalid OTP. Please try again.", error: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: error ? const Color(0xFFC0392B) : _C.tealDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  cancel() {}

  @override
  void dispose() {
    cancel();
    _phoneController.dispose();
    _heroController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: _C.bg,
          body: Stack(
            children: [
              // ── Decorative background ────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size.height * 0.48,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A8A63),
                        Color(0xFF0FA97A),
                        Color(0xFF1DC995),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Decorative circles ───────────────────────────────────────
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              // ── Wave clipper ─────────────────────────────────────────────
              Positioned(
                top: size.height * 0.42,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(size.width, 60),
                  painter: _WavePainter(),
                ),
              ),

              // ── Main content ─────────────────────────────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      // ── Hero section ─────────────────────────────────────
                      FadeTransition(
                        opacity: _heroFade,
                        child: SizedBox(
                          height: size.height * 0.38,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Image.asset(
                                  'assets/images/timebachaologo_new.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Book trusted home services in minutes',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.80),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Form card ─────────────────────────────────────────
                      SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.shadow,
                                  blurRadius: 40,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                              child: Form(
                                key: _formKey,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.06, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                                  child: _otpSent
                                      ? _OtpStep(
                                          key: const ValueKey('otp'),
                                          phone: _phoneController.text,
                                          isLoading: _isLoading,
                                          onCodeChanged: (c) =>
                                              _otpCode = c ?? "",
                                          onCodeSubmitted: _verifyOTP,
                                          onVerify: () =>
                                              _verifyOTP(_otpCode),
                                          onBack: () => setState(
                                              () => _otpSent = false),
                                        )
                                      : _PhoneStep(
                                          key: const ValueKey('phone'),
                                          controller: _phoneController,
                                          isLoading: _isLoading,
                                          onSend: () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              _sendOTP();
                                            }
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Phone Step Widget ─────────────────────────────────────────────────────────
class _PhoneStep extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _PhoneStep({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.tealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _C.tealDark,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        const Text(
          'Enter your\nphone number',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "We'll send a 6-digit OTP to verify your number",
          style: TextStyle(
            fontSize: 13,
            color: _C.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // Phone input
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '00000 00000',
            hintStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: _C.textSecondary.withOpacity(0.5),
              letterSpacing: 2,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 0, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _C.tealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '+91',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.tealDark,
                ),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            filled: true,
            fillColor: const Color(0xFFF7FDFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _C.teal, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFC0392B), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFC0392B), width: 2),
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
        const SizedBox(height: 28),

        // Send OTP button
        _GradientButton(
          label: 'Send OTP',
          icon: Icons.send_rounded,
          isLoading: isLoading,
          onTap: onSend,
        ),

        const SizedBox(height: 20),
        Center(
          child: Text(
            'Your number is safe with us 🔒',
            style: TextStyle(
              fontSize: 12,
              color: _C.textSecondary.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}

// ── OTP Step Widget ───────────────────────────────────────────────────────────
class _OtpStep extends StatelessWidget {
  final String phone;
  final bool isLoading;
  final void Function(String?) onCodeChanged;
  final void Function(String) onCodeSubmitted;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  const _OtpStep({
    super.key,
    required this.phone,
    required this.isLoading,
    required this.onCodeChanged,
    required this.onCodeSubmitted,
    required this.onVerify,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back + step indicator row
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 14, color: _C.textSecondary),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _C.tealLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Step 2 of 2',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.tealDark,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Verify your\nnumber',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13,
              color: _C.textSecondary,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'OTP sent to '),
              TextSpan(
                text: '+91 $phone',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _C.teal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // OTP icon indicator
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.tealMid, _C.tealDark],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _C.teal.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.sms_rounded, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 24),

        // PinField
        PinFieldAutoFill(
          codeLength: 6,
          decoration: BoxLooseDecoration(
            strokeColorBuilder: PinListenColorBuilder(
              _C.teal,
              _C.border,
            ),
            bgColorBuilder: const FixedColorBuilder(Color(0xFFF7FDFB)),
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
            strokeWidth: 1.8,
            radius: const Radius.circular(14),
            gapSpace: 8,
          ),
          onCodeChanged: onCodeChanged,
          onCodeSubmitted: onCodeSubmitted,
        ),
        const SizedBox(height: 28),

        // Verify button
        _GradientButton(
          label: 'Verify & Login',
          icon: Icons.verified_rounded,
          isLoading: isLoading,
          onTap: onVerify,
        ),
        const SizedBox(height: 16),

        // Resend hint
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: _C.textSecondary),
              children: const [
                TextSpan(text: "Didn't receive it? "),
                TextSpan(
                  text: 'OTP auto-fills via SMS',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _C.teal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(
                  colors: [Color(0xFF7AC9B2), Color(0xFF7AC9B2)],
                )
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_C.tealDark, _C.teal, _C.tealMid],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _C.teal.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Wave Painter ──────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5FAF8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 30);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 20);
    path.quadraticBezierTo(size.width * 0.75, 40, size.width, 10);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}