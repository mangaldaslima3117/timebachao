import 'package:bookmyservice/core/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../services/bookings_provider.dart';
import '../../services/customer_provider.dart';
import '../../services/payment_service.dart';
import '../presentation/customer/customer_booking_details_page.dart';
import 'new_booking_blinking.dart';
import 'paypment_options_widget.dart';

// Reusing the BookingStatusCard widget from the previous example
class BookingStatusCard extends ConsumerStatefulWidget {
  const BookingStatusCard({Key? key}) : super(key: key);

  @override
  // Notice this now returns ConsumerState<BookingStatusCard>
  ConsumerState<BookingStatusCard> createState() => _BookingStatusCardState();
}

// Extend ConsumerState<T> instead of just State<T>
class _BookingStatusCardState extends ConsumerState<BookingStatusCard> {
  String? bookingNumber;
  bool isNew = false; // True if it's a new booking
  late PaymentService paymentService;
  LatLng? customerLocation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    paymentService = PaymentService(
      ref: ref,
      booking: BookingModel.getDefaultBookingModel(),
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(bookingsProvider);
    final bookingNotifier = ref.watch(bookingsProvider.notifier);

    return ref.watch(customerDataProvider).when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('Error: $err'),
          data: (customer) {
            return FutureBuilder<BookingModel?>(
              future:
                  bookingNotifier.getLatestBookingByCustomerId(customer!.phone),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Container();
                }

                final booking = snapshot.data;

                if (booking == null || booking.bookingId.isEmpty) {
                  return Container();
                }

                return Column(
                  children: [
                    const SizedBox(
                      height: 5.0,
                    ),
                    GestureDetector(
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        elevation: 4.0, // Adds a subtle shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Align text left, chip right
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Latest Booking:',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Booking #${booking.bookingId}',
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Booked on : ${DateFormat('dd-MM-yyyy HH:mm:ss').format(booking.bookingDate)}',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Only show the Chip if isNew is true
                              if (booking.serviceStatus !=
                                      AppConstants.completed &&
                                  booking.paymentInfo != null &&
                                  booking.paymentInfo!.status ==
                                      AppConstants.pending)
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  child: Center(
                                    child: BlinkingNewTag(
                                      status: AppConstants.getStatusText(
                                        booking.serviceStatus,
                                      ),
                                    ),
                                  ),
                                ),

                              if (booking.serviceStatus ==
                                      AppConstants.completed &&
                                  booking.paymentInfo != null &&
                                  booking.paymentInfo!.status ==
                                      AppConstants.pending)
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      // backgroundColor:
                                      //     Colors.teal, // Color based on status
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                        side: BorderSide(
                                          color: AppConstants.getStatusColor(
                                            booking.serviceStatus,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      //initiatePayment(ref, booking);
                                      showPaymentOptions(context,
                                          (method) async {
                                        if (method == 'cash') {
                                          // Navigate to confirmation or place order directly
                                          final confirmed =
                                              await showCashConfirmationDialog(
                                            context,
                                          );
                                          if (confirmed == true) {
                                            // User confirmed: Proceed with placing booking
                                            debugPrint(
                                                "Confirmed: Cash on Service");
                                            paymentService.initiatePayment(
                                              ref,
                                              booking,
                                              false,
                                            ); // Handle cash payment
                                          } else {
                                            // User canceled
                                            debugPrint("Cancelled");
                                          }
                                        } else if (method == 'online') {
                                          // Redirect to Razorpay
                                          paymentService.initiatePayment(
                                            ref,
                                            booking,
                                            true,
                                          ); // Handle online payment
                                        }
                                      });
                                    },
                                    child: const Text(
                                      "Pay",
                                      style: TextStyle(
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ),
                                ),
                              if (booking.serviceStatus ==
                                      AppConstants.completed &&
                                  booking.paymentInfo != null &&
                                  booking.paymentInfo!.status ==
                                      AppConstants.paid)
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  child: Center(
                                    child: Text(
                                      AppConstants.getStatusText(
                                        booking.paymentInfo?.status ??
                                            AppConstants.pending,
                                      ),
                                      style: TextStyle(
                                        color: AppConstants.getStatusColor(
                                          booking.paymentInfo!.status,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ), // Show button only if payment is pending
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
  }
}
