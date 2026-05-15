import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DynamicCalendarIcon extends StatelessWidget {
  final String bookedOn;
  const DynamicCalendarIcon({super.key, required this.bookedOn});

  @override
  Widget build(BuildContext context) {
    //final now = DateTime.now();
    final now = DateTime.parse(bookedOn);
    final day = DateFormat('d').format(now);
    final month = DateFormat('MMM').format(now);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 0.2,
        ),
      ),
      width: 20,
      height: 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            decoration: BoxDecoration(
              color: Colors.red[400],
              //borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                month.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 5,
                ),
              ),
            ),
          ),
          Container(
            // decoration: BoxDecoration(
            //   color: Colors.red[400],
            //   borderRadius: BorderRadius.circular(4),
            // ),
            child: Text(
              day,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
