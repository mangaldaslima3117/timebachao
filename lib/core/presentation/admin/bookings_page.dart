import 'package:bookmyservice/core/presentation/admin/new_booking_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/bookings_provider.dart';
import '../../utils/common_function.dart';
import '../../widgets/booking_list_view.dart';

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  DateTimeRange? selectedRange;
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  DateFormat dateFormat2 = DateFormat('dd-MM-yyyy');
  final now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingsProvider);
    final bookingPro = ref.watch(bookingsProvider.notifier);
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
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
                      dateFormat2.format(start), dateFormat2.format(end));
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
          bottom: const TabBar(
            labelColor: Colors.white,
            dividerColor: Colors.white,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(
                text: "Today",
              ),
              Tab(
                text: "Upcoming",
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        body: bookingState.when(
          data: (bookings) {
            final today = DateTime(now.year, now.month, now.day);
            // Filter and sort bookings
            final todayBookings = bookings
                .where(
                    (b) => b.timeSlot.serviceDate == dateFormat2.format(today))
                .toList()
              ..sort((a, b) => DateFormat('dd-MM-yyyy')
                  .parse(a.timeSlot.serviceDate!)
                  .compareTo(
                      DateFormat('dd-MM-yyyy').parse(b.timeSlot.serviceDate!)));

            final upcomingBookings = bookings
                .where((b) =>
                    b.timeSlot.serviceDate != dateFormat2.format(today) &&
                    isFutureDate(b.timeSlot.serviceDate))
                .toList()
              ..sort((a, b) => DateFormat('dd-MM-yyyy')
                  .parse(a.timeSlot.serviceDate!)
                  .compareTo(
                      DateFormat('dd-MM-yyyy').parse(b.timeSlot.serviceDate!)));
            return bookings.isNotEmpty
                ? TabBarView(
                    children: [
                      BookingListView(bookings: todayBookings),
                      BookingListView(bookings: upcomingBookings),
                    ],
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
        floatingActionButton: SizedBox(
          height: 50,
          child: FloatingActionButton.extended(
            onPressed: () {
              // Action for new booking
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NewBookingPage(),
                ),
              );
            },
            icon: const Image(
              image: AssetImage(
                  'assets/images/bookings_icon.png'), // Replace with your icon path
              width: 24,
              height: 24,
            ),
            label: const Text(
              'New Booking',
              style: TextStyle(
                color: Colors.teal,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            //backgroundColor: Colors.teal, // Optional
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 1,
          ),
        ),
      ),
    );
  }
}
