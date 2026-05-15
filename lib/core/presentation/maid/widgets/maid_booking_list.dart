import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/booking_model.dart';
import '../../../utils/app_constants.dart';
import '../../../widgets/new_booking_blinking.dart';
import '../../admin/booking_details_page.dart';
import '../page/maid_booking_details_page.dart';

class MaidBookingList extends StatelessWidget {
  const MaidBookingList({
    super.key,
    required this.bookings,
  });

  final List<BookingModel> bookings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                        builder: (_) => MaidBookingDetailsPage(
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
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                              const SizedBox(
                                width: 10,
                              ),
                              if (booking.maid!.name.isEmpty &&
                                  (booking.serviceStatus !=
                                          AppConstants.completed ||
                                      booking.serviceStatus !=
                                          AppConstants.cancelled))
                                const BlinkingNewTag(
                                  status: 'New',
                                ),
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
                          // Row(
                          //   children: [
                          //     const Icon(
                          //         Icons.cleaning_services_outlined,
                          //         size: 20),
                          //     const SizedBox(width: 8),
                          //     const Text('Maid: ',
                          //         style: TextStyle(
                          //             fontWeight: FontWeight.bold)),
                          //     SizedBox(
                          //       width: MediaQuery.of(context)
                          //               .size
                          //               .width *
                          //           0.38,
                          //       child: Text(
                          //         booking.maid!.name.isNotEmpty
                          //             ? booking.maid!.name
                          //             : 'Not Assigned',
                          //       ),
                          //     ),
                          //     // Text(
                          //     //   AppConstants.getTimeDifference(
                          //     //     dateFormat2
                          //     //         .format(booking.bookingDate),
                          //     //     dateFormat2.format(now),
                          //     //   ),
                          //     //   style: const TextStyle(
                          //     //     fontSize: 14,
                          //     //     color: Colors.red,
                          //     //     fontWeight: FontWeight.bold,
                          //     //   ),
                          //     // ),
                          //     // if (booking.serviceStatus !=
                          //     //         AppConstants.completed &&
                          //     //     booking.serviceStatus !=
                          //     //         AppConstants.cancelled)
                          //     //   Align(
                          //     //     alignment: Alignment.centerRight,
                          //     //     child: IconButton(
                          //     //       onPressed: () {
                          //     //         showMaidSelectionSheet(
                          //     //             context, ref, booking);
                          //     //       },
                          //     //       icon: const Icon(
                          //     //         Icons.person_add_alt,
                          //     //       ),
                          //     //     ),
                          //     //   )
                          //   ],
                          // ),
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
      );
  }
}