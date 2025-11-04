class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String? imageUrl;
  final int stock;
  final String? brand;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.imageUrl,
    this.stock = 0,
    this.brand,
    this.rating,
    this.reviewCount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'image_url': imageUrl,
        'stock': stock,
        'brand': brand,
        'rating': rating,
        'review_count': reviewCount,
        'created_at': createdAt.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        price: json['price'] as double,
        imageUrl: json['image_url'] as String?,
        stock: json['stock'] as int? ?? 0,
        brand: json['brand'] as String?,
        rating: json['rating'] as double?,
        reviewCount: json['review_count'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  bool get inStock => stock > 0;
}
