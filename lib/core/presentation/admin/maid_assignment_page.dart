import 'package:bookmyservice/models/maid_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/booking_model.dart';
import '../../../models/slot_model.dart';
import '../../../services/bookings_provider.dart';
import '../../../services/shared_preference_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart'; // Where showMaidSelectionSheet exists

class MaidAssignmentPage extends ConsumerStatefulWidget {
  final BookingModel booking;

  const MaidAssignmentPage({
    super.key,
    required this.booking,
  });

  @override
  ConsumerState<MaidAssignmentPage> createState() => _MaidAssignmentPageState();
}

class _MaidAssignmentPageState extends ConsumerState<MaidAssignmentPage> {
  MaidModel? selectedMaidForAll;
  List<TimeSlotModel> updatedSlots = [];

  @override
  void initState() {
    super.initState();
    selectedMaidForAll = widget.booking.maid!.id.isNotEmpty
        ? widget.booking.maid
        : MaidModel.getDefaultMaid();
    debugPrint('MAID DETAILS : ${selectedMaidForAll!.name}');
    debugPrint('MAID DETAILS ID: ${selectedMaidForAll!.id}');
    // Create a true copy of booking slots so edits don't affect original booking
    updatedSlots = widget.booking.bookingSlots
        .map((slot) => slot.copyWith(
              maidId: slot.maidId,
              maidName: slot.maidName,
              assignedBy: slot.assignedBy,
              assignedTime: slot.assignedTime,
              serviceDate: slot.serviceDate,
            ))
        .toList();
  }

  void assignMaidToAll() {
    final userRole = ref.watch(roleProvider);
    if (selectedMaidForAll == null || selectedMaidForAll!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a maid first.")),
      );
      return;
    }

    setState(() {
      widget.booking.maid = selectedMaidForAll;
      updatedSlots = updatedSlots.map((slot) {
        return slot.copyWith(
          maidId: selectedMaidForAll!.id,
          maidName: selectedMaidForAll!.name,
          assignedBy: userRole?.roleType ?? '',
          assignedTime: DateTime.now().toIso8601String(),
          status: AppConstants.pending,
        );
      }).toList();
    });
  }

  void unAssignMaidToAll() {
    final userRole = ref.watch(roleProvider);

    setState(() {
      selectedMaidForAll = MaidModel.getDefaultMaid();
      widget.booking.maid = selectedMaidForAll;
      updatedSlots = updatedSlots.map((slot) {
        return slot.copyWith(
          maidId: selectedMaidForAll!.id,
          maidName: selectedMaidForAll!.name,
          assignedBy: userRole?.roleType ?? '',
          assignedTime: DateTime.now().toIso8601String(),
          status: AppConstants.pending,
        );
      }).toList();
    });
  }

  void assignMaidToSlot(int index) {
    final userRole = ref.watch(roleProvider);
    getSelectedMaid(context, ref, widget.booking)!.then((selectedMaid) {
      if (selectedMaid != null) {
        debugPrint(
            'Assigned maid ${selectedMaid.id} to slot ${widget.booking.bookingSlots[index].serviceDate}');
        setState(() {
          updatedSlots[index] = updatedSlots[index].copyWith(
            maidId: selectedMaid.id,
            maidName: selectedMaid.name,
            assignedBy: userRole?.roleType ?? '',
            assignedTime: DateTime.now().toIso8601String(),
            status: AppConstants.pending,
          );
        });
      }
    });
  }

  void selectMaidForAll() {
    getSelectedMaid(context, ref, widget.booking)!.then((selectedMaid) {
      if (selectedMaid != null) {
        debugPrint('Assigned maid ${selectedMaid.name}');
        setState(() {
          selectedMaidForAll = selectedMaid;
        });
      }
    });
  }

  void _saveAssignments() async {
    widget.booking.maid = selectedMaidForAll;
    widget.booking.bookingSlots = updatedSlots;
    await ref
        .read(bookingsProvider.notifier)
        .updateMaidAssignment(widget.booking);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assign Maid to Slots",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (widget.booking.bookingSlots.length > 1)
            Card(
              color: Colors.teal.shade50,
              child: ListTile(
                title: const Text(
                  "Assign One Maid to All Slots",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: selectedMaidForAll != null
                    ? Text("Maid : ${selectedMaidForAll!.name}")
                    : const Text("Maid : "),
                trailing: ElevatedButton(
                  onPressed: selectMaidForAll,
                  child: const Text(
                    "Pick Maid",
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (widget.booking.bookingSlots.length > 1)
            Column(
              children: [
                if (widget.booking.maid!.id.isEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_turned_in),
                    label: const Text("Assign to All Slots"),
                    onPressed: assignMaidToAll,
                  ),
                if (widget.booking.maid!.id.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_turned_in),
                    label: const Text("UnAssign from All Slots"),
                    onPressed: unAssignMaidToAll,
                  ),
              ],
            ),
          const SizedBox(height: 10),
          if (widget.booking.bookingSlots.length > 1)
            const Center(
              child: Text(
                "OR",
                style: TextStyle(),
              ),
            ),
          if (widget.booking.bookingSlots.length > 1) const Divider(height: 30),
          if (widget.booking.bookingSlots.length > 1)
            const Text("Assign Maid Individually to Slots:",
                style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...updatedSlots.asMap().entries.map((entry) {
            final slot = entry.value;
            return Card(
              child: ListTile(
                title: Text(
                    "${slot.serviceDate} | ${slot.startTime} - ${slot.endTime}"),
                subtitle: slot.maidId != null
                    ? Text("Maid : ${slot.maidName}")
                    : const Text(""),
                trailing: ElevatedButton(
                  onPressed: () => assignMaidToSlot(entry.key),
                  child: Text(
                    slot.maidId!.isNotEmpty ? "Change Maid" : "Assign Maid",
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          slot.maidId!.isNotEmpty ? Colors.blue : Colors.teal,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () async {
                    _saveAssignments();
                  },
                  style: TextButton.styleFrom(
                    elevation: 1.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(
                      80,
                      30,
                    ),
                    side: const BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
