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

  const MitraRevenueModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.transactions,
  });
}
