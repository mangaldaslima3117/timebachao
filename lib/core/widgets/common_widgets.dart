import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../models/maid_model.dart';
import '../../services/bookings_provider.dart';
import '../../services/maids_provider.dart';
import '../../services/user_provider.dart';
import '../utils/common_function.dart';

void showMaidSelectionSheet(
  BuildContext context,
  WidgetRef ref,
  BookingModel currentBooking,
) {
  final maids = ref.watch(maidAccountProvider);
  final userDtl = ref.watch(userProvider);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final searchController = TextEditingController();
          MaidModel? selectedMaid;

          return StatefulBuilder(builder: (context, setState) {
            final filteredMaids = maids.where((maid) {
              final searchText = searchController.text.toLowerCase();
              return maid.name.toLowerCase().contains(searchText);
            }).toList();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔍 Search Field
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search maid by name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // 📜 Maid List
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: filteredMaids.isEmpty
                        ? const Center(child: Text('No maids found.'))
                        : ListView.builder(
                            itemCount: filteredMaids.length,
                            itemBuilder: (context, index) {
                              final maid = filteredMaids[index];
                              final isSelected = selectedMaid?.id == maid.id;

                              return ListTile(
                                enabled: isFutureDate(
                                        currentBooking.timeSlot.serviceDate) ||
                                    maid.isAvailable,
                                selectedColor: Colors.teal.shade100,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(maid.name),
                                subtitle: Text(maid.phone),
                                trailing: Text(
                                  isFutureDate(currentBooking
                                              .timeSlot.serviceDate) ||
                                          maid.isAvailable
                                      ? 'Available'
                                      : 'Work in Progress',
                                  style: TextStyle(
                                    color: isFutureDate(currentBooking
                                                .timeSlot.serviceDate) ||
                                            maid.isAvailable
                                        ? Colors.green
                                        : Colors.blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                tileColor: isSelected
                                    ? Colors.teal.shade100
                                    : Colors.transparent,
                                onTap: () {
                                  setState(() => selectedMaid = maid);
                                },
                              );
                            },
                          ),
                  ),

                  // ✅ Update & ❌ Cancel Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: selectedMaid == null
                              ? null
                              : () async {
                                  //Store the previously selected maid if already assigned
                                  String? previousMaidId =
                                      currentBooking.maidId ?? '';
                                  debugPrint('USER DETAILS AS FOLLOWS:  ');
                                  debugPrint(userDtl?.role.roleType.toString());

                                  currentBooking.maid = selectedMaid;
                                  currentBooking.assignedTime =
                                      DateFormat('dd-MM-yyyy HH:mm:ss')
                                          .format(DateTime.now());
                                  currentBooking.assignedBy = userDtl != null
                                      ? userDtl.role.roleType
                                      : '';
                                  selectedMaid!.isAvailable = isFutureDate(
                                          currentBooking.timeSlot.serviceDate)
                                      ? true
                                      : false;
                                  await ref
                                      .read(bookingsProvider.notifier)
                                      .assignMaid(currentBooking);

                                  await ref
                                      .read(maidAccountProvider.notifier)
                                      .updateMaidAvailability(
                                        selectedMaid!.id,
                                        false,
                                      );

                                  if (previousMaidId.isNotEmpty &&
                                      previousMaidId != selectedMaid!.id) {
                                    await ref
                                        .read(maidAccountProvider.notifier)
                                        .updateMaidAvailability(
                                          previousMaidId,
                                          true,
                                        );
                                  }

                                  Navigator.pop(context);
                                },
                          child: const Text(
                            'Assign',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  )
                ],
              ),
            );
          });
        },
      );
    },
  );
}

Future<bool> showPaymentConfirmationDialog(
  BuildContext context,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm Payment'),
            content: const Text(
              'Are you sure you want to mark this booking as paid?',
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, false);
                },
                child: const Text('Cash Payment'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context, true);
                },
                child: const Text('Online Payment'),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<MaidModel?>? getSelectedMaid(
  BuildContext context,
  WidgetRef ref,
  BookingModel currentBooking,
) {
  final maids = ref.watch(maidAccountProvider);
  return showModalBottomSheet<MaidModel>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final searchController = TextEditingController();
          MaidModel? selectedMaid;

          return StatefulBuilder(builder: (context, setState) {
            final filteredMaids = maids.where((maid) {
              final searchText = searchController.text.toLowerCase();
              return maid.name.toLowerCase().contains(searchText);
            }).toList();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔍 Search Field
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search maid by name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // 📜 Maid List
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: filteredMaids.isEmpty
                        ? const Center(child: Text('No maids found.'))
                        : ListView.builder(
                            itemCount: filteredMaids.length,
                            itemBuilder: (context, index) {
                              final maid = filteredMaids[index];
                              final isSelected = selectedMaid?.id == maid.id;

                              return ListTile(
                                enabled: maid.isAvailable,
                                selectedColor: Colors.teal.shade100,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(maid.name),
                                subtitle: Text(maid.phone),
                                trailing: Text(
                                  maid.isAvailable
                                      ? 'Available'
                                      : 'Work in Progress',
                                  style: TextStyle(
                                    color: maid.isAvailable
                                        ? Colors.green
                                        : Colors.blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                tileColor: isSelected
                                    ? Colors.teal.shade100
                                    : Colors.transparent,
                                onTap: () {
                                  setState(() => selectedMaid = maid);
                                },
                              );
                            },
                          ),
                  ),

                  // ✅ Update & ❌ Cancel Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: () async {
                            Navigator.pop(context, selectedMaid!);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  )
                ],
              ),
            );
          });
        },
      );
    },
  );
}
