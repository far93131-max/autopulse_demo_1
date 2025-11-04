import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../database/database_helper.dart';

class MarketplaceService {
  final _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  // Products
  Future<List<Product>> getProducts({String? category}) async {
    final db = await _db;
    List<Map<String, dynamic>> maps;
    
    if (category != null && category.isNotEmpty) {
      maps = await db.query(
        'products',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('products', orderBy: 'created_at DESC');
    }

    return maps.map((map) => _mapToProduct(map)).toList();
  }

  Future<Product?> getProduct(String productId) async {
    final db = await _db;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToProduct(maps.first);
  }

  Future<List<String>> getCategories() async {
    final db = await _db;
    final maps = await db.query(
      'products',
      columns: ['category'],
      groupBy: 'category',
    );
    return maps.map((map) => map['category'] as String).toList();
  }

  Product _mapToProduct(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      price: map['price'] as double,
      imageUrl: map['image_url'] as String?,
      stock: map['stock'] as int? ?? 0,
      brand: map['brand'] as String?,
      rating: map['rating'] as double?,
      reviewCount: map['review_count'] as int?,
      createdAt: _dbHelper.timestampToDate(map['created_at'] as int),
    );
  }

  // Cart
  Future<List<CartItem>> getCartItems(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    final items = <CartItem>[];
    for (var map in maps) {
      final cartItem = _mapToCartItem(map);
      final product = await getProduct(cartItem.productId);
      items.add(CartItem(
        id: cartItem.id,
        productId: cartItem.productId,
        userId: cartItem.userId,
        quantity: cartItem.quantity,
        createdAt: cartItem.createdAt,
        product: product,
      ));
    }
    return items;
  }

  Future<void> addToCart(String userId, String productId, int quantity) async {
    final db = await _db;
    
    // Check if item already in cart
    final existing = await db.query(
      'cart_items',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final currentQuantity = existing.first['quantity'] as int;
      await db.update(
        'cart_items',
        {'quantity': currentQuantity + quantity},
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
    } else {
      await db.insert('cart_items', {
        'id': _dbHelper.generateId(),
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
        'created_at': _dbHelper.dateToTimestamp(DateTime.now()),
      });
    }
  }

  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    final db = await _db;
    if (quantity <= 0) {
      await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
    } else {
      await db.update('cart_items', {'quantity': quantity},
          where: 'id = ?', whereArgs: [cartItemId]);
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    final db = await _db;
    await db.delete('cart_items', where: 'id = ?', whereArgs: [cartItemId]);
  }

  Future<void> clearCart(String userId) async {
    final db = await _db;
    await db.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]);
  }

  CartItem _mapToCartItem(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      userId: map['user_id'] as String,
      quantity: map['quantity'] as int,
      createdAt: _dbHelper.timestampToDate(map['created_at'] as int),
    );
  }

  // Orders
  Future<List<Order>> getOrders(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToOrder(map)).toList();
  }

  Future<Order> createOrder(String userId, String paymentMethod, String? shippingAddress) async {
    final db = await _db;
    
    // Get cart items
    final cartItems = await getCartItems(userId);
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    // Calculate total
    final total = cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

    // Create order
    final orderId = _dbHelper.generateId();
    await db.insert('orders', {
      'id': orderId,
      'user_id': userId,
      'total': total,
      'status': 'pending',
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
      'created_at': _dbHelper.dateToTimestamp(DateTime.now()),
    });

    // Create order items
    final batch = db.batch();
    for (var item in cartItems) {
      batch.insert('order_items', {
        'id': _dbHelper.generateId(),
        'order_id': orderId,
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': item.product?.price ?? 0,
        'created_at': _dbHelper.dateToTimestamp(DateTime.now()),
      });
    }
    await batch.commit();

    // Clear cart
    await clearCart(userId);

    return getOrder(orderId);
  }

  Future<Order> getOrder(String orderId) async {
    final db = await _db;
    final maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (maps.isEmpty) throw Exception('Order not found');
    return _mapToOrder(maps.first);
  }

  Order _mapToOrder(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      total: map['total'] as double,
      status: map['status'] as String,
      paymentMethod: map['payment_method'] as String?,
      shippingAddress: map['shipping_address'] as String?,
      createdAt: _dbHelper.timestampToDate(map['created_at'] as int),
      updatedAt: map['updated_at'] != null 
          ? _dbHelper.timestampToDate(map['updated_at'] as int) 
          : null,
    );
  }
}
