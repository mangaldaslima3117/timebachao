import 'package:bookmyservice/services/shared_preference_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/booking_model.dart';
import '../../../models/maid_model.dart';
import '../../../services/bookings_provider.dart';
import '../../../services/maids_provider.dart';
import '../../../services/payment_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/common_function.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dynamic_calendar.dart';
import '../../widgets/live_tracking_map.dart';
import '../../widgets/paypment_options_widget.dart';

class CustomerBookingDetailsPage extends ConsumerStatefulWidget {
  final BookingModel currentBooking;
  const CustomerBookingDetailsPage({super.key, required this.currentBooking});

  @override
  ConsumerState<CustomerBookingDetailsPage> createState() =>
      _CustomerBookingDetailsPageState();
}

class _CustomerBookingDetailsPageState
    extends ConsumerState<CustomerBookingDetailsPage> {
  String result = "";
  bool isPaymentDone = false;
  late PaymentService paymentService;
  LatLng? customerLocation;

  @override
  void initState() {
    super.initState();
    paymentService = PaymentService(
      ref: ref,
      booking: widget.currentBooking,
      context: context,
    );
    _fetchDestination();
  }

  @override
  dispose() {
    paymentService.dispose(); // Dispose Razorpay instance
    super.dispose();
  }

  void _fetchDestination() async {
    //Get latitude and longitude from the customer address.
    final latLang = await getLatLngFromAddress(
        widget.currentBooking.customerAddress.toString());

    if (latLang != null) {
      debugPrint('CUSTOMERS CURRENT LOCATION ${latLang.toJson()}');
      setState(() {
        customerLocation = latLang;
      });
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  void initiatePayment(WidgetRef ref, BookingModel booking) {
    paymentService = PaymentService(
      ref: ref,
      booking: booking,
      context: context,
    );

    paymentService.razorPayAndPlaceOrder(booking);
  }

  unassignMaid(WidgetRef ref, BuildContext context, BookingModel booking) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Do you want to unassign the maid?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              // Unassign maid logic here
              await ref
                  .read(maidAccountProvider.notifier)
                  .updateMaidAvailability(
                    booking.maidId!,
                    true,
                  );
              //reset these fields
              booking.maidId = "";
              booking.maid = MaidModel.getDefaultMaid();
              await ref.read(bookingsProvider.notifier).assignMaid(
                    booking,
                  );

              Navigator.pop(context, true);
            },
            child: const Text(
              "Unassign",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    BookingModel booking =
        ref.watch(bookingByIdProvider(widget.currentBooking.bookingId))!;
    final userRole = ref.watch(roleProvider);

    final totalPrice = booking.services.fold<double>(
      0.0,
      (sum, service) => sum + service.finalPrice,
    );

    return Scaffold(
      appBar: AppBar(
        title: commonTitle(),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (booking.serviceStatus == AppConstants.accepted &&
                customerLocation != null)
              LiveTrackingMap(
                bookingId: booking.bookingId,
                destination: customerLocation!,
              ),
            _buildCard(
              title: '👤 Customer Information',
              children: [
                _infoRowWidget(context, 'Name', booking.customerInfo.name),
                _infoRowWidget(
                    context, 'Phone', '+91 ${booking.customerInfo.phone}'),
                _infoRowWidget(
                    context, 'Address', booking.customerAddress.toString()),
                // _infoRow(context, 'Name', booking.customerInfo.name),
                // _infoRow(context, 'Phone', booking.customerInfo.phone),
                // _infoRow(
                //     context, 'Address', booking.customerAddress.toString()),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              title: '🛎️ Services',
              children: [
                ...booking.services.map((service) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline),
                        const SizedBox(
                          width: 8,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (service.hasDiscount)
                                Text(
                                  '₹${service.finalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                '₹${(service.hasDiscount ? service.finalPrice : service.mrpPrice).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  // return ListTile(
                  //   contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  //   leading: const Icon(Icons.check_circle_outline),
                  //   title: Text(service.name),
                  //   trailing: Column(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     crossAxisAlignment: CrossAxisAlignment.end,
                  //     children: [
                  //       if (service.discountPrice > 0)
                  //         Text(
                  //           '₹${service.minPrice.toStringAsFixed(0)}',
                  //           style: const TextStyle(
                  //             decoration: TextDecoration.lineThrough,
                  //             fontSize: 12,
                  //             color: Colors.red,
                  //           ),
                  //         ),
                  //       Text(
                  //         '₹${(service.discountPrice > 0 ? service.discountPrice : service.minPrice).toStringAsFixed(0)}',
                  //         style: const TextStyle(fontSize: 16),
                  //       ),
                  //     ],
                  //   ),
                  // );
                }),

                // Add space
                const SizedBox(height: 8),

                // Total row inside the card
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Price : ',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      // Use the same totalPrice calculation
                      Text(
                        '₹${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              title: '🕒 Time Slot',
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    '${booking.timeSlot.startTime} - ${booking.timeSlot.endTime}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.timeSlot.serviceDate!,
                        style: const TextStyle(),
                      ),
                      // Text(
                      //     'Duration: ${booking.timeSlot.durationMinutes} mins'),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.maid != null) ...[
              const SizedBox(height: 12),
              _buildCard(
                title: '🧹 Assigned Maid',
                children: [
                  ListTile(
                    leading: booking.maid!.profilePictureUrl!.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(
                              booking.maid!.profilePictureUrl!,
                            ),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                    title: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: Text(booking.maid!.name),
                    ),
                    subtitle: booking.maidId!.isNotEmpty
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            child: Text('Mobile : ${booking.maid!.phone}'))
                        : const Text(''),
                    // trailing: booking.maidId!.isNotEmpty &&
                    //         booking.serviceStatus != AppConstants.completed
                    //     ? IconButton(
                    //         onPressed: () {
                    //           unassignMaid(ref, context, booking);
                    //         },
                    //         icon: const Icon(
                    //           Icons.cancel_outlined,
                    //           color: Colors.red,
                    //         ),
                    //       )
                    //     : IconButton(
                    //         onPressed: () {
                    //           showMaidSelectionSheet(context, ref, booking);
                    //         },
                    //         icon: const Icon(
                    //           Icons.person_add_alt,
                    //         ),
                    //       ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      'Assigned On : ${booking.assignedTime!.isNotEmpty ? booking.assignedTime : ''}',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      'Assigned By : ${booking.assignedBy!.isNotEmpty ? booking.assignedBy : ''}',
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  if (userRole != null &&
                      userRole.roleType.isNotEmpty &&
                      userRole.roleType == AppConstants.admin_role &&
                      booking.maidId!.isNotEmpty &&
                      booking.serviceStatus != AppConstants.completed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (userRole.roleType.isNotEmpty &&
                            userRole.roleType == AppConstants.admin_role &&
                            booking.maidId!.isNotEmpty &&
                            booking.serviceStatus != AppConstants.completed)
                          TextButton(
                            onPressed: () {
                              unassignMaid(ref, context, booking);
                            },
                            style: TextButton.styleFrom(
                              //backgroundColor: Colors.red,
                              elevation: 1.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              minimumSize: const Size(
                                80,
                                30,
                              ),
                            ),
                            child: const Text(
                              'Unassign',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            showMaidSelectionSheet(context, ref, booking);
                          },
                          style: TextButton.styleFrom(
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            minimumSize: const Size(
                              80,
                              30,
                            ),
                            side: const BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          child: const Text(
                            'Change Maid',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.teal,
                            ),
                          ),
                        )
                      ],
                    ),
                  if (userRole != null &&
                      userRole.roleType.isNotEmpty &&
                      userRole.roleType == AppConstants.admin_role &&
                      booking.maidId!.isEmpty &&
                      booking.serviceStatus != AppConstants.completed)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          showMaidSelectionSheet(context, ref, booking);
                        },
                        style: TextButton.styleFrom(
                          elevation: 1.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          minimumSize: const Size(
                            80,
                            30,
                          ),
                          side: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: const Text(
                          'Assign Maid',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ],
            const SizedBox(height: 12),
            _bookingInfoCard(
              title: Row(
                children: [
                  DynamicCalendarIcon(
                    bookedOn: booking.bookedOn!,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  const Text(
                    'Booking Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              children: [
                _infoRow(
                  context,
                  'Status ',
                  AppConstants.getStatusText(
                    booking.serviceStatus,
                  ),
                  status: booking.serviceStatus,
                ),
                _infoRow(context, 'Booking #', booking.bookingId),
                if (booking.parentBookingId.isNotEmpty)
                  _infoRow(context, 'Parent Booking', booking.parentBookingId),
                if (booking.otp.isNotEmpty &&
                    booking.otpVerifiedTime.isEmpty &&
                    booking.serviceStatus != AppConstants.completed &&
                    booking.serviceStatus != AppConstants.cancelled)
                  _infoRow(context, 'Start OTP', booking.otp),
                _infoRow(
                  context,
                  'Booked On',
                  DateFormat('dd-MM-yyyy HH:mm:ss').format(booking.bookingDate),
                ),
                _infoRow(
                  context,
                  'Booked By',
                  booking.bookedBy,
                ),
                if (booking.serviceStatus == AppConstants.completed) ...[
                  _infoRow(
                    context,
                    'Completed On',
                    booking.serviceCompletedTime,
                  ),
                ],
                if (booking.serviceStatus == AppConstants.completed &&
                    booking.assignedTime!.isNotEmpty &&
                    booking.serviceCompletedTime.isNotEmpty) ...[
                  _infoRow(
                    context,
                    'Service Time ',
                    AppConstants.getTimeDifference(
                        booking.assignedTime!, booking.serviceCompletedTime),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              title: '💳 Payment Info',
              children: [
                _infoRow(
                  context,
                  'Status ',
                  AppConstants.getStatusText(
                    booking.paymentInfo?.status ?? AppConstants.paid,
                  ),
                  status: booking.serviceStatus,
                ),
                _infoRow(
                  context,
                  'Amount',
                  booking.paymentInfo!.amount > 0
                      ? '₹ ${booking.paymentInfo!.amount.toStringAsFixed(2)}'
                      : '',
                ),
                _infoRow(context, 'Method', booking.paymentInfo!.method),
                if (booking.paymentInfo!.method ==
                    AppConstants.PAYMENT_ONLINE) ...[
                  _infoRow(
                      context, 'Payment Id', booking.paymentInfo!.paymentId),
                ],
                _infoRow(
                  context,
                  'Payment Time',
                  DateFormat('dd-MM-yyyy HH:mm:ss').format(
                    booking.paymentInfo!.createdAt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (booking.serviceStatus == AppConstants.completed &&
                booking.paymentInfo!.status == AppConstants.pending)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Color based on status
                ),
                onPressed: () {
                  //initiatePayment(ref, booking);
                  showPaymentOptions(context, (method) async {
                    if (method == 'cash') {
                      // Navigate to confirmation or place order directly
                      final confirmed = await showCashConfirmationDialog(
                        context,
                      );
                      if (confirmed == true) {
                        // User confirmed: Proceed with placing booking
                        debugPrint("Confirmed: Cash on Service");
                        paymentService.initiatePayment(
                            ref, booking, false); // Handle cash payment
                      } else {
                        // User canceled
                        debugPrint("Cancelled");
                      }
                    } else if (method == 'online') {
                      // Redirect to Razorpay
                      paymentService.initiatePayment(
                          ref, booking, true); // Handle online payment
                    }
                  });
                },
                child: const Text(
                  "Proceed to Payment",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(
              height: 50,
            ),
          ],
        ),
      ),
    );
  }

  Text commonTitle() => const Text(
        "Booking Details",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _bookingInfoCard(
      {required Widget title, required List<Widget> children}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value,
      {String status = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: Text(
              "$label: ",
              style: const TextStyle(),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: status.isNotEmpty
                    ? AppConstants.getStatusColor(
                        status,
                      )
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWidget(BuildContext context, String label, String value,
      {String status = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: status.isNotEmpty
                  ? AppConstants.getStatusColor(
                      status,
                    )
                  : Colors.black,
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
