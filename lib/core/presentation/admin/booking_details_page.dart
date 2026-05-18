import 'package:bookmyservice/services/shared_preference_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/booking_model.dart';
import '../../../models/maid_model.dart';
import '../../../services/bookings_provider.dart';
import '../../../services/maids_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';
import '../maid/services/current_maid_provider.dart';

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

class BookingDetailsPage extends ConsumerStatefulWidget {
  final BookingModel currentBooking;
  const BookingDetailsPage({super.key, required this.currentBooking});

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingDetailsPage> {
  LatLng? targetLocation;

  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddress();
  }

  Future<void> _getCoordinatesFromAddress() async {
    try {
      final locs = await locationFromAddress(
          widget.currentBooking.customerAddress.toString());
      if (locs.isNotEmpty && mounted) {
        setState(() =>
            targetLocation = LatLng(locs.first.latitude, locs.first.longitude));
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  Future<void> _openDirections(LatLng dest) async {
    final pos = await _currentPosition();
    if (pos == null) return;
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${pos.latitude},${pos.longitude}'
        '&destination=${dest.latitude},${dest.longitude}&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<Position?> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // ── Status handler ──────────────────────────────────────────────────────────

  Future<void> _handleStatusChange(
    BookingModel booking,
    String value,
    double totalPrice,
    dynamic userRole,
  ) async {
    final statusText = AppConstants.getStatusText(value);
    final confirmed = await _confirmDialog(
      title: 'Update Status',
      body: 'Mark this booking as "$statusText"?',
      confirmLabel: 'Confirm',
      confirmColor: _T.teal,
    );

    if (userRole?.roleType == AppConstants.maid_role &&
        value == AppConstants.accepted) {
      final maid = ref.read(currentMaidProvider);
      booking.maid = maid;
      booking.assignedBy = 'Self';
      booking.maidId = maid!.id;
    }

    if (confirmed != true) return;

    if (value == AppConstants.inProgress && booking.maidId!.isEmpty) {
      _snack('Please assign a maid before marking In Progress.', error: true);
      return;
    }

    if (value == AppConstants.inProgress) {
      final verified = await _verifyStartOtp(booking);
      if (!verified) return;
    }

    booking.assignedTime = booking.assignedTime!.isNotEmpty
        ? booking.assignedTime
        : (value == AppConstants.inProgress
            ? DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())
            : '');
    booking.serviceCompletedTime = value == AppConstants.completed
        ? DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())
        : '';
    booking.otpVerifiedTime = value == AppConstants.inProgress
        ? DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())
        : booking.otpVerifiedTime;

    if (value == AppConstants.completed || value == AppConstants.cancelled) {
      ref
          .read(maidAccountProvider.notifier)
          .updateMaidAvailability(booking.maidId!, true);
    }

    if (value == AppConstants.paid) {
      final online = await showPaymentConfirmationDialog(context);
      booking.paymentInfo!
        ..amount = totalPrice
        ..createdAt = DateTime.now()
        ..status = AppConstants.paid
        ..method = online ? 'Online' : 'Cash';
      ref
          .read(bookingsProvider.notifier)
          .updatePaymentInfo(booking, booking.serviceStatus);
    } else {
      ref.read(bookingsProvider.notifier).updateBookingStatus(booking, value);
    }
    _snack('Booking marked as $statusText');
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) =>
      showDialog<bool>(
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _T.textPrimary)),
                const SizedBox(height: 10),
                Text(body,
                    style: const TextStyle(
                        fontSize: 13, color: _T.textSecondary, height: 1.5)),
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
                      label: confirmLabel,
                      bg: confirmColor,
                      fg: Colors.white,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );

  Future<bool> _verifyStartOtp(BookingModel booking) async {
    if (booking.otp.isEmpty) {
      _snack('Start OTP is not available for this booking.', error: true);
      return false;
    }

    String otpInput = '';
    final verified = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Start OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _T.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter the OTP shared by the customer to start this work.',
                style: TextStyle(
                  fontSize: 13,
                  color: _T.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => otpInput = value.trim(),
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                    label: 'Verify',
                    bg: _T.teal,
                    fg: Colors.white,
                    onTap: () {
                      if (otpInput == booking.otp) {
                        Navigator.pop(ctx, true);
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid OTP'),
                            backgroundColor: _T.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    return verified == true;
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

  Future<void> _unassignMaid(BookingModel booking) async {
    final ok = await _confirmDialog(
      title: 'Unassign Maid',
      body: 'Are you sure you want to unassign the maid?',
      confirmLabel: 'Unassign',
      confirmColor: _T.red,
    );
    if (ok != true) return;
    await ref
        .read(maidAccountProvider.notifier)
        .updateMaidAvailability(booking.maidId!, true);
    booking.maidId = '';
    booking.maid = MaidModel.getDefaultMaid();
    await ref.read(bookingsProvider.notifier).assignMaid(booking);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final booking =
        ref.watch(bookingByIdProvider(widget.currentBooking.bookingId))!;
    final userRole = ref.watch(roleProvider);
    final isAdmin = userRole?.roleType == AppConstants.admin_role;

    final totalPrice =
        booking.services.fold<double>(0.0, (s, e) => s + e.finalPrice);
    final dayCount =
        booking.bookingSlots.isNotEmpty ? booking.bookingSlots.length : 1;

    return Scaffold(
      backgroundColor: _T.pageBg,
      appBar: _appBar(booking, totalPrice, userRole),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Column(
          children: [
            _MetaStrip(
                booking: booking, totalPrice: totalPrice, dayCount: dayCount),
            const SizedBox(height: 14),
            _customerCard(booking),
            const SizedBox(height: 14),
            _timeSlotCard(booking),
            const SizedBox(height: 14),
            _servicesCard(booking, totalPrice, dayCount),
            const SizedBox(height: 14),
            _maidCard(booking, isAdmin),
            const SizedBox(height: 14),
            _bookingInfoCard(booking, isAdmin),
            const SizedBox(height: 14),
            _paymentCard(booking, totalPrice),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  AppBar _appBar(BookingModel booking, double totalPrice, dynamic userRole) =>
      AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _T.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(children: [
          const Text('Booking Details',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w500, color: _T.teal)),
          Text('#${booking.bookingId}',
              style: const TextStyle(fontSize: 11, color: _T.textSecondary)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _T.divider),
        ),
        actions: [
          _ActionMenu(
            booking: booking,
            onSelected: (v) =>
                _handleStatusChange(booking, v, totalPrice, userRole),
          ),
        ],
      );

  // ── Customer ────────────────────────────────────────────────────────────────

  Widget _customerCard(BookingModel b) => _Card(
        iconBg: _T.tealBg,
        iconColor: _T.teal,
        icon: Icons.person_outline_rounded,
        title: 'Customer Information',
        child: Column(children: [
          _Row(label: 'Name', value: b.customerInfo.name),
          const _HDivider(indent: true),
          _Row(
            label: 'Phone',
            child: Text(b.customerInfo.phone,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: _T.teal)),
          ),
          const _HDivider(indent: true),
          _Row(label: 'Address', value: b.customerAddress.toString()),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _TealBtn(
              icon: Icons.directions_rounded,
              label: 'Get Directions',
              onTap: targetLocation != null
                  ? () => _openDirections(targetLocation!)
                  : null,
            ),
          ),
        ]),
      );

  // ── Time Slots ──────────────────────────────────────────────────────────────

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
                      time: '${s.startTime} – ${s.endTime}'),
                ))
            .toList(),
      ),
    );
  }

  // ── Services ────────────────────────────────────────────────────────────────

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
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.auto_awesome_rounded,
                            size: 16, color: _T.teal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(svc.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _T.textPrimary)),
                            if ((svc.categoryName).isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(svc.categoryName,
                                  style: const TextStyle(
                                      fontSize: 12, color: _T.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (svc.hasDiscount)
                            Text('₹${svc.mrpPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: _T.textSecondary,
                                    decoration: TextDecoration.lineThrough)),
                          Text('₹${svc.finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _T.teal)),
                          if (disc > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: _T.greenBg,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text('$disc% off',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: _T.green)),
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
                label: 'Subtotal', value: '₹${totalPrice.toStringAsFixed(0)}'),
            if (days > 1) ...[
              const SizedBox(height: 4),
              _SumRow(
                  label: '× $days days',
                  value: '₹${(totalPrice * days).toStringAsFixed(0)}'),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: _T.tealBg, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _T.teal)),
                  Text('₹${(totalPrice * days).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _T.tealDark)),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Maid ────────────────────────────────────────────────────────────────────

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
              CircleAvatar(
                radius: 24,
                backgroundColor: _T.indigoBg,
                child: Text(
                  b.maid!.name.isNotEmpty ? b.maid!.name[0].toUpperCase() : '?',
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
                  Text(b.maid!.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _T.textPrimary)),
                  const SizedBox(height: 2),
                  Text(b.maid!.phone,
                      style: const TextStyle(
                          fontSize: 13, color: _T.textSecondary)),
                ],
              ),
            ]),
            const SizedBox(height: 8),
            const _HDivider(indent: true),
            const SizedBox(height: 2),
            _Row(
              label: 'Assigned On',
              value: b.assignedTime?.isNotEmpty == true ? b.assignedTime! : '—',
            ),
            const _HDivider(indent: true),
            _Row(
              label: 'Assigned By',
              value: b.assignedBy?.isNotEmpty == true ? b.assignedBy! : '—',
            ),
          ] else
            const _Row(label: 'Maid', value: 'Not assigned'),
          if (isAdmin && !done) ...[
            const SizedBox(height: 4),
            const _HDivider(),
            const SizedBox(height: 10),
            Row(children: [
              if (hasMaid) ...[
                _RedBtn(
                  icon: Icons.person_remove_outlined,
                  label: 'Unassign',
                  onTap: () => _unassignMaid(b),
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

  // ── Booking Info ────────────────────────────────────────────────────────────

  Widget _bookingInfoCard(BookingModel b, bool isAdmin) => _Card(
        iconBg: _T.orangeBg,
        iconColor: _T.orange,
        icon: Icons.receipt_long_rounded,
        title: 'Booking Info',
        child: Column(children: [
          _Row(label: 'Status', child: _Badge(status: b.serviceStatus)),
          const _HDivider(indent: true),
          _Row(
            label: 'Booking ID',
            child: Text('#${b.bookingId}',
                style: const TextStyle(fontSize: 12, color: _T.textSecondary)),
          ),
          if (b.parentBookingId.isNotEmpty) ...[
            const _HDivider(indent: true),
            _Row(label: 'Parent Booking', value: b.parentBookingId),
          ],
          const _HDivider(indent: true),
          _Row(
            label: 'Booked On',
            value: DateFormat('dd MMM yyyy, hh:mm a').format(b.bookingDate),
          ),
          const _HDivider(indent: true),
          _Row(label: 'Booked By', value: b.bookedBy),
          if (b.otpVerifiedTime.isNotEmpty) ...[
            const _HDivider(indent: true),
            _Row(label: 'Started On', value: b.otpVerifiedTime),
          ],
          if (b.maidId!.isNotEmpty &&
              (b.maid?.commissionPercentage ?? 0) > 0) ...[
            const _HDivider(indent: true),
            _Row(
              label: 'Commission',
              value: '${b.maid!.commissionPercentage.toStringAsFixed(0)}%',
            ),
          ],
          if (b.serviceStatus == AppConstants.completed) ...[
            const _HDivider(indent: true),
            _Row(label: 'Completed On', value: b.serviceCompletedTime),
            if (b.assignedTime!.isNotEmpty &&
                b.serviceCompletedTime.isNotEmpty) ...[
              const _HDivider(indent: true),
              _Row(
                label: 'Service Time',
                value: AppConstants.getTimeDifference(
                    b.assignedTime!, b.serviceCompletedTime),
              ),
            ],
          ],
          if (isAdmin) ...[
            const _HDivider(indent: true),
            _Row(label: 'OTP', value: b.otp.isNotEmpty ? b.otp : '—'),
          ],
        ]),
      );

  // ── Payment ─────────────────────────────────────────────────────────────────

  Widget _paymentCard(BookingModel b, double totalPrice) {
    final isPaid = b.paymentInfo!.status == AppConstants.paid;
    return _Card(
      iconBg: _T.greenBg,
      iconColor: _T.green,
      icon: Icons.credit_card_rounded,
      title: 'Payment',
      child: Column(children: [
        _Row(label: 'Status', child: _Badge(status: b.paymentInfo!.status)),
        const _HDivider(indent: true),
        _Row(
          label: 'Payment ID',
          child: Text(
            b.paymentInfo!.paymentId.isNotEmpty
                ? b.paymentInfo!.paymentId
                : '—',
            style: const TextStyle(fontSize: 13, color: _T.textSecondary),
          ),
        ),
        if (isPaid) ...[
          const _HDivider(indent: true),
          _Row(label: 'Method', value: b.paymentInfo!.method),
          const _HDivider(indent: true),
          _Row(
            label: 'Payment Date',
            value: DateFormat('dd MMM yyyy, hh:mm a')
                .format(b.paymentInfo!.createdAt),
          ),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable Widgets
// ══════════════════════════════════════════════════════════════════════════════

/// Card shell matching mockup style
class _Card extends StatelessWidget {
  final Color iconBg, iconColor;
  final IconData icon;
  final String title;
  final Widget child;

  const _Card({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.child,
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
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _T.textPrimary)),
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
class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _Row({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _T.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: child ??
                Text(value ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _T.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _HDivider extends StatelessWidget {
  final bool indent;
  const _HDivider({this.indent = false});

  @override
  Widget build(BuildContext context) => Container(
        height: 0.5,
        color: _T.divider,
      );
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
            const Icon(Icons.access_time_rounded, size: 14, color: _T.tealDeep),
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
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _T.badgeText(status))),
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
                    fontSize: 19, fontWeight: FontWeight.w500, color: _T.teal),
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
              style: const TextStyle(fontSize: 13, color: _T.textSecondary)),
          Text(value,
              style: const TextStyle(fontSize: 13, color: _T.textSecondary)),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              color: _T.redBg,
              border: Border.all(color: _T.redBorder, width: 0.5),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: _T.red),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: _T.red)),
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
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: fg, fontSize: 14))),
        ),
      );
}

/// Actions popup menu
class _ActionMenu extends StatelessWidget {
  final BookingModel booking;
  final void Function(String) onSelected;
  const _ActionMenu({required this.booking, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final s = booking.serviceStatus;
    return PopupMenuButton<String>(
      onSelected: onSelected,
      icon: const Icon(Icons.more_vert_rounded,
          color: _T.textSecondary, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      itemBuilder: (_) => [
        if (s != AppConstants.inProgress &&
            s != AppConstants.accepted &&
            s != AppConstants.completed)
          _mi(AppConstants.accepted, 'Accept', Icons.check_circle_outline,
              _T.teal, _T.tealBg),
        if (s == AppConstants.accepted && s != AppConstants.completed)
          _mi(AppConstants.inProgress, 'Mark In Progress',
              Icons.play_circle_outline, Colors.blue, const Color(0xFFDBEAFE)),
        if (s == AppConstants.inProgress && s != AppConstants.completed)
          _mi(AppConstants.completed, 'Mark Complete', Icons.task_alt_rounded,
              _T.tealDark, _T.tealBg),
        if (s == AppConstants.completed &&
            booking.paymentInfo!.status != AppConstants.paid)
          _mi(AppConstants.paid, 'Mark as Paid', Icons.payments_outlined,
              _T.green, _T.greenBg),
        if (s != AppConstants.inProgress && s != AppConstants.completed)
          _mi(AppConstants.cancelled, 'Cancel Booking', Icons.cancel_outlined,
              _T.red, _T.redBg),
      ],
    );
  }

  PopupMenuItem<String> _mi(
          String value, String label, IconData icon, Color color, Color bg) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ]),
      );
}
