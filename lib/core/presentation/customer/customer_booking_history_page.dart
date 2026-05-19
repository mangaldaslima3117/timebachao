import 'package:bookmyservice/models/customer_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../services/authentication_provider.dart';
import '../../../services/bookings_provider.dart';
import '../../utils/app_constants.dart';
import 'customer_booking_details_page.dart';

class CustomerBookingHistoryPage extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  const CustomerBookingHistoryPage({Key? key, required this.customer})
      : super(key: key);

  @override
  ConsumerState<CustomerBookingHistoryPage> createState() =>
      _CustomerBookingHistoryPageState();
}

class _CustomerBookingHistoryPageState
    extends ConsumerState<CustomerBookingHistoryPage> {
  DateTimeRange? selectedRange;
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final now = DateTime.now();

  // ── helpers ────────────────────────────────────────────────────────────────

  String get _filterLabel {
    if (selectedRange == null) return 'All bookings';
    final s = DateFormat('dd MMM').format(selectedRange!.start);
    final e = DateFormat('dd MMM').format(selectedRange!.end);
    return '$s – $e';
  }

  Future<void> _pickDateRange(BuildContext context, dynamic bookingPro) async {
    final picked = await showDateRangePicker(
      saveText: 'Done',
      confirmText: 'Done',
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: selectedRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF00897B),
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor: Color(0xFF00897B)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => selectedRange = picked);
      final start = selectedRange?.start ?? DateTime(now.year, now.month, 1);
      final end = selectedRange?.end ?? now;
      bookingPro.loadBookingsWithDateRange(
          dateFormat.format(start), dateFormat.format(end));
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingsProvider);
    final bookingPro = ref.watch(bookingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: const Color(0xFF00695C),
            surfaceTintColor: const Color(0xFF00695C),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Filter chip
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _pickDateRange(context, bookingPro),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedRange != null
                          ? Colors.white
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: selectedRange != null
                              ? const Color(0xFF00695C)
                              : Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          selectedRange != null ? _filterLabel : 'Filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selectedRange != null
                                ? const Color(0xFF00695C)
                                : Colors.white,
                          ),
                        ),
                        if (selectedRange != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() => selectedRange = null);
                              bookingPro.loadBookingsWithDateRange(
                                dateFormat.format(
                                    DateTime(now.year, now.month, 1)),
                                dateFormat.format(now),
                              );
                            },
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Color(0xFF00695C)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -10,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'My Bookings',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Track all your service bookings',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          bookingState.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00897B))),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (bookings) {
              bookings = bookings
                  .where(
                    (element) =>
                        widget.customer != null &&
                        element.customerInfo.phone.isNotEmpty &&
                        element.customerInfo.phone == widget.customer!.phone,
                  )
                  .toList();

              if (bookings.isEmpty) return const SliverFillRemaining(child: _EmptyState());

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final booking = bookings[index];
                      return _BookingCard(
                        booking: booking,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerBookingDetailsPage(
                              currentBooking: booking,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: bookings.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking Card
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final dynamic booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = booking.serviceStatus as String;
    final statusColor = AppConstants.getStatusColor(status);
    final statusText = AppConstants.getStatusText(status);
    final isPaid = booking.paymentInfo?.status == AppConstants.paid;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header strip ───────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Booking ID
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            size: 14, color: Color(0xFF00695C)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Booking #${booking.bookingId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1A2E2B),
                        ),
                      ),
                    ],
                  ),
                  // Payment badge
                  if (isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 11, color: Colors.green.shade600),
                          const SizedBox(width: 3),
                          Text(
                            'Paid',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Details ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    text: booking.customerInfo.name,
                  ),
                  const SizedBox(height: 7),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: booking.customerInfo.phone,
                  ),
                  const SizedBox(height: 7),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: booking.customerAddress.toString(),
                    expanded: true,
                  ),
                  const SizedBox(height: 7),
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    text:
                        'Booked: ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.bookingDate)}',
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                        height: 1, color: Colors.grey.shade100),
                  ),

                  // Maid row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                            Icons.cleaning_services_rounded,
                            size: 14,
                            color: Color(0xFF00695C)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Maid: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2E2B),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          booking.maid?.name.isNotEmpty == true
                              ? booking.maid!.name
                              : 'Not Assigned',
                          style: TextStyle(
                            fontSize: 13,
                            color: booking.maid?.name.isNotEmpty == true
                                ? const Color(0xFF1A2E2B)
                                : Colors.grey.shade400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Status footer ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: (statusColor as Color).withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row helper
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool expanded;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Text(
      text,
      style: const TextStyle(fontSize: 13, color: Color(0xFF3D5A57)),
      overflow: expanded ? TextOverflow.ellipsis : null,
      maxLines: expanded ? 2 : null,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF00897B)),
        const SizedBox(width: 8),
        expanded ? Expanded(child: content) : Flexible(child: content),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 44,
                color: Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Bookings Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2E2B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your service bookings will appear here once you make one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF00ACC1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00897B).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '📋  Your Bookings Will Appear Here',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}