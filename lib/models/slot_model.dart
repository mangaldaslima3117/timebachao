import 'package:intl/intl.dart';

class TimeSlotModel {
  final String time; // e.g., "AM/PM" FORMAT
  final bool isAvailable;
  final String? slotId;
  final int? durationMinutes;

  // New fields
  final String startTime;
  final String endTime;
  final String availableTime;
  String? serviceDate; // This can be used to store the date of the service
  String? maidId; // Optional field for maid ID
  String? maidName; // Optional field for maid name
  String? assignedBy; // Optional field for who assigned the slot
  String? assignedTime; // Optional field for when the slot was assigned
  String status; // New field for status tracking

  TimeSlotModel({
    required this.time,
    required this.isAvailable,
    this.slotId,
    this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.availableTime, // This can now be calculated
    required this.serviceDate,
    required this.maidId,
    required this.maidName,
    required this.assignedBy,
    required this.assignedTime,
    required this.status,
  });

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) {
    return TimeSlotModel(
      time: map['time'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      slotId: map['slotId'],
      durationMinutes: map['durationMinutes'],
      startTime: map['startTime'] ?? '', // Extract start time
      endTime: map['endTime'] ?? '', // Extract end time
      availableTime: map['availableTime'] ?? '', // Extract available time
      serviceDate: map['serviceDate'], // Extract service date
      maidId: map.containsKey('maidId') ? map['maidId'] : '', // Extract maid ID
      maidName: map.containsKey('maidName')
          ? map['maidName']
          : '', // Extract maid name
      assignedBy: map.containsKey('assignedBy')
          ? map['assignedBy']
          : '', // Extract who assigned the slot
      assignedTime: map.containsKey('assignedTime')
          ? map['assignedTime']
          : '', // Extract when the slot was assigned
      status: map.containsKey('status') ? map['status'] : '', // Default status
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'isAvailable': isAvailable,
      if (slotId != null) 'slotId': slotId,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      'startTime': startTime,
      'endTime': endTime,
      'availableTime': availableTime,
      'serviceDate': serviceDate,
      'maidId': maidId,
      'maidName': maidName,
      'assignedBy': assignedBy,
      'assignedTime': assignedTime,
      'status': status, // Include status in the map
    };
  }

  // Method to calculate availableTime dynamically
  static String calculateAvailableTime(String startTime, String endTime) {
    final format = DateFormat("hh:mm a");
    DateTime start = format.parse(startTime);
    DateTime end = format.parse(endTime);
    Duration diff = end.difference(start);
    return "${diff.inMinutes} minutes"; // You can change the output format if needed
  }

  // Default time slot with dynamic availableTime calculation
  static TimeSlotModel defaultTimeSlot() {
    return TimeSlotModel(
      time: '',
      isAvailable: true,
      slotId: null,
      durationMinutes: 0,
      startTime: '',
      endTime: '',
      availableTime: '',
      serviceDate: null,
      maidId: null,
      maidName: null,
      assignedBy: null,
      assignedTime: null,
      status: '', // Default status
    );
  }

  static List<TimeSlotModel> generateDefaultTimeSlots() {
    final slots = [
      {'start': '08:00 AM', 'end': '10:00 AM', 'slotId': "1"},
      {'start': '12:00 PM', 'end': '02:00 PM', 'slotId': "2"},
      {'start': '04:00 PM', 'end': '06:00 PM', 'slotId': "3"},
      {'start': '08:00 PM', 'end': '10:00 PM', 'slotId': "4"},
    ];

    return slots.map((slot) {
      final availableTime =
          calculateAvailableTime(slot['start']!, slot['end']!);
      return TimeSlotModel(
        time: slot['start']!,
        isAvailable: true,
        slotId: slot['slotId'],
        durationMinutes: 120,
        startTime: slot['start']!,
        endTime: slot['end']!,
        availableTime: availableTime,
        serviceDate: null, // You can set this to a specific date if needed
        maidId: null,
        maidName: null,
        assignedBy: null,
        assignedTime: null,
        status: '', // Default status
      );
    }).toList();
  }

  TimeSlotModel copyWith({
    String? time,
    bool? isAvailable,
    String? slotId,
    int? durationMinutes,
    String? startTime,
    String? endTime,
    String? availableTime,
    String? serviceDate,
    String? maidId,
    String? maidName,
    String? assignedBy,
    String? assignedTime,
    String? status,
  }) {
    return TimeSlotModel(
      time: time ?? this.time,
      isAvailable: isAvailable ?? this.isAvailable,
      slotId: slotId ?? this.slotId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      availableTime: availableTime ?? this.availableTime,
      serviceDate: serviceDate ?? this.serviceDate,
      maidId: maidId ?? this.maidId,
      maidName: maidName ?? this.maidName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedTime: assignedTime ?? this.assignedTime,
      status: status ?? this.status,
    );
  }
}
