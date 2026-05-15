import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/slot_model.dart';
import '../../services/slots_provider.dart';

class DateWiseSlotSelector extends ConsumerStatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, TimeSlotModel> selectedSlots;
  final Function(String date, TimeSlotModel slot) onSlotSelected;

  const DateWiseSlotSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.selectedSlots,
    required this.onSlotSelected,
  });

  @override
  ConsumerState<DateWiseSlotSelector> createState() =>
      _DateWiseSlotSelectorState();
}

class _DateWiseSlotSelectorState extends ConsumerState<DateWiseSlotSelector> {
  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(slotProvider);
    final timeSlots = slotsAsync.where((slot) => slot.isAvailable).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pick slot for each day",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ),
      body: timeSlots.isNotEmpty
          ? ListView.builder(
              itemCount: widget.endDate.difference(widget.startDate).inDays + 1,
              itemBuilder: (context, index) {
                final date = widget.startDate.add(Duration(days: index));
                final formatted = DateFormat('dd-MM-yyyy').format(date);
                TimeSlotModel slot = widget.selectedSlots[formatted] != null
                    ? widget.selectedSlots[formatted]!
                    : TimeSlotModel.defaultTimeSlot();

                return Card(
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: Colors.teal, // When expanded
                      collapsedIconColor: Colors.grey, // When collapsed
                      title: Text(
                        DateFormat('MMM dd, EEEE').format(date),
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle:
                          slot.startTime.isNotEmpty && slot.endTime.isNotEmpty
                              ? Row(
                                  children: [
                                    const Text("Selected:  "),
                                    Text(
                                      "${slot.startTime} - ${slot.endTime}",
                                      style: const TextStyle(
                                        color: Colors.teal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text("No slot selected"),
                      children: timeSlots.map((s) {
                        final isSelected = slot.startTime == s.startTime &&
                            slot.endTime == s.endTime;
                        return ChoiceChip(
                          label: Text(
                            "${s.startTime} - ${s.endTime}",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.teal.shade300,
                          //backgroundColor: Colors.grey.shade200,
                          checkmarkColor:
                              isSelected ? Colors.white : Colors.black,
                          onSelected: (_) => setState(() {
                            slot = s;
                            TimeSlotModel formattedSlot = TimeSlotModel(
                              time: '',
                              isAvailable: true,
                              startTime: s.startTime,
                              endTime: s.endTime,
                              availableTime: '',
                              serviceDate: formatted,
                              maidId: s.maidId,
                              maidName: s.maidName,
                              assignedBy: s.assignedBy,
                              assignedTime: s.assignedTime,
                              status: s.status,
                            );
                            widget.onSlotSelected(
                              formatted,
                              formattedSlot,
                            );
                            widget.selectedSlots[formatted] = formattedSlot;
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Text("No available slots for the selected date range."),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, widget.selectedSlots);
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.check),
      ),
    );
  }
}
