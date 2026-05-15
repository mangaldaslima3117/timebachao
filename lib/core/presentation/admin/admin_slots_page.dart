// admin_slot_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/slot_model.dart';
import '../../../services/slots_provider.dart';
import '../../widgets/delete_confirmation_dialog.dart';

class AdminSlotPage extends ConsumerStatefulWidget {
  const AdminSlotPage({super.key});

  @override
  ConsumerState<AdminSlotPage> createState() => _AdminSlotPageState();
}

class _AdminSlotPageState extends ConsumerState<AdminSlotPage> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _availableTimeController = TextEditingController();
  final _durationController = TextEditingController();
  final _serviceDateController = TextEditingController();

  String _selectedAmPm = 'AM';
  TimeSlotModel? _editingSlot;

  final inputDecoration = const InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
    filled: true,
    fillColor: Color(0xFFF5F5F5),
  );

  @override
  void dispose() {
    _timeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _availableTimeController.dispose();
    _durationController.dispose();
    _serviceDateController.dispose();
    super.dispose();
  }

  void _showSlotFormModal([TimeSlotModel? slot]) {
    if (slot != null) {
      _editingSlot = slot;
      final timeParts = slot.time.split(' ');
      _timeController.text = timeParts[0];
      _selectedAmPm = timeParts.length > 1 ? timeParts[1] : 'AM';
      _startTimeController.text = slot.startTime;
      _endTimeController.text = slot.endTime;
      _availableTimeController.text = slot.availableTime;
      _durationController.text = slot.durationMinutes?.toString() ?? '';
      _serviceDateController.text = slot.serviceDate ?? '';
    } else {
      _editingSlot = null;
      _timeController.clear();
      _selectedAmPm = 'AM';
      _startTimeController.clear();
      _endTimeController.clear();
      _availableTimeController.clear();
      _durationController.clear();
      _serviceDateController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Slot Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      final formattedTime = picked.format(context);
                      final suffix =
                          picked.period == DayPeriod.am ? 'AM' : 'PM';
                      setState(() =>
                          _startTimeController.text = '$formattedTime $suffix');
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration:
                          inputDecoration.copyWith(labelText: 'Start Time'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      final formattedTime = picked.format(context);
                      final suffix =
                          picked.period == DayPeriod.am ? 'AM' : 'PM';
                      setState(() =>
                          _endTimeController.text = '$formattedTime $suffix');
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration:
                          inputDecoration.copyWith(labelText: 'End Time'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.teal.shade400,
                    ),
                  ),
                  onPressed: _submitSlot,
                  child: Text(
                    _editingSlot == null ? 'Save' : 'Update',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitSlot() async {
    if (_formKey.currentState!.validate()) {
      final fullTime = '${_timeController.text} $_selectedAmPm';
      if (_editingSlot != null) {
        final updatedSlot = TimeSlotModel(
          time: fullTime,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          availableTime: _availableTimeController.text,
          durationMinutes: int.tryParse(_durationController.text),
          serviceDate: _serviceDateController.text.isNotEmpty
              ? _serviceDateController.text
              : null,
          slotId: _editingSlot!.slotId,
          isAvailable: _editingSlot!.isAvailable,
          maidId: _editingSlot!.maidId,
          maidName: _editingSlot!.maidName,
          assignedBy: _editingSlot!.assignedBy,
          assignedTime: _editingSlot!.assignedTime,
          status: _editingSlot!.status,
        );
        await ref.read(slotProvider.notifier).updateSlot(updatedSlot);
      } else {
        await ref.read(slotProvider.notifier).addSlot(
              time: fullTime,
              startTime: _startTimeController.text,
              endTime: _endTimeController.text,
              availableTime: _availableTimeController.text,
              durationMinutes: int.tryParse(_durationController.text),
              serviceDate: _serviceDateController.text.isNotEmpty
                  ? _serviceDateController.text
                  : null,
            );
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(slotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Slots',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${slot.startTime} - ${slot.endTime}'),
              //subtitle: Text('Available: ${slot.availableTime}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                    ),
                    onPressed: () => _showSlotFormModal(slot),
                  ),
                  IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final confirmed = await showDeleteConfirmationDialog(
                          context: context,
                          title: 'Delete Slot',
                          content:
                              'Are you sure you want to delete this ${slot.startTime} - ${slot.endTime}?',
                        );
                        if (confirmed == true) {
                          ref
                              .read(slotProvider.notifier)
                              .removeSlot(slot.slotId);
                        }
                      }),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSlotFormModal(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
