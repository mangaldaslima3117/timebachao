// slot_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/slot_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//SLOTS PROVIDER
final slotProvider =
    NotifierProvider<SlotNotifier, List<TimeSlotModel>>(() => SlotNotifier());

final slotStreamProvider = StreamProvider<List<TimeSlotModel>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore.collection('slots').snapshots().map((snapshot) {
    final slots =
        snapshot.docs.map((doc) => TimeSlotModel.fromMap(doc.data())).toList();

    slots.sort((a, b) =>
        _parseSimpleTime(a.startTime).compareTo(_parseSimpleTime(b.startTime)));
    return slots;
  });
});

DateTime _parseSimpleTime(String timeStr) {
  final format = DateFormat('hh:mm a'); // Matches "08:00 AM", "12:00 PM"
  return format.parse(timeStr);
}

class SlotNotifier extends Notifier<List<TimeSlotModel>> {
  final _firestore = FirebaseFirestore.instance;

  @override
  List<TimeSlotModel> build() {
    _loadSlots();
    return [];
  }

  Future<void> _loadSlots() async {
    final snapshot = await _firestore.collection('slots').get();
    final loadedSlots =
        snapshot.docs.map((doc) => TimeSlotModel.fromMap(doc.data())).toList();
    loadedSlots.sort((a, b) =>
        _parseSimpleTime(a.startTime).compareTo(_parseSimpleTime(b.startTime)));
    state = loadedSlots;
  }

  Future<void> addSlot({
    required String time,
    required String startTime,
    required String endTime,
    required String availableTime,
    int? durationMinutes,
    String? serviceDate,
  }) async {
    final slotId = const Uuid().v4();
    final newSlot = TimeSlotModel(
      time: time,
      isAvailable: true,
      slotId: slotId,
      durationMinutes: durationMinutes,
      startTime: startTime,
      endTime: endTime,
      availableTime: availableTime,
      serviceDate: serviceDate,
      maidId: null, // Optional field for maid ID
      maidName: null, // Optional field for maid name
      assignedBy: null, // Optional field for who assigned the slot
      assignedTime: null, // Optional field for when the slot was assigned
      status: '', // Default status
    );

    await _firestore.collection('slots').doc(slotId).set(newSlot.toMap());
    state = [...state, newSlot];
  }

  Future<void> updateSlot(TimeSlotModel updatedSlot) async {
    if (updatedSlot.slotId == null) return;
    await _firestore
        .collection('slots')
        .doc(updatedSlot.slotId)
        .update(updatedSlot.toMap());
    state = [
      for (final slot in state)
        if (slot.slotId == updatedSlot.slotId) updatedSlot else slot,
    ];
  }

  Future<void> removeSlot(String? slotId) async {
    if (slotId == null) return;
    await _firestore.collection('slots').doc(slotId).delete();
    state = state.where((slot) => slot.slotId != slotId).toList();
  }
}
