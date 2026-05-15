import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../services/bookings_provider.dart';
import '../services/maid_earnings_provider.dart';
import '../widgets/custom_drawer.dart';

class MaidEarningsScreen extends ConsumerStatefulWidget {
  const MaidEarningsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MaidEarningsScreeneState();
}

class _MaidEarningsScreeneState extends ConsumerState<MaidEarningsScreen> {
  DateTimeRange? selectedRange;
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  DateFormat dateFormat3 = DateFormat('dd-MM-yyyy');
  DateFormat dateFormat2 = DateFormat('dd-MM-yyyy HH:mm:ss');
  final now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(maidEarningsProvider);
    final booking = ref.watch(bookingsProvider.notifier);

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text(
          "My Earnings",
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                saveText: 'Done',
                confirmText: 'Done',
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
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
              color: Colors.teal,
            ),
            //label: const Text("Filter"),
          ),
        ],
      ),
      body: earningsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (earnings) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'From ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      dateFormat3.format(selectedRange?.start ?? now),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal,
                      ),
                    ),
                    const Text(
                      ' to ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      dateFormat3.format(selectedRange?.end ?? now),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  shadowColor: Colors.teal.withOpacity(1),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRow(
                            "Total Orders", earnings!.totalOrders.toString()),
                        const SizedBox(height: 12),
                        _buildRow("Total Earnings",
                            "₹${earnings.totalEarnings.toStringAsFixed(2)}"),
                        const SizedBox(height: 12),
                        _buildRow(
                            "Current Commission (%)", "${earnings.commissionPercent}%"),
                        const SizedBox(height: 12),
                        _buildRow("Commission Amount",
                            "₹${earnings.commissionAmount.toStringAsFixed(2)}"),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildRow("Net Earnings",
                            "₹${earnings.netEarnings.toStringAsFixed(2)}",
                            isBold: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
