import 'dart:async';

import 'package:bookmyservice/core/presentation/customer/customer_welcome_page.dart';
import 'package:bookmyservice/core/presentation/customer/map_address_selection.dart';
import 'package:bookmyservice/services/authentication_provider.dart';
import 'package:bookmyservice/services/customer_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/customer_model.dart';
import '../../../models/address_model.dart';

// ── Design Tokens (shared with CustomerLoginPage) ─────────────────────────────
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
  static const errorRed = Color(0xFFC0392B);
}
// ─────────────────────────────────────────────────────────────────────────────

class CustomerDetailsPage extends ConsumerStatefulWidget {
  final CustomerModel customer;
  const CustomerDetailsPage({super.key, required this.customer});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends ConsumerState<CustomerDetailsPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final countryController = TextEditingController();
  final landController = TextEditingController();
  final areaController = TextEditingController();
  final houseController = TextEditingController();

  String gender = 'Male';
  String _addressLabel = 'Home'; // 'Home' | 'Office' | 'Other'
  bool _isLoading = false;

  late AnimationController _heroController;
  late AnimationController _cardController;
  late Animation<double> _heroFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    phoneController.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    nameController.text = widget.customer.name;
    emailController.text = widget.customer.email;
    gender =
        widget.customer.gender.isNotEmpty ? widget.customer.gender : 'Male';
    houseController.text = widget.customer.address.houseNumber;
    areaController.text = widget.customer.address.areaName;
    landController.text = widget.customer.address.landmark;
    cityController.text = widget.customer.address.city;
    pincodeController.text = widget.customer.address.pinCode;
    stateController.text = widget.customer.address.state;
    countryController.text = widget.customer.address.country;
    // Restore saved address label if available (extend AddressModel if needed)
    // _addressLabel = widget.customer.address.label ?? 'Home';

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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    countryController.dispose();
    landController.dispose();
    areaController.dispose();
    houseController.dispose();
    _heroController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomerData() async {
    final customerP = ref.read(customerProvider.notifier);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final customer = CustomerModel(
      id: widget.customer.id.isNotEmpty
          ? widget.customer.id
          : phoneController.text.trim(),
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim().substring(3),
      userId: uid,
      gender: gender,
      address: AddressModel(
        houseNumber: houseController.text.trim(),
        areaName: areaController.text.trim(),
        landmark: landController.text.trim(),
        city: cityController.text.trim(),
        pinCode: pincodeController.text.trim(),
        state: stateController.text.trim(),
        country: countryController.text.trim(),
        // label: _addressLabel, // Uncomment if AddressModel has this field
      ),
      appAccountId: '',
      profileImageUrl: '',
      fcmToken: widget.customer.fcmToken!.isNotEmpty
          ? widget.customer.fcmToken
          : '',
    );

    if (widget.customer.id.isNotEmpty) {
      await customerP.updateCustomer(customer);
    } else {
      await customerP.addCustomer(customer);
    }
    customerP.addCustomer(customer);

    if (mounted) {
      setState(() => _isLoading = false);
      _showSnack('Details saved successfully!');
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const CustomerWelcomePage(),
      ));
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
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
        backgroundColor: error ? _C.errorRed : _C.tealDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _pickAddressFromMap() {
    final authService = ref.read(authServiceProvider);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapAddressSelectorScreen()),
    ).then((dynamic selectedAddress) {
      debugPrint('Selected address In Detail: ${selectedAddress.toString()}');
      if (selectedAddress != null &&
          selectedAddress.houseNumber.isNotEmpty) {
        setState(() {
          houseController.text = selectedAddress.houseNumber;
          areaController.text = selectedAddress.areaName;
          landController.text = selectedAddress.landmark;
          cityController.text = selectedAddress.city;
          pincodeController.text = selectedAddress.pinCode;
          stateController.text = selectedAddress.state;
          countryController.text = selectedAddress.country;
        });
      }
    } as FutureOr Function(dynamic value));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authService = ref.watch(authServiceProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Stack(
          children: [
            // ── Decorative gradient background ───────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.34,
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
              top: 80,
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
              top: size.height * 0.28,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(size.width, 60),
                painter: _WavePainter(),
              ),
            ),

            // ── Main scrollable content ──────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // ── App bar row ────────────────────────────────────────
                  FadeTransition(
                    opacity: _heroFade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              await authService.signOut();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout_rounded,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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

                  // ── Hero text ──────────────────────────────────────────
                  FadeTransition(
                    opacity: _heroFade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Profile',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in your details to get started',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.80),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Scrollable form card ───────────────────────────────
                  Expanded(
                    child: SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.shadow,
                                  blurRadius: 40,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 28, 24, 28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // ── Section: Personal Info ───────────
                                    _SectionHeader(
                                      icon: Icons.person_outline_rounded,
                                      label: 'Personal Information',
                                    ),
                                    const SizedBox(height: 16),
                                    _StyledField(
                                      controller: phoneController,
                                      label: 'Phone Number',
                                      icon: Icons.phone_outlined,
                                      enabled: false,
                                    ),
                                    const SizedBox(height: 14),
                                    _StyledField(
                                      controller: nameController,
                                      label: 'Full Name',
                                      icon: Icons.badge_outlined,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Name is required'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StyledField(
                                      controller: emailController,
                                      label: 'Email Address',
                                      icon: Icons.mail_outline_rounded,
                                      inputType:
                                          TextInputType.emailAddress,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Email is required'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),

                                    // Gender Dropdown
                                    _GenderDropdown(
                                      value: gender,
                                      onChanged: (v) =>
                                          setState(() => gender = v!),
                                    ),
                                    const SizedBox(height: 28),

                                    // ── Section: Address ─────────────────
                                    Row(
                                      children: [
                                        _SectionHeader(
                                          icon: Icons.location_on_outlined,
                                          label: 'Address',
                                        ),
                                        const Spacer(),
                                        // Map pick button
                                        GestureDetector(
                                          onTap: _pickAddressFromMap,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _C.tealLight,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Icon(Icons.pin_drop_rounded,
                                                    size: 14,
                                                    color: _C.tealDark),
                                                SizedBox(width: 5),
                                                Text(
                                                  'Pick on Map',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: _C.tealDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Address label selector ───────────
                                    _AddressLabelSelector(
                                      selected: _addressLabel,
                                      onSelected: (label) =>
                                          setState(() =>
                                              _addressLabel = label),
                                    ),
                                    const SizedBox(height: 16),

                                    _StyledField(
                                      controller: houseController,
                                      label: 'House / Building No.',
                                      icon: Icons.home_outlined,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StyledField(
                                      controller: areaController,
                                      label: 'Area / Locality',
                                      icon: Icons.map_outlined,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StyledField(
                                      controller: landController,
                                      label: 'Landmark',
                                      icon: Icons.place_outlined,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StyledField(
                                      controller: cityController,
                                      label: 'City',
                                      icon: Icons.location_city_outlined,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StyledField(
                                      controller: pincodeController,
                                      label: 'Pin Code',
                                      icon: Icons.pin_outlined,
                                      inputType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter
                                            .digitsOnly,
                                      ],
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StyledField(
                                      controller: stateController,
                                      label: 'State',
                                      icon: Icons.flag_outlined,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _StyledField(
                                      controller: countryController,
                                      label: 'Country',
                                      icon: Icons.public_outlined,
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    const SizedBox(height: 32),

                                    // ── Save button ──────────────────────
                                    _GradientButton(
                                      label: 'Save Details',
                                      icon: Icons.check_circle_outline_rounded,
                                      isLoading: _isLoading,
                                      onTap: _saveCustomerData,
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Text(
                                        'Your information is secure 🔒',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _C.textSecondary
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
          ],
        ),
      ),
    );
  }
}

// ── Address Label Selector ────────────────────────────────────────────────────
class _AddressLabelSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelected;

  const _AddressLabelSelector({
    required this.selected,
    required this.onSelected,
  });

  static const _options = [
    ('Home', Icons.home_rounded),
    ('Office', Icons.business_center_rounded),
    ('Other', Icons.location_on_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final label = opt.$1;
        final icon = opt.$2;
        final isSelected = selected == label;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: label == 'Other' ? 0 : 8,
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? _C.tealLight : const Color(0xFFF7FDFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? _C.teal : _C.border,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? _C.tealDark : _C.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color:
                          isSelected ? _C.tealDark : _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.tealMid, _C.tealDark],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _C.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ── Styled Text Field ─────────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType inputType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.inputType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _C.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: _C.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon,
              size: 18,
              color: enabled ? _C.teal : _C.textSecondary.withOpacity(0.5)),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: enabled
            ? const Color(0xFFF7FDFB)
            : const Color(0xFFF0F4F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.border, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFDDE8E4), width: 1.5),
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
      validator: validator,
    );
  }
}

// ── Gender Dropdown ───────────────────────────────────────────────────────────
class _GenderDropdown extends StatelessWidget {
  final String value;
  final void Function(String?) onChanged;

  const _GenderDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _C.teal, size: 20),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _C.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: const TextStyle(
          fontSize: 13,
          color: _C.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.wc_outlined, size: 18, color: _C.teal),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ),
      onChanged: onChanged,
      items: ['Male', 'Female', 'Other']
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
    );
  }
}

// ── Gradient Button (reused from login page) ──────────────────────────────────
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
                    valueColor:
                        AlwaysStoppedAnimation(Colors.white),
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

// ── Wave Painter (identical to login page) ────────────────────────────────────
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