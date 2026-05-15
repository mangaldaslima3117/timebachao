class EarningsSummary {
  final int totalOrders;
  final double totalEarnings;
  final double commissionPercent;
  final double commissionAmount;
  final double netEarnings;
  final int completedCount;
  final int cancelledCount;

  EarningsSummary({
    required this.totalOrders,
    required this.totalEarnings,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.netEarnings,
    required this.completedCount,
    required this.cancelledCount,
  });

  factory EarningsSummary.empty() => EarningsSummary(
        totalOrders: 0,
        totalEarnings: 0,
        commissionPercent: 10,
        commissionAmount: 0,
        netEarnings: 0,
        completedCount: 0,
        cancelledCount: 0,
      );
}
