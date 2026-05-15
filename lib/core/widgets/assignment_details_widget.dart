import 'package:bookmyservice/models/booking_model.dart';
import 'package:flutter/material.dart';

class AssignmentDetailsWidget extends StatelessWidget {
  final BookingModel booking;

  const AssignmentDetailsWidget({Key? key, required this.booking})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true, // Important if inside a Column/ScrollView
      physics:
          const NeverScrollableScrollPhysics(), // Prevents internal scrolling if nested
      itemCount: booking.bookingSlots.length,
      itemBuilder: (context, index) {
        final slot = booking.bookingSlots[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slot.serviceDate != null)
                  Text(
                    'Service Date: ${slot.serviceDate}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text('${slot.startTime} - ${slot.endTime}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      slot.maidName != null && slot.maidName!.isNotEmpty
                          ? '${slot.maidName}'
                          : 'No Maid Assigned',
                      style: TextStyle(
                        color:
                            slot.maidName != null && slot.maidName!.isNotEmpty
                                ? Colors.black
                                : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 6),
                // Row(
                //   children: [
                //     const Icon(Icons.check_circle, size: 18, color: Colors.blueGrey),
                //     const SizedBox(width: 8),
                //     Text(
                //       AppConstants.getStatusText(slot.status),
                //       style: TextStyle(
                //           color: AppConstants.getStatusColor(slot.status),
                //           fontWeight: FontWeight.w500),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}
