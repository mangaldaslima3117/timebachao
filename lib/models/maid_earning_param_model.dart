import 'booking_model.dart';

class MaidEarningsParams {
  final String maidId;
  final List<BookingModel> bookings;

  MaidEarningsParams({required this.maidId, required this.bookings});
}
