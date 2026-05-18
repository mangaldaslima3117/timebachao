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
      _MaidEarningsScreenState();
}

class _MaidEarningsScreenState extends ConsumerState<MaidEarningsScreen> {
  DateTimeRange? selectedRange;
  final DateFormat storageFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayFormat = DateFormat('dd MMM yyyy');
  final now = DateTime.now();

  String get _fromLabel => displayFormat
      .format(selectedRange?.start ?? DateTime(now.year, now.month, 1));

  String get _toLabel => displayFormat.format(selectedRange?.end ?? now);

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
            storageFormat.format(picked.start),
            storageFormat.format(picked.end),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(maidEarningsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Earnings',
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
      body: earningsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.teal)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$e',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (earnings) {
          if (earnings == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Date Range Banner ──────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        _fromLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '→',
                          style: TextStyle(
                              color: Colors.teal.shade300, fontSize: 14),
                        ),
                      ),
                      Text(
                        _toLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade400,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Top Metric Cards ───────────────────────────────────
                Row(
                  children: [
                    _metricCard(
                      label: 'Total Orders',
                      value: '${earnings.totalOrders}',
                      icon: Icons.receipt_long_outlined,
                      iconColor: Colors.teal,
                      bgColor: Colors.teal.shade50,
                    ),
                    const SizedBox(width: 10),
                    _metricCard(
                      label: 'Total Earnings',
                      value: '₹${earnings.totalEarnings.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.blue,
                      bgColor: Colors.blue.shade50,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _metricCard(
                      label: 'Commission',
                      value: '₹${earnings.commissionAmount.toStringAsFixed(0)}',
                      icon: Icons.percent,
                      iconColor: Colors.orange,
                      bgColor: Colors.orange.shade50,
                      subtitle:
                          '${earnings.commissionPercent.toStringAsFixed(0)}% rate',
                    ),
                    const SizedBox(width: 10),
                    _metricCard(
                      label: 'Net Pay',
                      value: '₹${earnings.netEarnings.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                      iconColor: Colors.green,
                      bgColor: Colors.green.shade50,
                      subtitle: 'After commission',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Detailed Breakdown Card ────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                size: 16,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Earnings Breakdown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade100),

                      // Rows
                      _breakdownRow(
                        label: 'Total Orders',
                        value: '${earnings.totalOrders}',
                        icon: Icons.shopping_bag_outlined,
                        iconColor: Colors.teal,
                      ),
                      _breakdownRow(
                        label: 'Total Earnings',
                        value: '₹${earnings.totalEarnings.toStringAsFixed(2)}',
                        icon: Icons.currency_rupee,
                        iconColor: Colors.blue,
                      ),
                      _breakdownRow(
                        label: 'Commission Rate',
                        value:
                            '${earnings.commissionPercent.toStringAsFixed(0)}%',
                        icon: Icons.percent,
                        iconColor: Colors.orange,
                      ),
                      _breakdownRow(
                        label: 'Commission Amount',
                        value:
                            '- ₹${earnings.commissionAmount.toStringAsFixed(2)}',
                        icon: Icons.remove_circle_outline,
                        iconColor: Colors.red,
                        valueColor: Colors.red.shade400,
                      ),

                      // Net pay highlighted row
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Net Pay',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${earnings.netEarnings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Footnote ───────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Earnings are calculated based on completed bookings in the selected date range.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Metric Card ────────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Breakdown Row ──────────────────────────────────────────────────────────
  Widget _breakdownRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
