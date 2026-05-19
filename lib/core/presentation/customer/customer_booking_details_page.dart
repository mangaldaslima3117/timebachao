import 'package:bookmyservice/services/shared_preference_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/booking_model.dart';
import '../../../models/maid_model.dart';
import '../../../services/bookings_provider.dart';
import '../../../services/maids_provider.dart';
import '../../../services/payment_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/common_function.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dynamic_calendar.dart';
import '../../widgets/live_tracking_map.dart';
import '../../widgets/paypment_options_widget.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _T {
  // Teal
  static const teal = Color(0xFF1D9E75);
  static const tealDark = Color(0xFF0F6E56);
  static const tealDeep = Color(0xFF085041);
  static const tealBg = Color(0xFFE1F5EE);
  static const tealBorder = Color(0xFF9FE1CB);
  // Indigo
  static const indigo = Color(0xFF534AB7);
  static const indigoBg = Color(0xFFEEEDFE);
  // Orange
  static const orange = Color(0xFF854F0B);
  static const orangeBg = Color(0xFFFAEEDA);
  static const orangeBorder = Color(0xFFFAC775);
  // Green
  static const green = Color(0xFF3B6D11);
  static const greenBg = Color(0xFFEAF3DE);
  static const greenBorder = Color(0xFFC0DD97);
  // Red
  static const red = Color(0xFFA32D2D);
  static const redBg = Color(0xFFFCEBEB);
  static const redBorder = Color(0xFFF7C1C1);
  // Neutrals
  static const pageBg = Color(0xFFF0F2F5);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);

  // Status helpers
  static Color badgeBg(String s) {
    switch (_norm(s)) {
      case 'confirmed':
      case 'accepted':
      case '2':
        return tealBg;
      case 'paid':
      case 'completed':
      case '3':
        return greenBg;
      case 'cancelled':
      case '5':
        return redBg;
      case 'inprogress':
      case 'in progress':
      case '4':
        return const Color(0xFFDBEAFE);
      default:
        return orangeBg;
    }
  }

  static Color badgeText(String s) {
    switch (_norm(s)) {
      case 'confirmed':
      case 'accepted':
      case '2':
        return tealDark;
      case 'paid':
      case 'completed':
      case '3':
        return green;
      case 'cancelled':
      case '5':
        return red;
      case 'inprogress':
      case 'in progress':
      case '4':
        return const Color(0xFF1D4ED8);
      default:
        return orange;
    }
  }

  static Color badgeBorder(String s) {
    switch (_norm(s)) {
      case 'confirmed':
      case 'accepted':
      case '2':
        return tealBorder;
      case 'paid':
      case 'completed':
      case '3':
        return greenBorder;
      case 'cancelled':
      case '5':
        return redBorder;
      case 'inprogress':
      case 'in progress':
      case '4':
        return const Color(0xFF93C5FD);
      default:
        return orangeBorder;
    }
  }

  static String _norm(String s) => s.toLowerCase().trim();
}
// ─────────────────────────────────────────────────────────────────────────────

class CustomerBookingDetailsPage extends ConsumerStatefulWidget {
  final BookingModel currentBooking;
  const CustomerBookingDetailsPage({super.key, required this.currentBooking});

  @override
  ConsumerState<CustomerBookingDetailsPage> createState() =>
      _CustomerBookingDetailsPageState();
}

