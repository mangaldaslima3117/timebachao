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
    final maidBookings =
        ref.watch(bookingByMaidIdProvider(widget.maid!.id)) ?? [];
    final earningSummary =
        ref.watch(maidEarningsByIdProvider(widget.maid!));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text(
              widget.maid!.name,
              style: const TextStyle(
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.teal, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: earningSummary.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.teal)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.red)),
        ),
        data: (earnings) => _buildBody(earnings!, maidBookings),
      ),
    );
  }

  Widget _buildBody(EarningsSummary earnings, List<BookingModel> bookings) {
    return Column(
      children: [
        // ── Summary Section ───────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Earnings row
              Row(
                children: [
                  _earningCard(
                    label: 'Total Earnings',
                    value: '₹${earnings.totalEarnings.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: Colors.teal,
                    bgColor: Colors.teal.shade50,
                  ),
                  const SizedBox(width: 10),
                  _earningCard(
                    label: 'Commission',
                    value:
                        '₹${earnings.commissionAmount.toStringAsFixed(0)}',
                    icon: Icons.percent,
                    iconColor: Colors.orange,
                    bgColor: Colors.orange.shade50,
                    subtitle:
                        '${earnings.commissionPercent.toStringAsFixed(0)}% rate',
                  ),
                  const SizedBox(width: 10),
                  _earningCard(
                    label: 'Net Pay',
                    value: '₹${earnings.netEarnings.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                    iconColor: Colors.green,
                    bgColor: Colors.green.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Booking stats row
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 8),
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
                      value: '${earnings.totalOrders}',
                      color: Colors.teal,
                    ),
                    _verticalDivider(),
                    _statChip(
                      label: 'Completed',
                      value: '${earnings.completedCount}',
                      color: Colors.green,
                    ),
                    _verticalDivider(),
                    _statChip(
                      label: 'Cancelled',
                      value: '${earnings.cancelledCount}',
                      color: Colors.red,
                    ),
                    _verticalDivider(),
                    _statChip(
                      label: 'Pending',
                      value:
                          '${earnings.totalOrders - earnings.completedCount - earnings.cancelledCount}',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Commission calculated on bookings assigned to this maid.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Booking List Header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bookings (${bookings.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Tap to view details',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),

        // ── Booking List ──────────────────────────────────────────────────
        Expanded(child: _buildBookingList(bookings)),
      ],
    );
  }

  // ── Earning Card ──────────────────────────────────────────────────────────
  Widget _earningCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade600),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade500),
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
          style:
              TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
        height: 30, width: 1, color: Colors.grey.shade300);
  }

  // ── Booking List ──────────────────────────────────────────────────────────
  Widget _buildBookingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
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
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade400),
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
        final commissionPct = _commissionPercentageForBooking(b);
        final commissionAmt = _commissionAmountForBooking(b);
        final statusColor = AppConstants.getStatusColor(b.serviceStatus);
        final isCancelled =
            b.serviceStatus == AppConstants.cancelled;

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
                  // ── Left: status indicator bar ──────────────────────
                  Container(
                    width: 4,
                    height: 70,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Middle: details ─────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.customerInfo.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                                AppConstants.getStatusText(
                                    b.serviceStatus),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade400),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.percent,
                                size: 12,
                                color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              isCancelled
                                  ? 'No commission (cancelled)'
                                  : 'Commission: ${commissionPct.toStringAsFixed(0)}% = ₹${commissionAmt.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isCancelled
                                    ? Colors.red.shade300
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Right: total price ──────────────────────────────
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

  double _commissionPercentageForBooking(BookingModel booking) {
    final bookingMaidPct = booking.maid?.commissionPercentage ?? 0;
    if (bookingMaidPct > 0) return bookingMaidPct;
    if (booking.commissionPercentage > 0) {
      return booking.commissionPercentage.toDouble();
    }
    return widget.maid?.commissionPercentage ?? 0;
  }

  double _commissionAmountForBooking(BookingModel booking) {
    if (booking.serviceStatus == AppConstants.cancelled) return 0;
    return booking.totalPrice *
        (_commissionPercentageForBooking(booking) / 100);
  }
}