import 'package:bookmyservice/models/customer_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/authentication_provider.dart';
import '../../../services/bookings_provider.dart';
import '../../utils/app_constants.dart';
import 'customer_booking_details_page.dart';

class CustomerBookingHistoryPage extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  const CustomerBookingHistoryPage({Key? key, required this.customer})
      : super(key: key);

  @override
  ConsumerState<CustomerBookingHistoryPage> createState() =>
      _CustomerBookingHistoryPageState();
}

class _CustomerBookingHistoryPageState
    extends ConsumerState<CustomerBookingHistoryPage> {
  DateTimeRange? selectedRange;
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingsProvider);
    final bookingPro = ref.watch(bookingsProvider.notifier);
    final customerAsync = ref.watch(customerDetailsProvider);
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        backgroundColor: Colors.teal.shade300,
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                saveText: 'Done',
                confirmText: 'Done',
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                initialDateRange: selectedRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Colors.teal, // header background color
                        onPrimary: Colors.white, // header text color
                        onSurface: Colors.black, // body text color
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Colors.tealAccent, // button text color
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  selectedRange = picked;
                });

                final start =
                    selectedRange?.start ?? DateTime(now.year, now.month, 1);
                final end = selectedRange?.end ?? now;

                debugPrint(
                    "Selected Range: ${start.toIso8601String()} to ${end.toIso8601String()}");

                bookingPro.loadBookingsWithDateRange(
                    dateFormat.format(start), dateFormat.format(end));
              }
            },
            icon: const Icon(
              Icons.filter_alt,
              size: 20,
              color: Colors.white,
            ),
            //label: const Text("Filter"),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: bookingState.when(
        data: (bookings) {
          bookings = bookings
              .where(
                (element) =>
                    widget.customer != null &&
                    element.customerInfo.phone.isNotEmpty &&
                    element.customerInfo.phone == widget.customer!.phone,
              )
              .toList();
          return bookings.isNotEmpty
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const ScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerBookingDetailsPage(
                                    currentBooking: booking,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: Colors.teal,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Booking #${booking.bookingId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (booking.paymentInfo!.status ==
                                            AppConstants.paid)
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              Text(
                                                'paid',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        // Align(
                                        //   alignment: Alignment.centerRight,
                                        //   child: IconButton(
                                        //     onPressed: () {
                                        //       Navigator.push(
                                        //         context,
                                        //         MaterialPageRoute(
                                        //           builder: (_) =>
                                        //               NewBookingPage(
                                        //             initialBooking: booking,
                                        //           ),
                                        //         ),
                                        //       );
                                        //     },
                                        //     icon: const Icon(
                                        //       Icons.edit,
                                        //       size: 20,
                                        //     ),
                                        //   ),
                                        // )
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Text(booking.customerInfo.name),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Text(booking.customerInfo.phone),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(booking.customerAddress
                                                .toString())),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                            'Booked : ${DateFormat('dd-MM-yyyy HH:mm:ss').format(booking.bookingDate)}'),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.cleaning_services_outlined,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Maid: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.52,
                                          child: Text(
                                            booking.maid!.name.isNotEmpty
                                                ? booking.maid!.name
                                                : 'Not Assigned',
                                          ),
                                        ),
                                        // if (booking.serviceStatus !=
                                        //         AppConstants.completed &&
                                        //     booking.serviceStatus !=
                                        //         AppConstants.cancelled)
                                        //   Align(
                                        //     alignment: Alignment.centerRight,
                                        //     child: IconButton(
                                        //       onPressed: () {
                                        //         showMaidSelectionSheet(
                                        //             context, ref, booking);
                                        //       },
                                        //       icon: const Icon(
                                        //         Icons.person_add_alt,
                                        //       ),
                                        //     ),
                                        //   )
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Status : ',
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          AppConstants.getStatusText(
                                            booking.serviceStatus,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppConstants.getStatusColor(
                                              booking.serviceStatus,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1,
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🖼️ Image
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage(
                              'assets/images/cleaning home page.jpg',
                            ), // Replace with your image path
                            fit: BoxFit.fill,
                          ),
                        ),
                        width: 200,
                        height: 200,
                      ),

                      const SizedBox(height: 20),

                      // 📝 Text
                      const Text(
                        'Your Bookings will appear here',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