class _CustomerBookingDetailsPageState
    extends ConsumerState<CustomerBookingDetailsPage> {
  String result = "";
  bool isPaymentDone = false;
  late PaymentService paymentService;
  LatLng? customerLocation;

  @override
  void initState() {
    super.initState();
    paymentService = PaymentService(
      ref: ref,
      booking: widget.currentBooking,
      context: context,
    );
    _fetchDestination();
  }

  @override
  void dispose() {
    paymentService.dispose(); // Dispose Razorpay instance
    super.dispose();
  }

  // ── Location (original logic preserved) ────────────────────────────────────
  void _fetchDestination() async {
    final latLang = await getLatLngFromAddress(
        widget.currentBooking.customerAddress.toString());
    if (latLang != null) {
      debugPrint('CUSTOMERS CURRENT LOCATION ${latLang.toJson()}');
      setState(() => customerLocation = latLang);
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  // ── Payment (original logic preserved) ─────────────────────────────────────
  void initiatePayment(WidgetRef ref, BookingModel booking) {
    paymentService = PaymentService(
      ref: ref,
      booking: booking,
      context: context,
    );
    paymentService.razorPayAndPlaceOrder(booking);
  }

  // ── Unassign maid (original logic preserved) ───────────────────────────────
  void _unassignMaid(WidgetRef ref, BuildContext context,
      BookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unassign Maid',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _T.textPrimary),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to unassign the maid?',
                style: TextStyle(
                    fontSize: 13, color: _T.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: _PillBtn(
                    label: 'Cancel',
                    bg: const Color(0xFFF3F4F6),
                    fg: _T.textSecondary,
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PillBtn(
                    label: 'Unassign',
                    bg: _T.red,
                    fg: Colors.white,
                    onTap: () async {
                      await ref
                          .read(maidAccountProvider.notifier)
                          .updateMaidAvailability(booking.maidId!, true);
                      booking.maidId = "";
                      booking.maid = MaidModel.getDefaultMaid();
                      await ref
                          .read(bookingsProvider.notifier)
                          .assignMaid(booking);
                      Navigator.pop(ctx, true);
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: error ? _T.red : _T.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(14),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final BookingModel booking =
        ref.watch(bookingByIdProvider(widget.currentBooking.bookingId))!;
    final userRole = ref.watch(roleProvider);
    final isAdmin = userRole?.roleType == AppConstants.admin_role;

    final totalPrice = booking.services.fold<double>(
      0.0,
      (sum, service) => sum + service.finalPrice,
    );
    final dayCount =
        booking.bookingSlots.isNotEmpty ? booking.bookingSlots.length : 1;

    return Scaffold(
      backgroundColor: _T.pageBg,
      appBar: _buildAppBar(booking),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Column(
          children: [
            // ── Live tracking map (customer-specific, shown when accepted) ──
            if (booking.serviceStatus == AppConstants.accepted &&
                customerLocation != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: LiveTrackingMap(
                  bookingId: booking.bookingId,
                  destination: customerLocation!,
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Meta strip ──────────────────────────────────────────────────
            _MetaStrip(
                booking: booking,
                totalPrice: totalPrice,
                dayCount: dayCount),
            const SizedBox(height: 14),

            // ── Customer card ───────────────────────────────────────────────
            _customerCard(booking),
            const SizedBox(height: 14),

            // ── Time slot card ──────────────────────────────────────────────
            _timeSlotCard(booking),
            const SizedBox(height: 14),

            // ── Services card ───────────────────────────────────────────────
            _servicesCard(booking, totalPrice, dayCount),
            const SizedBox(height: 14),

            // ── Maid card (shown when maid is assigned) ─────────────────────
            if (booking.maid != null) ...[
              _maidCard(booking, isAdmin),
              const SizedBox(height: 14),
            ],

            // ── Booking info card ───────────────────────────────────────────
            _bookingInfoCard(booking),
            const SizedBox(height: 14),

            // ── Payment card ────────────────────────────────────────────────
            _paymentCard(booking, totalPrice),
            const SizedBox(height: 14),

            // ── Proceed to payment button (customer-specific) ───────────────
            if (booking.serviceStatus == AppConstants.completed &&
                booking.paymentInfo!.status == AppConstants.pending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.payment_rounded, size: 20),
                  label: const Text(
                    'Proceed to Payment',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  onPressed: () {
                    showPaymentOptions(context, (method) async {
                      if (method == 'cash') {
                        final confirmed =
                            await showCashConfirmationDialog(context);
                        if (confirmed == true) {
                          debugPrint("Confirmed: Cash on Service");
                          paymentService.initiatePayment(ref, booking, false);
                        } else {
                          debugPrint("Cancelled");
                        }
                      } else if (method == 'online') {
                        paymentService.initiatePayment(ref, booking, true);
                      }
                    });
                  },
                ),
              ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(BookingModel booking) => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _T.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(children: [
          const Text(
            'Booking Details',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w500, color: _T.teal),
          ),
          Text(
            '#${booking.bookingId}',
            style:
                const TextStyle(fontSize: 11, color: _T.textSecondary),
          ),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _T.divider),
        ),
        // No action menu for customer — customers cannot change booking status
      );

  // ── Customer card ───────────────────────────────────────────────────────────
  Widget _customerCard(BookingModel b) => _Card(
        iconBg: _T.tealBg,
        iconColor: _T.teal,
        icon: Icons.person_outline_rounded,
        title: 'Customer Information',
        child: Column(children: [
          _InfoRow(label: 'Name', value: b.customerInfo.name),
          const _HDivider(),
          _InfoRow(
            label: 'Phone',
            child: Text(
              '+91 ${b.customerInfo.phone}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _T.teal),
            ),
          ),
          const _HDivider(),
          _InfoRow(label: 'Address', value: b.customerAddress.toString()),
        ]),
      );

  // ── Time slot card ──────────────────────────────────────────────────────────
  Widget _timeSlotCard(BookingModel b) {
    final slots = b.bookingSlots.isNotEmpty ? b.bookingSlots : [b.timeSlot];
    return _Card(
      iconBg: _T.tealBg,
      iconColor: _T.teal,
      icon: Icons.calendar_today_rounded,
      title: 'Date & Time',
      child: Column(
        children: slots
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _SlotChip(
                    date: s.serviceDate ?? '',
                    time: '${s.startTime} – ${s.endTime}',
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Services card ───────────────────────────────────────────────────────────
  Widget _servicesCard(BookingModel b, double totalPrice, int days) => _Card(
        iconBg: _T.tealBg,
        iconColor: _T.teal,
        icon: Icons.auto_awesome_rounded,
        title: 'Services',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...b.services.asMap().entries.map((en) {
              final svc = en.value;
              final disc = svc.hasDiscount
                  ? (((svc.mrpPrice - svc.finalPrice) / svc.mrpPrice) * 100)
                      .round()
                  : 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (en.key > 0) ...[
                    const _HDivider(),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _T.tealBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            size: 16, color: _T.teal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              svc.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _T.textPrimary),
                            ),
                            if (svc.categoryName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                svc.categoryName,
                                style: const TextStyle(
                                    fontSize: 12, color: _T.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (svc.hasDiscount)
                            Text(
                              '₹${svc.mrpPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _T.textSecondary,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          Text(
                            '₹${(svc.hasDiscount ? svc.finalPrice : svc.mrpPrice).toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _T.teal),
                          ),
                          if (disc > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: _T.greenBg,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                '$disc% off',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: _T.green),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }),
            const _HDivider(),
            const SizedBox(height: 10),
            _SumRow(
                label: 'Subtotal',
                value: '₹${totalPrice.toStringAsFixed(0)}'),
            if (days > 1) ...[
              const SizedBox(height: 4),
              _SumRow(
                  label: '× $days days',
                  value: '₹${(totalPrice * days).toStringAsFixed(0)}'),
            ],
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: _T.tealBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _T.teal),
                  ),
                  Text(
                    '₹${(totalPrice * days).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _T.tealDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Maid card ───────────────────────────────────────────────────────────────
  // Preserves: maid profile image, admin-only assign/unassign/change actions
  Widget _maidCard(BookingModel b, bool isAdmin) {
    final hasMaid = b.maid != null && b.maidId!.isNotEmpty;
    final done = b.serviceStatus == AppConstants.completed;

    return _Card(
      iconBg: _T.indigoBg,
      iconColor: _T.indigo,
      icon: Icons.badge_outlined,
      title: 'Assigned Maid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMaid) ...[
            Row(children: [
              // Preserves original profile image logic
              b.maid!.profilePictureUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          NetworkImage(b.maid!.profilePictureUrl!),
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor: _T.indigoBg,
                      child: Text(
                        b.maid!.name.isNotEmpty
                            ? b.maid!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: _T.indigo),
                      ),
                    ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.maid!.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _T.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mobile: ${b.maid!.phone}',
                    style: const TextStyle(
                        fontSize: 13, color: _T.textSecondary),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 8),
            const _HDivider(),
            _InfoRow(
              label: 'Assigned On',
              value: b.assignedTime?.isNotEmpty == true
                  ? b.assignedTime!
                  : '—',
            ),
            const _HDivider(),
            _InfoRow(
              label: 'Assigned By',
              value: b.assignedBy?.isNotEmpty == true ? b.assignedBy! : '—',
            ),
          ] else
            const _InfoRow(label: 'Maid', value: 'Not assigned'),

          // Admin-only maid management actions (preserved from original)
          if (isAdmin && !done) ...[
            const SizedBox(height: 4),
            const _HDivider(),
            const SizedBox(height: 10),
            Row(children: [
              if (hasMaid) ...[
                _RedBtn(
                  icon: Icons.person_remove_outlined,
                  label: 'Unassign',
                  onTap: () => _unassignMaid(ref, context, b),
                ),
                const SizedBox(width: 10),
              ],
              _TealBtn(
                icon: Icons.swap_horiz_rounded,
                label: hasMaid ? 'Change Maid' : 'Assign Maid',
                onTap: () => showMaidSelectionSheet(context, ref, b),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Booking info card ───────────────────────────────────────────────────────
  // Preserves: DynamicCalendarIcon, OTP visibility logic (not verified + not
  // completed/cancelled), original customer-visible fields
  Widget _bookingInfoCard(BookingModel b) => _Card(
        iconBg: _T.orangeBg,
        iconColor: _T.orange,
        // DynamicCalendarIcon replaces the generic icon in the header
        icon: Icons.receipt_long_rounded,
        title: 'Booking Info',
        customHeader: Row(children: [
          DynamicCalendarIcon(bookedOn: b.bookedOn!),
          const SizedBox(width: 10),
          const Text(
            'Booking Info',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _T.textPrimary),
          ),
        ]),
        child: Column(children: [
          _InfoRow(
            label: 'Status',
            child: _Badge(status: b.serviceStatus),
          ),
          const _HDivider(),
          _InfoRow(
            label: 'Booking ID',
            child: Text(
              '#${b.bookingId}',
              style:
                  const TextStyle(fontSize: 12, color: _T.textSecondary),
            ),
          ),
          if (b.parentBookingId.isNotEmpty) ...[
            const _HDivider(),
            _InfoRow(label: 'Parent Booking', value: b.parentBookingId),
          ],
          // OTP: shown only while unverified and booking not completed/cancelled
          if (b.otp.isNotEmpty &&
              b.otpVerifiedTime.isEmpty &&
              b.serviceStatus != AppConstants.completed &&
              b.serviceStatus != AppConstants.cancelled) ...[
            const _HDivider(),
            _InfoRow(
              label: 'Start OTP',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _T.orangeBg,
                  border:
                      Border.all(color: _T.orangeBorder, width: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  b.otp,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: _T.orange,
                  ),
                ),
              ),
            ),
          ],
          const _HDivider(),
          _InfoRow(
            label: 'Booked On',
            value: DateFormat('dd MMM yyyy, hh:mm a').format(b.bookingDate),
          ),
          const _HDivider(),
          _InfoRow(label: 'Booked By', value: b.bookedBy),
          if (b.serviceStatus == AppConstants.completed) ...[
            const _HDivider(),
            _InfoRow(label: 'Completed On', value: b.serviceCompletedTime),
            if (b.assignedTime!.isNotEmpty &&
                b.serviceCompletedTime.isNotEmpty) ...[
              const _HDivider(),
              _InfoRow(
                label: 'Service Time',
                value: AppConstants.getTimeDifference(
                    b.assignedTime!, b.serviceCompletedTime),
              ),
            ],
          ],
        ]),
      );

  // ── Payment card ────────────────────────────────────────────────────────────
  // Preserves: original payment fields (amount, method, paymentId, time)
  Widget _paymentCard(BookingModel b, double totalPrice) {
    final isPaid = b.paymentInfo!.status == AppConstants.paid;
    return _Card(
      iconBg: _T.greenBg,
      iconColor: _T.green,
      icon: Icons.credit_card_rounded,
      title: 'Payment',
      child: Column(children: [
        _InfoRow(
          label: 'Status',
          child: _Badge(status: b.paymentInfo!.status),
        ),
        if (b.paymentInfo!.amount > 0) ...[
          const _HDivider(),
          _InfoRow(
            label: 'Amount',
            value:
                '₹ ${b.paymentInfo!.amount.toStringAsFixed(2)}',
          ),
        ],
        if (b.paymentInfo!.method.isNotEmpty) ...[
          const _HDivider(),
          _InfoRow(label: 'Method', value: b.paymentInfo!.method),
        ],
        if (b.paymentInfo!.method == AppConstants.PAYMENT_ONLINE) ...[
          const _HDivider(),
          _InfoRow(
            label: 'Payment ID',
            child: Text(
              b.paymentInfo!.paymentId.isNotEmpty
                  ? b.paymentInfo!.paymentId
                  : '—',
              style:
                  const TextStyle(fontSize: 13, color: _T.textSecondary),
            ),
          ),
        ],
        const _HDivider(),
        _InfoRow(
          label: 'Payment Time',
          value: DateFormat('dd MMM yyyy, hh:mm a')
              .format(b.paymentInfo!.createdAt),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable Design Widgets (matching BookingDetailsPage style)
// ══════════════════════════════════════════════════════════════════════════════

/// Card shell — supports an optional [customHeader] to replace the default
/// icon + title row (used for DynamicCalendarIcon in booking info card)
class _Card extends StatelessWidget {
  final Color iconBg, iconColor;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? customHeader;

  const _Card({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.child,
    this.customHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
            child: customHeader ??
                Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 17, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _T.textPrimary),
                  ),
                ]),
          ),
          Container(height: 0.5, color: _T.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Label + value row
class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _InfoRow({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: _T.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: child ??
                Text(
                  value ?? '',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _T.textPrimary),
                ),
          ),
        ],
      ),
    );
  }
}

class _HDivider extends StatelessWidget {
  const _HDivider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: _T.divider);
}

/// Teal date/time chip
class _SlotChip extends StatelessWidget {
  final String date, time;
  const _SlotChip({required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: _T.tealBg,
          border: Border.all(color: _T.tealBorder, width: 0.5),
          borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: _T.tealDeep),
            const SizedBox(width: 6),
            Text(date,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _T.tealDeep)),
          ]),
          Row(children: [
            const Icon(Icons.access_time_rounded,
                size: 14, color: _T.tealDeep),
            const SizedBox(width: 6),
            Text(time,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _T.tealDeep)),
          ]),
        ],
      ),
    );
  }
}

/// Status badge pill
class _Badge extends StatelessWidget {
  final String status;
  const _Badge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = AppConstants.getStatusText(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: _T.badgeBg(status),
          border: Border.all(color: _T.badgeBorder(status), width: 0.5),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _T.badgeText(status)),
      ),
    );
  }
}

/// Meta strip: Status | Total | Days
class _MetaStrip extends StatelessWidget {
  final BookingModel booking;
  final double totalPrice;
  final int dayCount;
  const _MetaStrip(
      {required this.booking,
      required this.totalPrice,
      required this.dayCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.divider, width: 0.5)),
      child: Row(children: [
        // Status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status',
                  style: TextStyle(fontSize: 11, color: _T.textSecondary)),
              const SizedBox(height: 4),
              _Badge(status: booking.serviceStatus),
            ],
          ),
        ),
        // Total
        Expanded(
          child: Column(
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 11, color: _T.textSecondary)),
              const SizedBox(height: 4),
              Text(
                '₹${(totalPrice * dayCount).toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: _T.teal),
              ),
            ],
          ),
        ),
        // Days
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Days',
                  style: TextStyle(fontSize: 11, color: _T.textSecondary)),
              const SizedBox(height: 4),
              Text(
                '$dayCount ${dayCount == 1 ? 'day' : 'days'}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _T.textPrimary),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Price summary row
class _SumRow extends StatelessWidget {
  final String label, value;
  const _SumRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: _T.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, color: _T.textSecondary)),
        ],
      );
}

/// Teal pill button
class _TealBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _TealBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              color: _T.tealBg,
              border: Border.all(color: _T.tealBorder, width: 0.5),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: _T.tealDark),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _T.tealDark)),
          ]),
        ),
      );
}

/// Red pill button
class _RedBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _RedBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              color: _T.redBg,
              border: Border.all(color: _T.redBorder, width: 0.5),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: _T.red),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _T.red)),
          ]),
        ),
      );
}

/// Generic pill button (dialogs)
class _PillBtn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  const _PillBtn(
      {required this.label,
      required this.bg,
      required this.fg,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: fg, fontSize: 14),
            ),
          ),
        ),
      );
}