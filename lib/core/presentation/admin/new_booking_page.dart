import 'dart:math';

import 'package:bookmyservice/models/payment_info_model.dart';
import 'package:bookmyservice/services/app_account_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

import '../../../models/address_model.dart';
import '../../../models/booking_model.dart';
import '../../../models/customer_model.dart';
import '../../../models/maid_model.dart';
import '../../../models/service_model.dart';
import '../../../models/slot_model.dart';
import '../../../services/bookings_provider.dart';
import '../../../services/customer_provider.dart';
import '../../../services/service_provider.dart';
import '../../../services/slots_provider.dart';
import '../../../services/user_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/common_function.dart';
import '../../widgets/datewise_slot_selector.dart';

class NewBookingPage extends ConsumerStatefulWidget {
  final BookingModel? initialBooking;
  const NewBookingPage({super.key, this.initialBooking});

  @override
  ConsumerState<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends ConsumerState<NewBookingPage> {
  int _currentStep = 0;

  // ── Controllers ────────────────────────────────────────────────────────────
  TextEditingController customerIdController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();
  TextEditingController customerGenderController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  TextEditingController houseController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  TextEditingController landmarkController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController countryController = TextEditingController();

  List<ServiceModel> selectedServices = <ServiceModel>[];
  DateTime? selectedDate = DateTime.now();
  TimeSlotModel? selectedTimeSlot;
  AddressModel? address;
  CustomerModel? customerInfo;

  final customerInfoFormKey = GlobalKey<FormState>();
  final addressFormKey = GlobalKey<FormState>();
  DateFormat dateFormat = DateFormat('dd-MM-yyyy hh:MM:ss');
  DateFormat bookingFormat = DateFormat('yyyy-MM-dd');
  List<TimeSlotModel>? selectedTimeSlots = [];
  DateTime? startDate = DateTime.now();
  DateTime? endDate = DateTime.now();
  bool applyToAll = true;
  TimeSlotModel? defaultSlot;
  Map<String, TimeSlotModel> individualSlots = {};
  DateTimeRange<DateTime>? pickedDateRange;
  List<String> sortedDates = [];
  final dateFormatStep = DateFormat('dd-MM-yyyy');

  // ── OTP ────────────────────────────────────────────────────────────────────
  late String _generatedOtp;

  String _generateOtp() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _nextStep() {
    bool isValid = false;
    if (_currentStep == 0) {
      isValid = customerInfoFormKey.currentState?.validate() ?? false;
    } else {
      isValid = true;
    }
    if (isValid) {
      // Generate OTP fresh when reaching the confirmation step
      if (_currentStep == 3) {
        setState(() => _generatedOtp = _generateOtp());
      }
      setState(() => _currentStep += 1);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _submitBooking() async {
    final appAccount = ref.read(appAccountProvider);
    final userDtl = ref.read(userProvider);

    if (customerNameController.text.isEmpty ||
        customerPhoneController.text.isEmpty) {
      _showSnack("Please fill customer information");
      return;
    }
    if (selectedDate == null ||
        selectedTimeSlot == null ||
        selectedTimeSlot!.startTime.isEmpty ||
        selectedTimeSlot!.endTime.isEmpty ||
        selectedServices.isEmpty) {
      _showSnack("Please select date and time slot");
      return;
    }
    if (houseController.text.isEmpty ||
        areaController.text.isEmpty ||
        cityController.text.isEmpty) {
      _showSnack("Please enter address");
      return;
    }

    final isBookingExist = widget.initialBooking != null &&
        widget.initialBooking!.bookingId.isNotEmpty;

    final bookingId = isBookingExist
        ? widget.initialBooking!.bookingId
        : DateTime.now().millisecondsSinceEpoch.toString();

    address = AddressModel(
      houseNumber: houseController.text.trim(),
      areaName: areaController.text.trim(),
      landmark: landmarkController.text.trim(),
      city: cityController.text.trim(),
      pinCode: pinCodeController.text.trim(),
      state: stateController.text.trim(),
      country: countryController.text.trim(),
    );

    customerInfo = CustomerModel(
      id: '',
      name: customerNameController.text,
      email: '',
      phone: customerPhoneController.text,
      userId: '',
      gender: customerGenderController.text,
      address: address!,
      appAccountId: appAccount != null ? appAccount.appAccountId : "",
      profileImageUrl: '',
      fcmToken: '',
    );

    final double totalServicePrice = selectedServices.fold<double>(
      0.0,
      (sum, service) => sum + service.finalPrice,
    );
    final int dayCount =
        individualSlots.isNotEmpty ? individualSlots.length : 1;
    final double totalPrice = totalServicePrice * dayCount;

    // Use existing OTP if editing, generate new one if creating
    final String otp =
        isBookingExist ? widget.initialBooking!.otp : _generatedOtp;

    final BookingModel booking = BookingModel(
      bookingId: bookingId,
      appAccountId: appAccount != null ? appAccount.appAccountId : "",
      customerId: customerIdController.text.trim(),
      maidId: isBookingExist ? widget.initialBooking!.maid!.id : '',
      services: selectedServices,
      status: isBookingExist ? widget.initialBooking!.serviceStatus : "1",
      totalPrice: totalPrice,
      customerAddress: address!,
      bookingDate:
          isBookingExist ? widget.initialBooking!.bookingDate : DateTime.now(),
      timeSlot: selectedTimeSlot!,
      note: noteController.text.trim(),
      assignedByAdmin: true,
      serviceCompletedTime: "",
      serviceCompletedMarkedById: "",
      serviceCompletedMarkedByName: "",
      serviceStatus:
          isBookingExist ? widget.initialBooking!.serviceStatus : "1",
      cancellationReason: "",
      bookedBy: userDtl != null ? userDtl.role.roleType : '',
      maid: isBookingExist
          ? widget.initialBooking!.maid
          : MaidModel.getDefaultMaid(),
      totalTimeTaken:
          isBookingExist ? widget.initialBooking!.totalTimeTaken : '',
      customerInfo: customerInfo!,
      assignedTime: '',
      assignedBy: '',
      bookedOn: bookingFormat.format(DateTime.now()),
      commissionPercentage: 0,
      paymentInfo: PaymentInfoModel.defaultPayment(),
      bookingSlots: individualSlots.values.toList(),
      startDate:
          selectedDate != null ? bookingFormat.format(selectedDate!) : "",
      endDate: selectedDate != null
          ? bookingFormat.format(selectedDate!.add(const Duration(days: 1)))
          : "",
      taxPercentage: appAccount != null ? appAccount.taxPercentage : 0.0,
      parentBookingId: individualSlots.length > 1
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : '',
      otp: _generatedOtp, // ✅ stored in booking
    );

    if (isBookingExist) {
      await ref.read(bookingsProvider.notifier).updateBooking(booking);
    } else {
      await ref.read(bookingsProvider.notifier).createBookingsBatch(booking);
    }

    await ref.read(customerProvider.notifier).addCustomer(booking.customerInfo);

    if (mounted) {
      _showSnack(isBookingExist ? "Booking Updated!" : "Booking Created!");
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Input decoration ───────────────────────────────────────────────────────
  final inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.teal),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.teal),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.teal, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.teal),
  );

  void _openDateWiseSlotSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DateWiseSlotSelector(
          startDate: startDate!,
          endDate: endDate!,
          selectedSlots: individualSlots,
          onSlotSelected: (date, slot) {
            setState(() => individualSlots[date] = slot);
          },
        ),
      ),
    ).then((_) {
      setState(() {
        selectedTimeSlots = individualSlots.values.toList();
        sortedDates = individualSlots.keys.toList()
          ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _generatedOtp = _generateOtp(); // initial OTP
    pickedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
    if (widget.initialBooking != null) {
      houseController = TextEditingController(
          text: widget.initialBooking!.customerAddress.houseNumber);
      areaController = TextEditingController(
          text: widget.initialBooking!.customerAddress.areaName);
      landmarkController = TextEditingController(
          text: widget.initialBooking!.customerAddress.landmark);
      cityController = TextEditingController(
          text: widget.initialBooking!.customerAddress.city);
      pinCodeController = TextEditingController(
          text: widget.initialBooking!.customerAddress.pinCode);
      stateController = TextEditingController(
          text: widget.initialBooking!.customerAddress.state);
      countryController = TextEditingController(
          text: widget.initialBooking!.customerAddress.country);
      address = AddressModel(
        houseNumber: houseController.text.trim(),
        areaName: areaController.text.trim(),
        landmark: landmarkController.text.trim(),
        city: cityController.text.trim(),
        pinCode: pinCodeController.text.trim(),
        state: stateController.text.trim(),
        country: countryController.text.trim(),
      );
      customerNameController.text = widget.initialBooking!.customerInfo.name;
      customerPhoneController.text = widget.initialBooking!.customerInfo.phone;
      selectedServices = widget.initialBooking!.services;
      selectedDate = widget.initialBooking!.bookingDate;
      selectedTimeSlot = widget.initialBooking!.timeSlot;
      selectedTimeSlots = widget.initialBooking!.bookingSlots;
      // Use existing OTP when editing
      _generatedOtp = widget.initialBooking!.otp.isNotEmpty
          ? widget.initialBooking!.otp
          : _generateOtp();
    } else {
      address = AddressModel(
        houseNumber: "",
        areaName: "",
        landmark: "",
        city: "",
        pinCode: "",
        state: "",
        country: "India",
      );
      countryController.text = "India";
      customerInfo = CustomerModel.getDefaultCustomer();
      customerInfo!.address = address!;
      selectedTimeSlot = TimeSlotModel.defaultTimeSlot();
      selectedTimeSlots = [selectedTimeSlot!];
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: inputDecoration.copyWith(
          labelText: label,
          hintText: "Enter $label",
        ),
        onChanged: (value) {
          setState(() {
            if (label == "House / Building No.") {
              address!.houseNumber = value;
            } else if (label == "Area Name") {
              address!.areaName = value;
            } else if (label == "Landmark") {
              address!.landmark = value;
            } else if (label == "City") {
              address!.city = value;
            } else if (label == "Pin Code") {
              address!.pinCode = value;
            } else if (label == "State") {
              address!.state = value;
            } else if (label == "Country") {
              address!.country = value;
            }
          });
        },
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      saveText: 'Done',
      context: context,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.teal,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        selectedTimeSlot = null;
      });
    }
  }

  // ─── Service Card ──────────────────────────────────────────────────────────
  Widget _buildServiceCard(ServiceModel service) {
    final bool isSelected = selectedServices.any((s) => s.id == service.id);
    final bool hasProperties = service.numberOfBeds > 0 ||
        service.numberOfKitchens > 0 ||
        service.numberOfBalconies > 0 ||
        service.numberOfFamilyMembers > 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedServices.removeWhere((s) => s.id == service.id);
          } else {
            selectedServices.add(service);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.teal : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.teal.shade800
                                : Colors.black87,
                          ),
                        ),
                        if (service.categoryName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              service.categoryName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.teal.shade700
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (service.hasDiscount)
                        Text(
                          '₹${service.mrpPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade500,
                          ),
                        ),
                      Text(
                        '₹${service.finalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? Colors.teal.shade700 : Colors.teal,
                        ),
                      ),
                      if (service.hasDiscount)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '${((service.mrpPrice - service.sellingPrice) / service.mrpPrice * 100).round()}% off',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.8,
              color: isSelected ? Colors.teal.shade100 : Colors.grey.shade200,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  if (service.duration.isNotEmpty) ...[
                    Icon(Icons.schedule_rounded,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${service.duration} hr',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (service.extraPricePerDuration > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(+₹${service.extraPricePerDuration.toStringAsFixed(0)}/hr)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                  ],
                  if (service.description.isNotEmpty)
                    Expanded(
                      child: Text(
                        service.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (hasProperties) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                child: Text(
                  'Includes',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (service.numberOfBeds > 0)
                      _PropertyMiniChip(
                        icon: Icons.bed_rounded,
                        label:
                            '${service.numberOfBeds} Bed${service.numberOfBeds > 1 ? 's' : ''}',
                        price: service.pricePerBed,
                        isSelected: isSelected,
                      ),
                    if (service.numberOfKitchens > 0)
                      _PropertyMiniChip(
                        icon: Icons.countertops_rounded,
                        label:
                            '${service.numberOfKitchens} Kitchen${service.numberOfKitchens > 1 ? 's' : ''}',
                        price: service.pricePerKitchen,
                        isSelected: isSelected,
                      ),
                    if (service.numberOfBalconies > 0)
                      _PropertyMiniChip(
                        icon: Icons.balcony_rounded,
                        label:
                            '${service.numberOfBalconies} Balcon${service.numberOfBalconies > 1 ? 'ies' : 'y'}',
                        price: service.pricePerBalcony,
                        isSelected: isSelected,
                      ),
                    if (service.numberOfFamilyMembers > 0)
                      _PropertyMiniChip(
                        icon: Icons.people_alt_rounded,
                        label:
                            '${service.numberOfFamilyMembers} Member${service.numberOfFamilyMembers > 1 ? 's' : ''}',
                        price: service.pricePerFamilyMember,
                        isSelected: isSelected,
                      ),
                  ],
                ),
              ),
              if (service.propertyTotal > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.teal.shade100 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Base + Add-ons',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isSelected
                              ? Colors.teal.shade800
                              : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${service.sellingPrice.toStringAsFixed(0)} + ₹${service.propertyTotal.toStringAsFixed(0)} = ₹${service.finalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.teal.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSummary() {
    if (selectedServices.isEmpty) return const SizedBox.shrink();
    final total =
        selectedServices.fold<double>(0.0, (sum, s) => sum + s.finalPrice);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            '${selectedServices.length} service${selectedServices.length > 1 ? 's' : ''} selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            'Total: ₹${total.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(maidServiceProvider);
    final customers = ref.read(customerProvider);
    final slots = ref.watch(slotProvider);
    final List<ServiceModel> services = servicesAsync;
    final timeSlots = slots.where((slot) => slot.isAvailable).toList();

    bool isSameDay = startDate != null &&
        endDate != null &&
        AppConstants.isSameDay(startDate!, endDate!);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.shade300,
        title: Column(
          children: [
            Text(
              "${widget.initialBooking != null ? 'Update' : 'New'} Booking",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            if (widget.initialBooking != null)
              Text(
                "Booking #${widget.initialBooking!.bookingId}",
                style: const TextStyle(fontSize: 12, color: Colors.teal),
              ),
          ],
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              Theme.of(context).colorScheme.copyWith(primary: Colors.teal),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _currentStep == 4 ? _submitBooking : _nextStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepCancel: _prevStep,
          controlsBuilder: (context, details) {
            return Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _currentStep == 4 ? "Submit Booking" : "Next",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.teal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Back"),
                  ),
              ],
            );
          },
          steps: [
            // ── Step 1: Customer Info ────────────────────────────────────
            Step(
              title: const Text("Customer Info"),
              isActive: _currentStep >= 0,
              content: Form(
                key: customerInfoFormKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TypeAheadField<CustomerModel>(
                        suggestionsCallback: (pattern) {
                          if (pattern.length < 4) return [];
                          final filtered = customers
                              .where((c) => c.phone.contains(pattern))
                              .toList();
                          if (filtered.isEmpty) {
                            setState(() {
                              customerPhoneController.text = pattern;
                              customerNameController.text = "";
                              houseController.text = "";
                              areaController.text = "";
                              landmarkController.text = "";
                              cityController.text = "";
                              pinCodeController.text = "";
                              stateController.text = "";
                            });
                            return [];
                          }
                          return filtered;
                        },
                        builder: (context, ctrl, focusNode) {
                          return TextField(
                            controller: ctrl,
                            focusNode: focusNode,
                            autofocus: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Customer Phone',
                            ),
                          );
                        },
                        itemBuilder: (context, customer) => ListTile(
                          title: Text(customer.phone),
                          subtitle: Text(customer.name),
                        ),
                        onSelected: (customer) {
                          setState(() {
                            customerPhoneController.text = customer.phone;
                            customerNameController.text = customer.name;
                            houseController.text = customer.address.houseNumber;
                            areaController.text = customer.address.areaName;
                            landmarkController.text = customer.address.landmark;
                            cityController.text = customer.address.city;
                            pinCodeController.text = customer.address.pinCode;
                            stateController.text = customer.address.state;
                            countryController.text = customer.address.country;
                            address = AddressModel(
                              houseNumber: houseController.text.trim(),
                              areaName: areaController.text.trim(),
                              landmark: landmarkController.text.trim(),
                              city: cityController.text.trim(),
                              pinCode: pinCodeController.text.trim(),
                              state: stateController.text.trim(),
                              country: countryController.text.trim(),
                            );
                          });
                        },
                        controller: customerPhoneController,
                        emptyBuilder: (context) => const ListTile(
                          title: Text("No customer found"),
                        ),
                        hideOnEmpty: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: customerNameController,
                        decoration: inputDecoration.copyWith(
                          labelText: "Customer Name",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter name";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Step 2: Services ─────────────────────────────────────────
            Step(
              title: const Text("Services"),
              isActive: _currentStep >= 1,
              content: services.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: Colors.teal),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectedSummary(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Choose one or more services',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        ...services.map(_buildServiceCard).toList(),
                      ],
                    ),
            ),

            // ── Step 3: Date & Time ──────────────────────────────────────
            Step(
              title: const Text("Date & Time"),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: startDate != null && endDate != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd-MM-yyyy').format(startDate!),
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (!isSameDay) const Text("to"),
                              if (!isSameDay)
                                Text(
                                  DateFormat('dd-MM-yyyy').format(endDate!),
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          )
                        : const Text("Select Booking Date"),
                    trailing:
                        const Icon(Icons.calendar_today, color: Colors.teal),
                    onTap: _pickDateRange,
                  ),
                  const SizedBox(height: 8),
                  const Text("Select Time Slot"),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: timeSlots.map((slot) {
                      slot.serviceDate = selectedDate != null
                          ? bookingFormat.format(selectedDate!)
                          : "";
                      bool isDisabled =
                          isSlotExpiredDateRange(slot, startDate!);
                      bool isSelected = !isDisabled &&
                          selectedTimeSlot != null &&
                          slot.startTime == selectedTimeSlot!.startTime &&
                          slot.endTime == selectedTimeSlot!.endTime;
                      return ChoiceChip(
                        disabledColor: isDisabled ? Colors.grey.shade200 : null,
                        selectedColor: Colors.teal,
                        checkmarkColor:
                            isSelected ? Colors.white : Colors.black,
                        label: Text(
                          "${slot.startTime} - ${slot.endTime}",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: isDisabled
                            ? null
                            : (_) => setState(() {
                                  selectedTimeSlot = slot;
                                  individualSlots = generateSlotMapForRange(
                                    startDate: startDate!,
                                    endDate: endDate!,
                                    selectedSlot: slot,
                                  );
                                }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  if (!isSameDay &&
                      selectedTimeSlot != null &&
                      individualSlots.isNotEmpty)
                    ElevatedButton(
                      onPressed: _openDateWiseSlotSelection,
                      child: const Text("Customize Each Day's Slot"),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // ── Step 4: Address ──────────────────────────────────────────
            Step(
              title: const Text("Address"),
              isActive: _currentStep >= 3,
              content: Column(
                children: [
                  _buildTextField(houseController, "House / Building No."),
                  _buildTextField(areaController, "Area Name"),
                  _buildTextField(landmarkController, "Landmark"),
                  _buildTextField(cityController, "City"),
                  _buildTextField(pinCodeController, "Pin Code",
                      inputType: TextInputType.number),
                  _buildTextField(stateController, "State"),
                  _buildTextField(countryController, "Country"),
                ],
              ),
            ),

            // ── Step 5: Confirmation ─────────────────────────────────────
            Step(
              title: const Text("Confirmation"),
              isActive: _currentStep >= 4,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (individualSlots.length > 1)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Individual bookings will be created for each date.",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    "Review your booking details before submitting.",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  _buildConfirmSection(
                    title: "Customer Details",
                    rows: [
                      _ConfirmRow(
                          label: "Name", value: customerNameController.text),
                      _ConfirmRow(
                          label: "Phone", value: customerPhoneController.text),
                      _ConfirmRow(
                        label: "Address",
                        value: address!.houseNumber.isNotEmpty
                            ? address!.toString()
                            : "Not provided",
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmSection(
                    title: "Booking Date & Time",
                    rows: individualSlots.keys.toList().map((dateStr) {
                      final slot = individualSlots[dateStr]!;
                      return _ConfirmRow(
                        label: dateStr,
                        value: "${slot.startTime} - ${slot.endTime}",
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmServicesSection(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    decoration: inputDecoration.copyWith(
                      labelText: "Additional Notes",
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmSection({
    required String title,
    required List<_ConfirmRow> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.8),
          ...rows.map((row) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildConfirmServicesSection() {
    final subtotal =
        selectedServices.fold<double>(0.0, (sum, s) => sum + s.finalPrice);
    final int dayCount =
        individualSlots.isNotEmpty ? individualSlots.length : 1;
    final total = subtotal * dayCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              "Service Details",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.8),
          ...selectedServices.map((service) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '₹${service.finalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (service.hasDiscount)
                      Text(
                        'MRP ₹${service.mrpPrice.toStringAsFixed(0)}  •  Save ₹${(service.mrpPrice - service.finalPrice).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                        ),
                      ),
                    if (service.duration.isNotEmpty)
                      Text(
                        'Duration: ${service.duration} hr',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              )),
          const Divider(height: 1, thickness: 0.8),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                Text('₹${subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          if (dayCount > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '× $dayCount days',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper classes ────────────────────────────────────────────────────────

class _ConfirmRow {
  final String label;
  final String value;
  const _ConfirmRow({required this.label, required this.value});
}

class _PropertyMiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double price;
  final bool isSelected;

  const _PropertyMiniChip({
    required this.icon,
    required this.label,
    required this.price,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.teal.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: isSelected ? Colors.teal.shade600 : Colors.grey.shade600),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.teal.shade700 : Colors.grey.shade700,
            ),
          ),
          if (price > 0) ...[
            const SizedBox(width: 4),
            Text(
              '+₹${price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.teal.shade600 : Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
