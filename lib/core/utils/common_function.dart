import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/slot_model.dart';

bool isSlotExpired(TimeSlotModel slot) {
  if (slot.serviceDate == null) return true;

  final date = DateTime.parse(slot.serviceDate!); // e.g. 2025-06-14
  final slotStart = _combineDateAndTime(date, slot.startTime);

  return slotStart.isBefore(DateTime.now());
}

//This will check for expired slots based on the current date and time
bool isSlotExpiredDateRange(TimeSlotModel slot, DateTime selectedDate) {
  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);
  final selected = DateFormat('yyyy-MM-dd').format(selectedDate);

  if (today != selected) return false; // Not today, so allow

  try {
    final date = DateTime.parse(slot.serviceDate!); // e.g. 2025-06-14
    final current =
        DateTime(now.year, now.month, now.day, now.hour, now.minute);

    final slotDateTime = _combineDateAndTime(date, slot.startTime);
    ;
    return current.isAfter(slotDateTime);
  } catch (e) {
    return false;
  }
}

DateTime _combineDateAndTime(DateTime date, String timeString) {
  // Remove AM/PM suffix if present (since 24-hour format doesn't need it)
  final cleaned =
      timeString.replaceAll(RegExp(r'\s*(AM|PM)', caseSensitive: false), '');

  final parts = cleaned.split(':');
  int hour = int.parse(parts[0]);
  int minute = int.parse(parts[1]);

  return DateTime(date.year, date.month, date.day, hour, minute);
}

Map<String, TimeSlotModel> generateSlotMapForRange({
  required DateTime startDate,
  required DateTime endDate,
  required TimeSlotModel selectedSlot,
}) {
  final Map<String, TimeSlotModel> slotMap = {};

  for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
    final date = startDate.add(Duration(days: i));
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);

    slotMap[formattedDate] = TimeSlotModel(
      time: '',
      isAvailable: true,
      startTime: selectedSlot.startTime,
      endTime: selectedSlot.endTime,
      availableTime: '',
      serviceDate: formattedDate,
      maidId: selectedSlot.maidId,
      maidName: selectedSlot.maidName,
      assignedBy: selectedSlot.assignedBy,
      assignedTime: selectedSlot.assignedTime,
      status: selectedSlot.status,
      slotId: selectedSlot.slotId,
      durationMinutes: selectedSlot.durationMinutes,
    );
  }

  return slotMap;
}

bool isFutureDate(String? dateStr) {
  if (dateStr == null) return false;
  final now = DateTime.now();
  final format = DateFormat('dd-MM-yyyy');
  final parsedDate = format.parse(dateStr);
  return parsedDate.isAfter(DateTime(now.year, now.month, now.day));
}

Future<LatLng?> getLatLngFromAddress(String address) async {
  try {
    List<Location> locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      debugPrint('LOCATIONS LENGTH IS ${locations.length}');
      return LatLng(locations.first.latitude, locations.first.longitude);
    }
  } catch (e) {
    print("Geocoding failed: $e");
  }
  return null;
}