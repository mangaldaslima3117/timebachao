import 'package:bookmyservice/core/presentation/admin/new_booking_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../services/shared_preference_provider.dart';
import '../presentation/admin/booking_details_page.dart';
import '../utils/app_constants.dart';
import 'booking_not_found_widget.dart';

class BookingListView extends ConsumerWidget {
  final List<BookingModel> bookings;
  const BookingListView({super.key, required this.bookings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final isMaid = role?.roleType == AppConstants.maid_role;

    return SingleChildScrollView(
      child: bookings.isNotEmpty
          ? Column(
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
                            builder: (_) => BookingDetailsPage(
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
                                  if (!isMaid)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => NewBookingPage(
                                                initialBooking: booking,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 20),
                                  const SizedBox(width: 8),
                                  Text(booking.customerInfo.name),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 20),
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
                                      child: Text(
                                          booking.customerAddress.toString())),
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
                                  const Icon(Icons.cleaning_services_outlined,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Maid: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.52,
                                    child: Text(
                                      _maidName(booking),
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                  if (!isMaid && booking.otp.isNotEmpty) ...[
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    const Text(
                                      'OTP : ',
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          booking.otp,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: booking.otp),
                                            );

                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('OTP copied'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.copy_rounded,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
            )
          : const BookingNotFoundWidget(),
    );
  }

  String _maidName(BookingModel booking) {
    final maidName = booking.maid?.name ?? '';
    if (maidName.isNotEmpty) return maidName;

    for (final slot in booking.bookingSlots) {
      final slotMaidName = slot.maidName ?? '';
      if (slotMaidName.isNotEmpty) return slotMaidName;
    }

    return 'Not Assigned';
  }
}
