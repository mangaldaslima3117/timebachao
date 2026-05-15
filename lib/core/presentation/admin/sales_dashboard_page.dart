import 'package:bookmyservice/core/presentation/admin/booking_details_page.dart';
import 'package:bookmyservice/models/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/bookings_provider.dart';
import '../../utils/app_constants.dart';

class SalesDashboardPage extends ConsumerStatefulWidget {
  const SalesDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends ConsumerState<SalesDashboardPage> {
  DateTimeRange? selectedRange;
  DateFormat dateFormat = DateFormat('dd-MM-yyyy');
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
    final bookingState =
        ref.watch(bookingsProvider); // ✅ watches the state (AsyncValue<List>)
    final booking = ref.read(bookingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sales Dashboard",
          style: TextStyle(
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
            _buildSalesSummary(
              booking.totalRevenue,
              booking.totalBookings,
              booking.completedCount,
              booking.cancelledCount,
              notifier: booking,
            ),
            // Text("Total Bookings: ${notifier.totalBookings}"),
            // Text("Completed: ${notifier.completedCount}"),
            // Text("Cancelled: ${notifier.cancelledCount}"),

            // Add ListView or charts here...
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Bookings',
                  style: TextStyle(),
                ),
              ),
            ),
            Expanded(
              child: _buildBookingList(
                booking.filteredBookings,
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
    int cancelled, {
    required BookingsNotifier notifier,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryTile("Total Revenue", "₹${sales.toStringAsFixed(0)}",
                    icon: Icons.currency_rupee),
                _summaryTile("Bookings", "$total", icon: Icons.book_online),
                _summaryTile("Completed", "$completed",
                    icon: Icons.check_circle_outline),
                _summaryTile(
                  "Cancelled",
                  "$cancelled",
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: _summaryTails(
                    "Profit",
                    "₹${notifier.totalProfit.toStringAsFixed(2)}",
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: _summaryTails(
                    "Total Comission",
                    "₹${notifier.totalCommission.toStringAsFixed(2)}",
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            const Text(
              'Profit and comission are calculated on completed bookings only.',
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
      {IconData icon = Icons.info, Color? color = Colors.teal}) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color ?? Colors.teal),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                leading: const Icon(Icons.cleaning_services),
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
                  children: [
                    Row(
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
                    Text(
                      "Date: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(b.bookingDate)}",
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
                  avatar: b.paymentInfo!.status == AppConstants.paid
                      ? const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 16, // small tick
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
