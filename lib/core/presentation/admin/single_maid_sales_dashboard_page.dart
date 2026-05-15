import 'package:bookmyservice/core/presentation/admin/booking_details_page.dart';
import 'package:bookmyservice/models/booking_model.dart';
import 'package:bookmyservice/models/earnings_summary.dart';
import 'package:bookmyservice/models/maid_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/bookings_provider.dart';
import '../../utils/app_constants.dart';
import '../maid/services/maid_earnings_provider.dart';

class SingleMaidSalesDashboardPage extends ConsumerStatefulWidget {
  final MaidModel? maid;
  const SingleMaidSalesDashboardPage({Key? key, required this.maid})
      : super(key: key);

  @override
  ConsumerState<SingleMaidSalesDashboardPage> createState() =>
      _SingleMaidSalesDashboardPageState();
}

class _SingleMaidSalesDashboardPageState
    extends ConsumerState<SingleMaidSalesDashboardPage> {
  DateTimeRange? selectedRange;
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final booking = ref.read(bookingsProvider.notifier);
    Future.microtask(() {
      booking.loadBookingsWithDateRange(
        dateFormat.format(start),
        dateFormat.format(end),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.read(bookingsProvider.notifier);
    //final earningsAsync = ref.watch(maidEarningsProvider);
    List<BookingModel> maidBookings =
        ref.watch(bookingByMaidIdProvider(widget.maid!.id))!;
    final earningSummary = ref.watch(maidEarningsByIdProvider(
      widget.maid!,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.maid!.name,
          style: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(color: Colors.teal.shade100, width: 1),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                saveText: 'Done',
                confirmText: 'Done',
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
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

                booking.loadBookingsWithDateRange(
                    dateFormat.format(start), dateFormat.format(end));
              }
            },
            icon: const Icon(
              Icons.filter_alt,
              size: 20,
              color: Colors.teal,
            ),
            //label: const Text("Filter"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            earningSummary.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (earnings) {
                  return _buildSalesSummary(
                    earnings!.totalEarnings,
                    earnings.totalOrders,
                    earnings.completedCount,
                    earnings.cancelledCount,
                    earnings,
                  );
                }),

            // Text("Total Bookings: ${notifier.totalBookings}"),
            // Text("Completed: ${notifier.completedCount}"),
            // Text("Cancelled: ${notifier.cancelledCount}"),

            // Add ListView or charts here...
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bookings Assigned to ${widget.maid!.name}',
                  style: const TextStyle(),
                ),
              ),
            ),
            Expanded(
              child: _buildBookingList(
                maidBookings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesSummary(
    double sales,
    int total,
    int completed,
    int cancelled,
    EarningsSummary earnings,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // _summaryTile("Total Earning", "₹${sales.toStringAsFixed(0)}",
                //     icon: Icons.currency_rupee),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: _summaryTails(
                    "Total",
                    "₹${earnings.totalEarnings.toStringAsFixed(0)}",
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: _summaryTails(
                    "Comission",
                    "₹${earnings.commissionAmount.toStringAsFixed(0)}",
                    color: Colors.red,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.25,
                  child: _summaryTails(
                    "Pay",
                    "₹${earnings.netEarnings.toStringAsFixed(0)}",
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // _summaryTile("Total Earning", "₹${sales.toStringAsFixed(0)}",
                //     icon: Icons.currency_rupee),
                _summaryTile("Total Bookings", "$total", icon: Icons.book_online),
                _summaryTile("Completed", "$completed",
                    icon: Icons.check_circle_outline),
                _summaryTile(
                  "Cancelled",
                  "$cancelled",
                  icon: Icons.cancel_outlined,
                  
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            const Text(
              'comission are calculated for assigned maid for a booking.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String title, String value,
      {IconData icon = Icons.info, Color? color = Colors.black}) {
    return Column(
      children: [
        //Icon(icon, size: 28, color: color ?? Colors.teal),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _summaryTails(String title, String value,
      {Color? color = Colors.black}) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🖼️ Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
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
    }
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailsPage(
                  currentBooking: b,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                backgroundBlendMode: BlendMode.overlay,
                border: Border.all(
                  color: Colors.teal.shade50,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                //leading: const Icon(Icons.cleaning_services),
                title: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    b.customerInfo.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                subtitle: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          "Status: ",
                        ),
                        Text(
                          " ${AppConstants.getStatusText(b.serviceStatus)}",
                          style: TextStyle(
                            color: AppConstants.getStatusColor(b.serviceStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Date: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(b.bookingDate)}",
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Chip(
                  side: BorderSide(
                    color: Colors.teal.shade50,
                    width: 1,
                  ),
                  label: Text(
                    "₹${b.totalPrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
