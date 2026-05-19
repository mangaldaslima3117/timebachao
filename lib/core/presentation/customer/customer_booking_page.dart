import 'package:bookmyservice/models/payment_info_model.dart';
import 'package:bookmyservice/services/app_account_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/address_model.dart';
import '../../../models/booking_model.dart';
import '../../../models/customer_model.dart';
import '../../../models/maid_model.dart';
import '../../../models/service_model.dart';
import '../../../models/service_area_model.dart';
import '../../../models/slot_model.dart';
import '../../../services/authentication_provider.dart';
import '../../../services/bookings_provider.dart';
import '../../../services/customer_provider.dart';
import '../../../services/service_provider.dart';
import '../../../services/service_area_provider.dart';
import '../../../services/slots_provider.dart';
import '../../../services/user_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/common_function.dart';
import '../../widgets/datewise_slot_selector.dart'; // You must have this

class CustomerBookingPage extends ConsumerStatefulWidget {
  final BookingModel? initialBooking;
  const CustomerBookingPage({super.key, this.initialBooking});

  @override
  ConsumerState<CustomerBookingPage> createState() =>
      _CustomerBookingPageState();
}

class _CustomerBookingPageState extends ConsumerState<CustomerBookingPage> {
  int _currentStep = 0;

  TextEditingController customerIdController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerPhoneController = TextEditingController();
  TextEditingController customerGenderController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  //Address fields controller
  TextEditingController houseController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  TextEditingController landmarkController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController countryController = TextEditingController();

  List<ServiceModel> selectedServices = <ServiceModel>[];
  DateTime? selectedDate;
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
  List<String> sortedDates = [];

  void _nextStep() {
    bool isValid = false;

    if (_currentStep == 0) {
      isValid = customerInfoFormKey.currentState?.validate() ?? false;
    } else {
      isValid = true;
    }

    if (isValid) {
      setState(() {
        _currentStep += 1;
      });
    }
    //if (_currentStep < 4) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _defaultStateIfEmpty(String value) {
    return value.trim().isEmpty ? AddressModel.defaultState : value;
  }

  String _defaultCountryIfEmpty(String value) {
    return value.trim().isEmpty ? AddressModel.defaultCountry : value;
  }

  bool _ensureServiceableArea() {
    final city = cityController.text.trim();
    final area = areaController.text.trim();
    final serviceAreas = ref.read(serviceAreaProvider).maybeWhen(
          data: (areas) => areas,
          orElse: () => null,
        );

    if (serviceAreas == null) {
      _showSnack("Please wait while service areas load");
      return false;
    }

    if (ServiceAreaModel.isServiceableArea(serviceAreas, city, area)) {
      return true;
    }

    final activeAreas =
        ServiceAreaModel.activeAreaNamesForCity(serviceAreas, city);
    final hint = activeAreas.isEmpty
        ? " No active areas found for $city."
        : " Available in $city: ${activeAreas.take(5).join(', ')}.";
    _showSnack("Service is not available in $area, $city.$hint");
    return false;
  }

