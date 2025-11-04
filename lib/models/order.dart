import 'cart_item.dart';

class Order {
  final String id;
  final String userId;
  final double total;
  final String status;
  final String? paymentMethod;
  final String? shippingAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<CartItem>? items;

  Order({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    this.paymentMethod,
    this.shippingAddress,
    required this.createdAt,
    this.updatedAt,
    this.items,
  });

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'total': total,
        'status': status,
        'payment_method': paymentMethod,
        'shipping_address': shippingAddress,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        total: json['total'] as double,
        status: json['status'] as String,
        paymentMethod: json['payment_method'] as String?,
        shippingAddress: json['shipping_address'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );
}
