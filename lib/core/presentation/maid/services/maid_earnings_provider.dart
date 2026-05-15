import 'package:bookmyservice/core/presentation/maid/services/current_maid_provider.dart';
import 'package:bookmyservice/core/utils/app_constants.dart';
import 'package:bookmyservice/models/maid_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/earnings_summary.dart';
import '../../../../models/maid_earning_param_model.dart';
import '../../../../services/bookings_provider.dart';

final maidEarningsProvider = FutureProvider<EarningsSummary?>((ref) async {
  final maidId = await ref.watch(maidIdProvider.future);
  final bookingsAsync = ref.watch(bookingsProvider);

  return bookingsAsync.when(
    data: (bookings) {
      final filtered = bookings
          .where((b) =>
              b.maidId == maidId && b.serviceStatus == AppConstants.completed)
          .toList();

      double totalEarnings =
          filtered.fold(0.0, (sum, b) => sum + (b.totalPrice));
      //double commissionPercent = 10;

      final commissionAmount = filtered.fold(
        0.0,
        (sum, b) =>
            sum +
            (b.serviceStatus == AppConstants.completed
                ? (b.totalPrice * (b.maid!.commissionPercentage / 100))
                : 0.0),
      );

      //final commissionAmount = (commissionPercent / 100) * totalEarnings;
      final netEarnings = totalEarnings - commissionAmount;
      final completedCount = filtered.fold(
        0,
        (sum, b) => sum + (b.serviceStatus == AppConstants.completed ? 1 : 0),
      );
      final cancelledCount = filtered.fold(
        0,
        (sum, b) => sum + (b.serviceStatus == AppConstants.completed ? 1 : 0),
      );

      return EarningsSummary(
        totalOrders: filtered.length,
        totalEarnings: totalEarnings,
        commissionPercent: 0,
        commissionAmount: commissionAmount,
        netEarnings: netEarnings,
        completedCount: completedCount,
        cancelledCount: cancelledCount,
      );
    },
    error: (_, __) => null,
    loading: () => null,
  );
});

final maidEarningsByIdProvider =
    FutureProvider.family<EarningsSummary?, MaidModel?>((ref, maid) async {
  final bookingsAsync = ref.watch(bookingsProvider);

  return bookingsAsync.when(
    data: (bookings) {
      final filtered = bookings.where((b) => b.maidId == maid!.id).toList();
      debugPrint('Filtered bookings: ${filtered.length}');
      double totalEarnings = filtered.fold(
          0.0,
          (sum, b) =>
              sum +
              (b.serviceStatus != AppConstants.cancelled ? b.totalPrice : 0.0));

      final commissionAmount = filtered.fold(
        0.0,
        (sum, b) =>
            sum +
            (b.serviceStatus != AppConstants.cancelled
                ? (b.totalPrice * (b.maid!.commissionPercentage / 100))
                : 0.0),
      );
      //final commissionAmount = (commissionPercent / 100) * totalEarnings;
      final netEarnings = totalEarnings - commissionAmount;
      final completedCount = filtered.fold(
        0,
        (sum, b) => sum + (b.serviceStatus == AppConstants.completed ? 1 : 0),
      );
      final cancelledCount = filtered.fold(
        0,
        (sum, b) => sum + (b.serviceStatus == AppConstants.cancelled ? 1 : 0),
      );

      return EarningsSummary(
        totalOrders: filtered.length,
        totalEarnings: totalEarnings,
        commissionPercent: maid!.commissionPercentage,
        commissionAmount: commissionAmount,
        netEarnings: netEarnings,
        completedCount: completedCount,
        cancelledCount: cancelledCount,
      );
    },
    error: (_, __) => null,
    loading: () => null,
  );
});
