import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppConstants {
  static const String booked = "1"; //BOOKED
  static const String accepted = "2"; //ACCEPTED
  static const String inProgress = "3"; //INPROGRESS
  static const String completed = "4"; //COMPLETED
  static const String cancelled = "5"; //CANCELLED OR REJECTED THE ORDER
  static const String paid = "6"; //PAID
  static const String pending = "7"; //PENDING PAYMENT/BOOKING SERVICE
  static const String admin_role = "admin";
  static const String user_role = "customer";
  static const String maid_role = "maid";

  //APP TYPE
  static const String CUSTOMER_APP = "customer";
  static const String ADMIN_APP = "admin";
  static const String MAID_APP = "maid";
  static const String PAYMENT_CASH = "Cash";
  static const String PAYMENT_ONLINE = "Online";

  static String getStatusText(String status) {
    switch (status) {
      case booked:
        return 'Booked';
      case accepted:
        return 'Accepted';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case paid:
        return 'Paid';
      case pending:
        return 'Pending';
      default:
        return '';
    }
  }

  static Color getStatusColor(String value) {
    switch (value) {
      case '1':
        return Colors.green;
      case '2':
        return Colors.teal;
      case '3':
        return Colors.blue;
      case '4':
        return Colors.teal;
      case '5':
        return Colors.red;
      case '6':
        return Colors.green;
      case '7':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static String getTimeDifference(String startTime, String endTime) {
    // Define the format
    DateFormat format = DateFormat('dd-MM-yyyy HH:mm:ss');

    // Parse the strings into DateTime
    DateTime assignTime = format.parse(startTime);
    DateTime completeTime = format.parse(endTime);

    // Calculate the difference
    Duration diff = completeTime.difference(assignTime);

    String timeDifference = formatDuration(diff);

    return timeDifference;
  }

  static String formatDuration(Duration d) {
    int hours = d.inHours;
    int minutes = d.inMinutes.remainder(60);

    if (d.inMinutes >= 60) {
      return '$hours hr${hours > 1 ? 's' : ''} $minutes min';
    } else {
      return '$minutes min';
    }
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
