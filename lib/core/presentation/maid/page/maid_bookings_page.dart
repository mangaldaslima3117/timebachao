import 'package:bookmyservice/core/presentation/maid/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../services/bookings_provider.dart';
import '../../../../services/notification_service.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/common_function.dart';
import '../../../widgets/booking_list_view.dart';
import '../../../widgets/booking_not_found_widget.dart';
import '../services/current_maid_provider.dart';

class MaidBookingsPage extends ConsumerStatefulWidget {
  const MaidBookingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MaidBookingsPageState();
}

class _MaidBookingsPageState extends ConsumerState<MaidBookingsPage> {
  DateTimeRange? selectedRange;
  DateFormat dateFormat = DateFormat('dd-MM-yyyy');
  DateFormat dateFormat3 = DateFormat('dd-MM-yyyy');
  final now = DateTime.now();

  @override
  void initState() {
    final currentMaid = ref.read(currentMaidProvider);
    selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    saveFCMToken(currentMaid?.id ?? '');
    super.initState();
  }

  saveFCMToken(String maidId) async {
    // Implement your FCM token saving logic here
    // This is just a placeholder function
    debugPrint("FCM Token saved MAID BOOKINGS PAGE");
    if (maidId.isNotEmpty) {
      await NotificationService.saveAndSubscribeToken(
        userId: maidId,
        collection: 'maids',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingsProvider);
    final maidDetails = ref.watch(currentMaidProvider);
    final maidIdAsync = ref.watch(maidIdProvider);
    final booking = ref.watch(bookingsProvider.notifier);

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        drawer: const CustomDrawer(),

        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white, // Change the color of the drawer icon
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.teal.shade300,
          title: ListTile(
            title: const Text(
              'Bookings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${DateFormat('dd-MM-yyyy').format(selectedRange!.start)} to ${DateFormat('dd-MM-yyyy').format(selectedRange!.end)}',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  saveText: 'Done',
                  confirmText: 'Done',
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now().add(
                    const Duration(
                      days: 30,
                    ),
                  ),
                  //initialDateRange: selectedRange,
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
          data: (maidBookings) {
            final today = DateTime(now.year, now.month, now.day);
            // final bookings = maidBookings
            //     .where((b) =>
            //         maidDetails != null && b.maidId == maidDetails.id ||
            //         b.maidId!.isEmpty)
            //     .toList();
            debugPrint(
                'Before Filtered Bookings: ${maidBookings.length} maid id : ${maidDetails?.id}');

            final maidId = maidDetails?.id ?? maidIdAsync.valueOrNull ?? '';
            if (maidId.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final bookings = maidBookings.where((b) {
              return isBookingAssignedToMaid(b, maidId);
            }).toList();

            debugPrint('Filtered Bookings: ${bookings.length}');

            final todayBookings = bookings
                .where(
                    (b) => b.timeSlot.serviceDate == dateFormat3.format(today))
                .toList()
              ..sort((a, b) => DateFormat('dd-MM-yyyy')
                  .parse(a.timeSlot.serviceDate!)
                  .compareTo(
                      DateFormat('dd-MM-yyyy').parse(b.timeSlot.serviceDate!)));

            final upcomingBookings = bookings
                .where((b) =>
                    b.serviceStatus != AppConstants.completed &&
                    b.timeSlot.serviceDate != dateFormat3.format(today) &&
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
                : const BookingNotFoundWidget();
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        // body: const TabBarView(
        //   children: [
        //     CurrentBookingsPage(),
        //     PastBookingsPage(),
        //   ],
        // ),
        // body: Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       // 🖼️ Image
        //       Container(
        //         decoration: const BoxDecoration(
        //           image: DecorationImage(
        //             image: const AssetImage(
        //               'assets/images/maid_bookings.jpg',
        //             ), // Replace with your image path
        //             fit: BoxFit.fill,
        //           ),
        //         ),
        //         width: 250,
        //         height: 250,
        //       ),

        //       const SizedBox(height: 20),

        //       // 📝 Text
        //       const Text(
        //         'Your bookings will appear here',
        //         style: TextStyle(
        //           fontSize: 20,
        //           fontWeight: FontWeight.bold,
        //           color: Colors.teal,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}
