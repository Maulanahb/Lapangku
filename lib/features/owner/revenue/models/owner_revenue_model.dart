class OwnerTransactionModel {
  final String id;
  final String customerName;
  final String fieldName;
  final int amount;
  final DateTime date;

  const OwnerTransactionModel({
    required this.id,
    required this.customerName,
    required this.fieldName,
    required this.amount,
    required this.date,
  });
}

class OwnerRevenueModel {
  final int totalRevenue;
  final int totalOrders;
  final List<OwnerTransactionModel> transactions;

  const OwnerRevenueModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.transactions,
  });
}
