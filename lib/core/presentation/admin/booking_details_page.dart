import 'package:bookmyservice/services/shared_preference_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/booking_model.dart';
import '../../../models/maid_model.dart';
import '../../../services/bookings_provider.dart';
import '../../../services/maids_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';
import '../maid/services/current_maid_provider.dart';

class BookingDetailsPage extends ConsumerStatefulWidget {
  final BookingModel currentBooking;
  const BookingDetailsPage({super.key, required this.currentBooking});

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingDetailsPage> {
  LatLng? targetLocation;
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddress();
  }

  Future<void> _getCoordinatesFromAddress() async {
    try {
      List<Location> locations = await locationFromAddress(
          widget.currentBooking.customerAddress.toString());
      if (locations.isNotEmpty) {
        setState(() {
          targetLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error converting address: $e');
    }
  }

  void _openInGoogleMapsDirections(LatLng destination) async {
    final Position? current = await getCurrentPosition();

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${current!.latitude},${current.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch Google Maps');
    }
  }

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    // 2. Check permission status
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are still denied
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // 3. If all good, get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
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
      (sum, service) =>
          sum +
          (service.discountPrice > 0
              ? service.discountPrice
              : service.minPrice),
    );

    return Scaffold(
      appBar: AppBar(
        title: commonTitle(),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final statusText =
                  AppConstants.getStatusText(value); // Helper to map status
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirmation"),
                  content: Row(
                    children: [
                      const Text(
                        "Do you want to mark ",
                      ),
                      Text(
                        " $statusText?",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, // Color based on status
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              debugPrint(
                "Status change confirmed: $confirmed, Role: ${userRole?.roleType}, Value: $value",
              );

              if (userRole != null &&
                  userRole.roleType.isNotEmpty &&
                  userRole.roleType == AppConstants.maid_role &&
                  value == AppConstants.accepted) {
                final maid = ref.read(currentMaidProvider);
                debugPrint(maid!.toMap().toString());
                booking.maid = maid;
                booking.assignedBy = 'Self'; // Maid assigns herself
                booking.maidId = maid.id;
              }

              if (confirmed == true) {
                if (value == AppConstants.inProgress &&
                    booking.maidId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please assign a maid before marking as In Progress.",
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                booking.assignedTime = booking.assignedTime!.isNotEmpty
                    ? booking.assignedTime
                    : (value == AppConstants.inProgress
                        ? DateFormat('dd-MM-yyyy HH:mm:ss')
                            .format(DateTime.now())
                        : '');
                booking.serviceCompletedTime = value == AppConstants.completed
                    ? DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())
                    : '';
                debugPrint(booking.maid!.toMap().toString());

                if (value == AppConstants.completed ||
                    value == AppConstants.cancelled) {
                  // Update maid availability if booking is completed or cancelled
                  ref.read(maidAccountProvider.notifier).updateMaidAvailability(
                        booking.maidId!,
                        true,
                      );
                }

                if (value == AppConstants.paid) {
                  // Update maid availability if booking is paid
                  final isPaidOnline =
                      await showPaymentConfirmationDialog(context);
                  booking.paymentInfo!.amount = totalPrice;
                  booking.paymentInfo!.createdAt = DateTime.now();
                  booking.paymentInfo!.status = AppConstants.paid;
                  booking.paymentInfo!.method =
                      isPaidOnline ? 'Online' : 'Cash';

                  ref.read(bookingsProvider.notifier).updatePaymentInfo(
                        booking,
                        booking.serviceStatus,
                      );
                } else {
                  ref.read(bookingsProvider.notifier).updateBookingStatus(
                        booking,
                        value,
                      );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Booking marked as $statusText",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              if (booking.serviceStatus != AppConstants.inProgress &&
                  booking.serviceStatus != AppConstants.accepted &&
                  booking.serviceStatus != AppConstants.completed)
                PopupMenuItem(
                  value: AppConstants.accepted,
                  child: _buildStatusChip(
                    'Accept',
                    Colors.green,
                  ),
                ),
              if (booking.serviceStatus == AppConstants.accepted &&
                  booking.serviceStatus != AppConstants.completed)
                PopupMenuItem(
                  value: AppConstants.inProgress,
                  child: _buildStatusChip(
                    'In Progress',
                    Colors.blue,
                  ),
                ),
              if (booking.serviceStatus == AppConstants.inProgress &&
                  booking.serviceStatus != AppConstants.completed)
                PopupMenuItem(
                  value: AppConstants.completed,
                  child: _buildStatusChip(
                    'Complete',
                    Colors.teal,
                  ),
                ),
              if (booking.serviceStatus == AppConstants.completed &&
                  booking.paymentInfo!.status != AppConstants.paid)
                PopupMenuItem(
                  value: AppConstants.paid,
                  child: _buildStatusChip(
                    'Mark as Paid',
                    Colors.teal,
                  ),
                ),
              if (booking.serviceStatus != AppConstants.inProgress &&
                  booking.serviceStatus != AppConstants.completed)
                PopupMenuItem(
                  value: AppConstants.cancelled,
                  child: _buildStatusChip(
                    'Cancel',
                    Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              title: '👤 Customer Information',
              children: [
                _infoRow(context, 'Name', booking.customerInfo.name),
                _infoRow(context, 'Phone', booking.customerInfo.phone),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: const Text(
                          "Address : ",
                          style: TextStyle(),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              booking.customerAddress.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            ElevatedButton.icon(
                              label: const Text(
                                'View on Map',
                                style: TextStyle(
                                  color: Colors.teal,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                //backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    25,
                                  ),
                                  side: BorderSide(
                                    width: 1,
                                    color: Colors.teal.shade100,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                _openInGoogleMapsDirections(targetLocation!);
                              },
                              icon: const Icon(
                                Icons.map,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // _infoRow(
                //   context,
                //   'Address',
                //   booking.customerAddress.toString(),
                // ),
                // Row(
                //   children: [
                //     _infoRow(
                //       context,
                //       'Address',
                //       booking.customerAddress.toString(),
                //     ),
                //     IconButton(
                //       onPressed: () {
                //         _openInGoogleMaps(targetLocation!);
                //       },
                //       icon: const Icon(
                //         Icons.map,
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              title: '🕒 Time Slot',
              children: [
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    booking.timeSlot.serviceDate!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${booking.timeSlot.startTime} - ${booking.timeSlot.endTime}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    AppConstants.getStatusText(booking.timeSlot.status),
                    style: TextStyle(
                      color:
                          AppConstants.getStatusColor(booking.timeSlot.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              title: '🛎️ Services',
              children: [
                ...booking.services.map((service) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: const Icon(Icons.room_service),
                    title: Text(service.name),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (service.discountPrice > 0)
                          Text(
                            '₹${service.minPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          '₹${(service.discountPrice > 0 ? service.discountPrice : service.minPrice).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }),

                // Add space
                const SizedBox(height: 8),

                // Total row inside the card
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
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
                      // if (booking.bookingSlots.length > 1)
                      //   Text(
                      //     "Price calculated for ${booking.bookingSlots.length} days",
                      //     style: const TextStyle(
                      //       fontSize: 12,
                      //       color: Colors.grey,
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.maid != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: _buildCard(
                  title: '🧹 Maid Info',
                  children: [
                    // AssignmentDetailsWidget(booking: booking),
                    // Center(
                    //   child: TextButton(
                    //     onPressed: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (_) => MaidAssignmentPage(
                    //             booking: booking,
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //     style: TextButton.styleFrom(
                    //       //backgroundColor: Colors.red,
                    //       elevation: 1.0,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(25),
                    //         side: const BorderSide(
                    //           color: Colors.grey,
                    //           width: 1.0,
                    //         ),
                    //       ),
                    //       minimumSize: const Size(
                    //         80,
                    //         30,
                    //       ),
                    //     ),
                    //     child: const Text(
                    //       'View and Assign Maid',
                    //     ),
                    //   ),
                    // ),
                    //     : IconButton(
                    //         onPressed: () {
                    //           showMaidSelectionSheet(context, ref, booking);
                    //         },
                    //         icon: const Icon(
                    //           Icons.person_add_alt,
                    //         ),
                    //       ),
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
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
              ),
            ],
            const SizedBox(height: 12),
            _buildCard(
              title: '📅 Booking Info',
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
                  _infoRow(
                      context, 'Parent Booking #', booking.parentBookingId),
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
                if (booking.maidId!.isNotEmpty)
                  _infoRow(
                    context,
                    'Commission ',
                    booking.maid!.commissionPercentage > 0
                        ? '${booking.maid!.commissionPercentage.toStringAsFixed(0)}%'
                        : '',
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
                    booking.paymentInfo!.status,
                  ),
                  status: booking.paymentInfo!.status,
                ),
                _infoRow(
                    context, 'Payment Id ', booking.paymentInfo!.paymentId),
                _infoRow(
                  context,
                  'Method',
                  booking.paymentInfo!.status == AppConstants.paid
                      ? booking.paymentInfo!.method
                      : '',
                ),
                _infoRow(
                  context,
                  'Payment Date',
                  booking.paymentInfo!.status == AppConstants.paid
                      ? DateFormat('dd-MM-yyyy HH:mm:ss')
                          .format(booking.paymentInfo!.createdAt)
                      : '',
                ),
              ],
            ),
            const SizedBox(height: 30),
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

  Widget _infoRow(BuildContext context, String label, String value,
      {String status = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.35,
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
}
