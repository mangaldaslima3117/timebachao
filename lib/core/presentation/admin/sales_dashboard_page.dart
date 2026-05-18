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
  final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
  final DateFormat displayFormat = DateFormat('dd MMM yyyy');
  final now = DateTime.now();

  String get _rangeLabel {
    if (selectedRange == null) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return '${displayFormat.format(start)} – ${displayFormat.format(end)}';
    }
    return '${displayFormat.format(selectedRange!.start)} – ${displayFormat.format(selectedRange!.end)}';
  }

  @override
  void initState() {
    super.initState();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    Future.microtask(() {
      ref.read(bookingsProvider.notifier).loadBookingsWithDateRange(
            dateFormat.format(start),
            dateFormat.format(end),
          );
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      saveText: 'Done',
      confirmText: 'Done',
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: selectedRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.teal,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => selectedRange = picked);
      ref.read(bookingsProvider.notifier).loadBookingsWithDateRange(
            dateFormat.format(picked.start),
            dateFormat.format(picked.end),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(bookingsProvider.notifier);
    ref.watch(bookingsProvider); // reactively rebuild on state change

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'Sales Dashboard',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _rangeLabel,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range, size: 18, color: Colors.teal),
              label: const Text(
                'Filter',
                style: TextStyle(color: Colors.teal, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Section ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Revenue + Profit + Commission cards
                Row(
                  children: [
                    _metricCard(
                      label: 'Total Revenue',
                      value: '₹${notifier.totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.teal,
                      bgColor: Colors.teal.shade50,
                    ),
                    const SizedBox(width: 10),
                    _metricCard(
                      label: 'Profit',
                      value: '₹${notifier.totalProfit.toStringAsFixed(0)}',
                      icon: Icons.trending_up,
                      iconColor: Colors.green,
                      bgColor: Colors.green.shade50,
                      subtitle: 'After commission',
                    ),
                    const SizedBox(width: 10),
                    _metricCard(
                      label: 'Commission',
                      value: '₹${notifier.totalCommission.toStringAsFixed(0)}',
                      icon: Icons.percent,
                      iconColor: Colors.orange,
                      bgColor: Colors.orange.shade50,
                      subtitle: 'Paid to maids',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Booking stats strip
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip(
                        label: 'Total',
                        value: '${notifier.totalBookings}',
                        color: Colors.teal,
                      ),
                      _verticalDivider(),
                      _statChip(
                        label: 'Completed',
                        value: '${notifier.completedCount}',
                        color: Colors.green,
                      ),
                      _verticalDivider(),
                      _statChip(
                        label: 'Cancelled',
                        value: '${notifier.cancelledCount}',
                        color: Colors.red,
                      ),
                      _verticalDivider(),
                      _statChip(
                        label: 'Pending',
                        value:
                            '${notifier.totalBookings - notifier.completedCount - notifier.cancelledCount}',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Footnote
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Profit & commission calculated on completed bookings only.',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── List Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bookings (${notifier.filteredBookings.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Tap to view details',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // ── Booking List ────────────────────────────────────────────────
          Expanded(child: _buildBookingList(notifier.filteredBookings)),
        ],
      ),
    );
  }

  // ── Metric Card ───────────────────────────────────────────────────────────
  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        height: 90, // 👈 fixed height for all cards
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 👈 even spacing
          children: [
            Icon(icon, size: 16, color: iconColor),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis, // 👈 no wrapping on large numbers
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat Chip ─────────────────────────────────────────────────────────────
  Widget _statChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _verticalDivider() =>
      Container(height: 30, width: 1, color: Colors.grey.shade300);

  // ── Booking List ──────────────────────────────────────────────────────────
  Widget _buildBookingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing the date range',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        final statusColor = AppConstants.getStatusColor(b.serviceStatus);
        final isPaid = b.paymentInfo?.status == AppConstants.paid;
        final isCancelled = b.serviceStatus == AppConstants.cancelled;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailsPage(currentBooking: b),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status bar ────────────────────────────────────────
                  Container(
                    width: 4,
                    height: 70,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Details ───────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.customerInfo.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            // Payment badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPaid
                                        ? Icons.check_circle
                                        : Icons.access_time,
                                    size: 11,
                                    color: isPaid ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isPaid ? 'Paid' : 'Unpaid',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Status pill
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                AppConstants.getStatusText(b.serviceStatus),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            if (isCancelled) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Not counted in profit',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Date + maid
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(b.bookingDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        if (b.maid?.name != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                b.maid!.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Price ─────────────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${b.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(Icons.chevron_right,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
