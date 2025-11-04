import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/marketplace_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with TickerProviderStateMixin {
  final _marketplaceService = MarketplaceService();
  final _authService = AuthService();
  
  String? _userId;
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      _userId = await _authService.getCurrentUserId() ?? 
                await _authService.getSavedEmail() ?? 
                'default_user';
      
      final products = await _marketplaceService.getProducts(category: _selectedCategory);
      final categories = await _marketplaceService.getCategories();
      final cartItems = await _marketplaceService.getCartItems(_userId!);

      if (!mounted) return;
      setState(() {
        _products = products;
        _categories = categories;
        _cartItems = cartItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.backgroundColor,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _filterByCategory(String? category) {
    setState(() => _selectedCategory = category);
    _loadData();
  }

    Future<void> _addToCart(Product product, int quantity) async {
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to add items to cart'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    try {
      await _marketplaceService.addToCart(_userId!, product.id, quantity);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
            backgroundColor: AppTheme.accentColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.backgroundColor,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateCartQuantity(String cartItemId, int quantity) async {
    try {
      await _marketplaceService.updateCartItemQuantity(cartItemId, quantity);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating cart: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.backgroundColor,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeFromCart(String cartItemId) async {
    try {
      await _marketplaceService.removeFromCart(cartItemId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from cart'),
            backgroundColor: AppTheme.accentColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.backgroundColor,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkout() async {
    if (_cartItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
           content: const Text('Your cart is empty'),
           backgroundColor: AppTheme.errorColor,
         ),
        );
      }
      return;
    }

    final total = _cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            cartItems: _cartItems,
            total: total,
          ),
        ),
      ).then((_) {
        // Reload data when returning from payment screen
        _loadData();
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marketplace'),
        backgroundColor: Colors.transparent,
        elevation: 0,
                 bottom: TabBar(
           controller: _tabController,
           labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.accentColor,
                     tabs: [
             const Tab(icon: Icon(Icons.store), text: 'Products'),
             Tab(
               icon: Stack(
                 children: [
                   const Icon(Icons.shopping_cart),
                  if (_cartItems.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                                                 constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                         child: Center(
                           child: Text(
                             '${_cartItems.length}',
                             style: const TextStyle(
                               color: AppTheme.backgroundColor,
                               fontSize: 10,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ),
                       ),
                     ),
                 ],
               ),
               text: 'Cart',
             ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildCartTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    return Column(
      children: [
        // Category filter
        Container(
          height: 60,
          padding: EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final isSelected = (isAll && _selectedCategory == null) ||
                  (!isAll && _categories[index - 1] == _selectedCategory);
              
                             return Padding(
                 padding: const EdgeInsets.only(right: 8),
                 child: FilterChip(
                   label: Text(isAll ? 'All' : _categories[index - 1]),
                  selected: isSelected,
                  onSelected: (_) => _filterByCategory(isAll ? null : _categories[index - 1]),
                  selectedColor: AppTheme.accentColor.withOpacity(0.3),
                  checkmarkColor: AppTheme.accentColor,
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? AppTheme.accentColor 
                        : AppTheme.textSecondaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        
                 Expanded(
           child: _products.isEmpty
               ? Center(child: Text('No products available', style: const TextStyle(color: AppTheme.textSecondaryColor)))
               : ListView.builder(
                   padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) => _buildProductCard(_products[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(product.category),
                size: 40,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                     Text(
                     product.name,
                     style: const TextStyle(
                       color: AppTheme.textPrimaryColor,
                       fontSize: 16,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                  if (product.brand != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.brand!,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (product.rating != null) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 12,
                          ),
                        ),
                        if (product.reviewCount != null) ...[
                          Text(
                            ' (${product.reviewCount})',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                      ],
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!product.inStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (product.inStock) ...[
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: () => _addToCart(product, 1),
                    icon: Icon(Icons.add_shopping_cart),
                    color: AppTheme.accentColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'engine':
        return Icons.build;
      case 'brakes':
        return Icons.disc_full;
      case 'battery':
        return Icons.battery_charging_full;
      case 'tires':
        return Icons.blur_circular;
      case 'cooling':
        return Icons.water_drop;
      case 'accessories':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  Widget _buildCartTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
    }

    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 100, color: AppTheme.textSecondaryColor),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 18),
            ),
          ],
        ),
      );
    }

    final total = _cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) => _buildCartItemCard(_cartItems[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(
                      color: AppTheme.backgroundColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final product = item.product;
    if (product == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(product.category),
                size: 30,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                                  IconButton(
                    onPressed: () => _updateCartQuantity(item.id, item.quantity - 1),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.textSecondaryColor,
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateCartQuantity(item.id, item.quantity + 1),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removeFromCart(item.id),
                    icon: const Icon(Icons.delete_outline),
                    color: AppTheme.errorColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
