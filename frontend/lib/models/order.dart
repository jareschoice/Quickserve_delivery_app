class OrderModel {
  final String id;
  final String status;
  final double total;

  OrderModel({required this.id, required this.status, required this.total});

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? '',
      status: json['status'] ?? 'placed',
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}