  void _submitBooking() async {
    String? duplicateMessage = '';
    final appAccount = ref.read(appAccountProvider);
    final userDtl = ref.read(userProvider);

    if (customerNameController.text.isEmpty ||
        customerPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill customer information"),
        ),
      );
      return;
    }

    if (selectedDate == null ||
        selectedTimeSlot == null ||
        selectedTimeSlot!.startTime.isEmpty ||
        selectedTimeSlot!.endTime.isEmpty ||
        selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select date and time slot "),
        ),
      );
      return;
    }

    //Validate for address
    if (houseController.text.isEmpty ||
        areaController.text.isEmpty ||
        cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter address "),
        ),
      );
      return;
    }
    if (!_ensureServiceableArea()) {
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
      appAccountId: appAccount != null
          ? appAccount.appAccountId
          : "", // replace with actual admin account ID,
      profileImageUrl: '',
      fcmToken: '',
    );

    double totalServicePrice = selectedServices.fold<double>(
      0.0,
      (sum, service) => sum + service.finalPrice,
    );
    double totalPrice = totalServicePrice * individualSlots.length;

    BookingModel booking = BookingModel(
      bookingId: bookingId,
      appAccountId: appAccount != null
          ? appAccount.appAccountId
          : "", // replace with actual admin account ID
      customerId: customerInfo!.phone.trim(),
      maidId: isBookingExist ? widget.initialBooking!.maid!.id : '',
      services: selectedServices,
      status: isBookingExist
          ? widget.initialBooking!.serviceStatus
          : "1", // Booking
      totalPrice: totalPrice,
      customerAddress: address!,
      bookingDate:
          isBookingExist ? widget.initialBooking!.bookingDate : DateTime.now(),
      timeSlot: selectedTimeSlot!,
      note: noteController.text.trim(),
      assignedByAdmin: true,
      serviceCompletedTime: "", // dummy for now
      serviceCompletedMarkedById: "",
      serviceCompletedMarkedByName: "",
      serviceStatus: isBookingExist
          ? widget.initialBooking!.serviceStatus
          : "1", // Booking
      cancellationReason: "",
      bookedBy: userDtl != null ? userDtl.role.roleType : '',
      maid: isBookingExist
          ? widget.initialBooking!.maid
          : MaidModel.getDefaultMaid(), // Maid details can be added later
      totalTimeTaken:
          isBookingExist ? widget.initialBooking!.totalTimeTaken : '',
      customerInfo: customerInfo!,
      assignedTime: '',
      assignedBy: '', // This can be set later if needed
      bookedOn: bookingFormat.format(
        DateTime.now(),
      ),
      commissionPercentage: 0, // Current time as booking time
      paymentInfo: PaymentInfoModel.defaultPayment(),
      bookingSlots: individualSlots.values
          .toList(), // Add the selected time slot to the booking
      startDate: selectedDate != null
          ? bookingFormat.format(selectedDate!)
          : "", // Format the date for the booking
      endDate: selectedDate != null
          ? bookingFormat.format(selectedDate!
              .add(const Duration(days: 1))) // Assuming end date is next day
          : "", // Format the date for the booking
      taxPercentage: appAccount != null ? appAccount.taxPercentage : 0.0,
      parentBookingId: individualSlots.length > 1
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : '', // Unique ID for parent booking
    );

    if (widget.initialBooking != null &&
        widget.initialBooking!.bookingId.isNotEmpty) {
      await ref.read(bookingsProvider.notifier).updateBooking(booking);
    } else {
      //await ref.read(bookingsProvider.notifier).createBooking(booking);
      duplicateMessage = await ref
          .read(bookingsProvider.notifier)
          .createBookingsBatch(booking);
    }

    if (duplicateMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(duplicateMessage),
        ),
      );
      return;
    }

    // Add or update customer details
    // This will add or update the customer details in the database
    await ref.read(customerProvider.notifier).addCustomer(booking.customerInfo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.initialBooking != null &&
                widget.initialBooking!.bookingId.isNotEmpty
            ? "Booking Updated !"
            : "Booking Successfully Created!"),
      ),
    );
    Navigator.pop(context);
  }

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

  @override
  void initState() {
    super.initState();
    final customer = ref.read(customerDetailsProvider);

    // Action for new booking
    BookingModel booking = BookingModel.getDefaultBookingModel();
    if (customer.value != null) {
      debugPrint('CUSTOMER INFO');
      debugPrint(customer.value!.toMap().toString());
      customerInfo = customer.value!;
      booking.customerAddress = customer.value!.address;
      booking.customerInfo = customer.value!;
    }
    houseController =
        TextEditingController(text: booking.customerAddress.houseNumber);
    areaController =
        TextEditingController(text: booking.customerAddress.areaName);
    landmarkController =
        TextEditingController(text: booking.customerAddress.landmark);
    cityController = TextEditingController(text: booking.customerAddress.city);
    pinCodeController =
        TextEditingController(text: booking.customerAddress.pinCode);
    stateController = TextEditingController(
        text: _defaultStateIfEmpty(booking.customerAddress.state));
    countryController = TextEditingController(
        text: _defaultCountryIfEmpty(booking.customerAddress.country));

    address = AddressModel(
      houseNumber: houseController.text.trim(),
      areaName: areaController.text.trim(),
      landmark: landmarkController.text.trim(),
      city: cityController.text.trim(),
      pinCode: pinCodeController.text.trim(),
      state: stateController.text.trim(),
      country: countryController.text.trim(),
    );

    //Set the customer details
    customerNameController.text = booking.customerInfo.name;
    customerPhoneController.text = booking.customerInfo.phone;

    //Set the selected service
    selectedServices = booking.services;

    //Set the time slot and date
    selectedDate = booking.bookingDate;
    selectedTimeSlot = booking.timeSlot;
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text}) {
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

  Widget _buildServiceAreaStatus(
    AsyncValue<List<ServiceAreaModel>> serviceAreasState,
  ) {
    final city = cityController.text.trim();
    final area = areaController.text.trim();

    if (city.isEmpty || area.isEmpty) {
      return const SizedBox.shrink();
    }

    final serviceAreas = serviceAreasState.valueOrNull;
    if (serviceAreas == null) {
      return _buildAreaStatusBanner(
        icon: Icons.schedule_outlined,
        message: 'Checking service availability...',
        color: Colors.grey,
      );
    }

    final isServiceable =
        ServiceAreaModel.isServiceableArea(serviceAreas, city, area);

    return _buildAreaStatusBanner(
      icon: isServiceable ? Icons.check_circle_outline : Icons.block_outlined,
      message: isServiceable
          ? 'Service is available in $area, $city'
          : 'Service is not available in $area, $city',
      color: isServiceable ? Colors.green : Colors.red,
    );
  }

  Widget _buildAreaStatusBanner({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    ).then((value) {
      // After returning from DateWiseSlotSelector, update the selectedTimeSlots
      setState(() {
        selectedTimeSlots = individualSlots.values.toList();
        sortedDates = individualSlots.keys.toList()
          ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
      });
    });
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
                  primary: Colors.teal, // Selection circle + header color
                  onPrimary: Colors.white, // Text on selected date
                  surface: Colors.white,
                  onSurface: Colors.black, // Default text color
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
        selectedTimeSlot =
            null; // Reset selected time slot when date range changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(maidServiceProvider);
    final serviceAreasState = ref.watch(serviceAreaProvider);
    final customers = ref.read(customerProvider);
    List<ServiceModel> services = servicesAsync;
    final slots = ref.watch(slotProvider);
    final slotAsync = ref.watch(slotStreamProvider);
    //final timeSlots = TimeSlotModel.generateDefaultTimeSlots();
    final timeSlots = slots;
    debugPrint('CUSTOMERS ${customers.length}');
    bool isSameDay = startDate != null &&
        endDate != null &&
        AppConstants.isSameDay(startDate!, endDate!);
    debugPrint('SAME DAY: $isSameDay, Start: $startDate, End: $endDate');

    return Scaffold(
      appBar: AppBar(
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.teal,
                ),
              ),
          ],
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary:
                    Colors.teal, // Active/complete step color (circle + text)
              ),
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
                    backgroundColor: Colors.teal.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _currentStep == 4 ? "Submit" : "Next",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
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
            // Step 1: Customer Info
            Step(
              title: const Text("Customer Info"),
              isActive: _currentStep >= 0,
              content: Form(
                key: customerInfoFormKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: customerPhoneController,
                        autofocus: false,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Customer Phone',
                        ),
                      ),
                      // child: TextFormField(
                      //   controller: customerPhoneController,
                      //   decoration: inputDecoration.copyWith(
                      //     labelText: "Customer Phone",
                      //   ),
                      //   keyboardType: TextInputType.number,
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return "Enter phone number";
                      //     }
                      //     if (value.length != 10) {
                      //       return "Enter 10 digit phone number";
                      //     }
                      //     return null;
                      //   },
                      // ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        readOnly: true,
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
            // Step 2: Services
            Step(
              title: const Text("Services"),
              isActive: _currentStep >= 1,
              content: services.isEmpty
                  ? const CircularProgressIndicator() // or a message
                  : Column(
                      children: [
                        ...services.map((service) {
                          bool isSelected =
                              selectedServices.any((s) => s.id == service.id);
                          //final isSelected = selectedServices.contains(service);
                          return CheckboxListTile(
                            title: Text(service.name),
                            subtitle: service.hasDiscount
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹${service.finalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        '₹${service.mrpPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor: Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    '₹${service.mrpPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                            value: isSelected,
                            onChanged: (selected) {
                              debugPrint('SERVICE UNCHECKED $selected');
                              setState(() {
                                if (selected!) {
                                  selectedServices.add(service);
                                } else {
                                  selectedServices
                                      .removeWhere((s) => s.id == service.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
            ),
            // Step 3: Date and Time
            Step(
              title: const Text("Date & Time"),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
                  ListTile(
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
                                )
                            ],
                          )
                        : const Text("Select Booking Date"),
                    trailing: const Icon(
                      Icons.calendar_today,
                      color: Colors.teal,
                    ),
                    onTap: () async {
                      // final picked = await showDatePicker(
                      //   context: context,
                      //   initialDate:
                      //       DateTime.now().add(const Duration(days: 1)),
                      //   firstDate: DateTime.now(),
                      //   lastDate: DateTime.now().add(const Duration(days: 365)),
                      // );

                      // if (picked != null) {
                      //   setState(() {
                      //     selectedDate = picked;
                      //     selectedTimeSlot =
                      //         null; // Reset time slot on date change
                      //   });
                      // }

                      _pickDateRange();
                    },
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
                      bool isDisabled = isSlotExpiredDateRange(
                        slot,
                        startDate!, // Use startDate for consistency
                      );
                      debugPrint(
                          'Slot: ${slot.startTime} - ${slot.endTime}, Disabled: $isDisabled');

                      bool isSelected = !isDisabled &&
                          selectedTimeSlot != null &&
                          slot.startTime == selectedTimeSlot!.startTime &&
                          slot.endTime == selectedTimeSlot!.endTime;
                      debugPrint(
                          'Selected Time Slot: ${selectedTimeSlot?.startTime} - ${selectedTimeSlot?.endTime}, Current Slot: ${slot.startTime} - ${slot.endTime}, Is Selected: $isSelected');
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
                                  debugPrint('MAP VALUE');
                                  individualSlots.forEach((key, value) {
                                    debugPrint(
                                        'Date: $key, Slot: ${value.startTime} - ${value.endTime}');
                                  });

                                  // debugPrint(
                                  //     'Selected Slot: ${slot.startTime} - ${slot.endTime}, Date: ${slot.serviceDate}');
                                }),
                      );
                    }).toList(),
                  ),

                  //UNCOMMENT BELOW CODE IF YOU WANT TO USE DATEWISE SLOT SELECTION
                  const SizedBox(height: 10),
                  if (!isSameDay)
                    const SizedBox(
                      height: 10,
                    ),
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
            // Step 4: Address
            Step(
              title: const Text("Address"),
              isActive: _currentStep >= 3,
              content: Column(
                children: [
                  _buildTextField(houseController, "House / Building No."),
                  _buildTextField(areaController, "Area Name"),
                  _buildTextField(landmarkController, "Landmark"),
                  _buildTextField(cityController, "City"),
                  _buildServiceAreaStatus(serviceAreasState),
                  _buildTextField(pinCodeController, "Pin Code",
                      inputType: TextInputType.number),
                  _buildTextField(stateController, "State"),
                  _buildTextField(countryController, "Country"),
                ],
              ),
            ),
            // Step 5: Note & Confirm
            Step(
              title: const Text("Confirmation"),
              isActive: _currentStep >= 4,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (individualSlots.length > 1)
                    const Text(
                      "Individual booking will be created for each date.",
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  const Text(
                    "Please review your booking details before submitting.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Customer Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 5),
                      const Divider(height: 1),
                      const SizedBox(height: 5),
                      Text("Name:     ${customerNameController.text}"),
                      Text("Phone:    ${customerPhoneController.text}"),
                      Text(
                          "Address:  ${address!.houseNumber.isNotEmpty ? address!.toString() : "Not provided"}"),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    "Booking Date & Time",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 5),
                  const Divider(height: 1),
                  const SizedBox(height: 5),
                  ...individualSlots.keys.toList().map((dateStr) {
                    final slot = individualSlots[dateStr]!;
                    // final formattedDate = DateFormat('dd-MM-yyyy')
                    //     .format(DateTime.parse(dateStr));

                    return Text(
                      "$dateStr,  Time : ${slot.startTime} - ${slot.endTime}",
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 5),
                  const Divider(height: 1),
                  const SizedBox(height: 5),
                  const Text(
                    "Service Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 5),
                  const Divider(height: 1),
                  const SizedBox(height: 5),
                  ...selectedServices.map((service) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.35,
                          child: Text(
                            service.name,
                            softWrap: true,
                          ),
                        ),
                        Text(
                            "₹${service.hasDiscount ? service.finalPrice.toStringAsFixed(0) : service.mrpPrice.toStringAsFixed(0)}"),
                      ],
                    );
                  }).toList(),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        "Sub Total : ₹${selectedServices.fold(0, (sum, s) => sum.toInt() + s.finalPrice.toInt()).toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Divider(height: 1),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        "Total : ₹${(individualSlots.length * selectedServices.fold(0, (sum, s) => sum.toInt() + (s.hasDiscount ? s.finalPrice : s.mrpPrice).toInt())).toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (individualSlots.length > 1)
                    Row(
                      children: [
                        const Spacer(),
                        Text(
                          "Price calculated for ${individualSlots.length} days",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  const SizedBox(height: 5),
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
}
