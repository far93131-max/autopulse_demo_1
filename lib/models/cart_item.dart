import 'product.dart';

class CartItem {
  final String id;
  final String productId;
  final String userId;
  final int quantity;
  final DateTime createdAt;
  final Product? product;

  CartItem({
    required this.id,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.createdAt,
    this.product,
  });

  double get totalPrice => (product?.price ?? 0) * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'user_id': userId,
        'quantity': quantity,
        'created_at': createdAt.toIso8601String(),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        userId: json['user_id'] as String,
        quantity: json['quantity'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
