class MitraTransactionModel {
  final String id;
  final String customerName;
  final String fieldName;
  final int amount;
  final DateTime date;

  const MitraTransactionModel({
    required this.id,
    required this.customerName,
    required this.fieldName,
    required this.amount,
    required this.date,
  });
}

class MitraRevenueModel {
  final int totalRevenue;
  final int totalOrders;
  final List<MitraTransactionModel> transactions;
  final int todayRevenue;
  final int pendingPayout;
  final int disbursedRevenue;
  final int availableBalance;
  final int activeBookings;
  final double payoutSuccessRate;
  final double revenueGrowth;
  final int periodRevenue;

  const MitraRevenueModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.transactions,
    this.todayRevenue = 0,
    this.pendingPayout = 0,
    this.disbursedRevenue = 0,
    this.availableBalance = 0,
    this.activeBookings = 0,
    this.payoutSuccessRate = 0.92,
    this.revenueGrowth = 0.0,
    this.periodRevenue = 0,
  });
}
