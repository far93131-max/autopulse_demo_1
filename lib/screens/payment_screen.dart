import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/marketplace_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double total;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _marketplaceService = MarketplaceService();
  final _authService = AuthService();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  
  String? _userId;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'Credit Card';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    _userId = await _authService.getCurrentUserId() ?? 
              await _authService.getSavedEmail() ?? 
              'default_user';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _formatCardNumber(String input) {
    // Remove all non-digits
    String digits = input.replaceAll(RegExp(r'\D'), '');
    
    // Add spaces every 4 digits
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digits[i];
    }
    
    return formatted;
  }

  String _formatExpiry(String input) {
    // Remove all non-digits
    String digits = input.replaceAll(RegExp(r'\D'), '');
    
    // Format as MM/YY
    if (digits.length >= 2) {
      return '${digits.substring(0, 2)}/${digits.substring(2, digits.length > 4 ? 4 : digits.length)}';
    }
    
    return digits;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to complete payment'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Create order
      final order = await _marketplaceService.createOrder(
        _userId!,
        _selectedPaymentMethod,
        _addressController.text,
      );

      if (!mounted) return;
      
      setState(() => _isProcessing = false);

      // Clear form
      _nameController.clear();
      _addressController.clear();
      _cardNumberController.clear();
      _expiryController.clear();
      _cvvController.clear();

      // Show success dialog and navigate back
      _showSuccessDialog(order.id, order.formattedTotal);
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isProcessing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
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

  void _showSuccessDialog(String orderId, String total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.accentColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Order Placed!',
                style: const TextStyle(color: AppTheme.textPrimaryColor),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your order has been placed successfully.',
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Order ID: ${orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: $total',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to marketplace
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            child: const Text('Continue Shopping'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Order Summary Section
                    Card(
                      color: AppTheme.surfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_bag,
                                  color: AppTheme.accentColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Order Summary',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...widget.cartItems.map((item) {
                              final product = item.product;
                              if (product == null) return const SizedBox.shrink();
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(product.category),
                                        size: 24,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              color: AppTheme.textPrimaryColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Qty: ${item.quantity} × ${product.formattedPrice}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondaryColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${(item.totalPrice).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppTheme.accentColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(color: AppTheme.textSecondaryColor),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${widget.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Method Section
                    Card(
                      color: AppTheme.surfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.payment,
                                  color: AppTheme.accentColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text(
                                      'Credit Card',
                                      style: TextStyle(color: AppTheme.textPrimaryColor),
                                    ),
                                    value: 'Credit Card',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (value) {
                                      setState(() => _selectedPaymentMethod = value!);
                                    },
                                    activeColor: AppTheme.accentColor,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text(
                                      'Debit Card',
                                      style: TextStyle(color: AppTheme.textPrimaryColor),
                                    ),
                                    value: 'Debit Card',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (value) {
                                      setState(() => _selectedPaymentMethod = value!);
                                    },
                                    activeColor: AppTheme.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Details Section
                    Card(
                      color: AppTheme.surfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.credit_card,
                                  color: AppTheme.accentColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Payment Details',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Name on Card
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: AppTheme.textPrimaryColor),
                              decoration: const InputDecoration(
                                labelText: 'Name on Card',
                                labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                                prefixIcon: Icon(Icons.person, color: AppTheme.textSecondaryColor),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Card Number
                            TextFormField(
                              controller: _cardNumberController,
                              style: const TextStyle(color: AppTheme.textPrimaryColor),
                              decoration: const InputDecoration(
                                labelText: 'Card Number',
                                labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                                prefixIcon: Icon(Icons.credit_card, color: AppTheme.textSecondaryColor),
                                hintText: '1234 5678 9012 3456',
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 19, // 16 digits + 3 spaces
                              onChanged: (value) {
                                final formatted = _formatCardNumber(value);
                                if (formatted != value) {
                                  _cardNumberController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }
                              },
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                final digits = value!.replaceAll(RegExp(r'\D'), '');
                                if (digits.length < 13 || digits.length > 19) {
                                  return 'Invalid card number';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Expiry and CVV
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _expiryController,
                                    style: const TextStyle(color: AppTheme.textPrimaryColor),
                                    decoration: const InputDecoration(
                                      labelText: 'Expiry (MM/YY)',
                                      labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                                      prefixIcon: Icon(Icons.calendar_today, color: AppTheme.textSecondaryColor),
                                      hintText: 'MM/YY',
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 5,
                                    onChanged: (value) {
                                      final formatted = _formatExpiry(value);
                                      if (formatted != value) {
                                        _expiryController.value = TextEditingValue(
                                          text: formatted,
                                          selection: TextSelection.collapsed(offset: formatted.length),
                                        );
                                      }
                                    },
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value!)) {
                                        return 'Format: MM/YY';
                                      }
                                      final parts = value.split('/');
                                      final month = int.tryParse(parts[0]);
                                      if (month == null || month < 1 || month > 12) {
                                        return 'Invalid month';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cvvController,
                                    style: const TextStyle(color: AppTheme.textPrimaryColor),
                                    decoration: const InputDecoration(
                                      labelText: 'CVV',
                                      labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                                      prefixIcon: Icon(Icons.lock, color: AppTheme.textSecondaryColor),
                                    ),
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    maxLength: 4,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (value!.length < 3) return 'Invalid CVV';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Shipping Address Section
                    Card(
                      color: AppTheme.surfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppTheme.accentColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Shipping Address',
                                  style: TextStyle(
                                    color: AppTheme.textPrimaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              style: const TextStyle(color: AppTheme.textPrimaryColor),
                              decoration: const InputDecoration(
                                labelText: 'Full Address',
                                labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                                prefixIcon: Icon(Icons.home, color: AppTheme.textSecondaryColor),
                                hintText: 'Street, City, State, ZIP Code',
                              ),
                              maxLines: 3,
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundColor),
                                ),
                              )
                            : const Text(
                                'Pay Now',
                                style: TextStyle(
                                  color: AppTheme.backgroundColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Security Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock,
                          color: AppTheme.textSecondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your payment is secure and encrypted',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
