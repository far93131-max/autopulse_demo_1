import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../database/database_helper.dart';
import 'home_screen.dart';

class SignupStep2Screen extends StatefulWidget {
  final String fullName;
  final String email;

  const SignupStep2Screen({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vinController = TextEditingController();
  final List<Map<String, String>> _cars = [];
  bool _isLoading = false;
  final _carService = CarService();
  final _authService = AuthService();

  @override
  void dispose() {
    _carModelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  void _addCar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cars.add({
        'model': _carModelController.text.trim(),
        'year': _yearController.text.trim(),
        'licensePlate': _licensePlateController.text.trim(),
        'vin': _vinController.text.trim(),
      });

      _carModelController.clear();
      _yearController.clear();
      _licensePlateController.clear();
      _vinController.clear();
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleFinish() async {
    // If no car has been added yet, validate the current form
    if (_cars.isEmpty) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      _addCar();
    }

    setState(() {
      _isLoading = true;
    });

    // Save cars to database
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not found. Please try again.')),
      );
      return;
    }
    
    final dbHelper = DatabaseHelper.instance;
    
    for (final carData in _cars) {
      final parts = carData['model']!.split(' ');
      final make = parts.isNotEmpty ? parts[0] : '';
      final model = parts.length > 1 ? parts.sublist(1).join(' ') : carData['model']!;
      
      final car = Car(
        id: dbHelper.generateId(),
        userId: userId,
        make: make,
        model: model,
        year: int.tryParse(carData['year'] ?? '') ?? DateTime.now().year,
        licensePlate: carData['licensePlate']?.isEmpty == true ? null : carData['licensePlate'],
        vin: carData['vin']?.isEmpty == true ? null : carData['vin'],
        currentMileage: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _carService.saveCar(car);
      
      // Set first car as selected
      if (_cars.indexOf(carData) == 0) {
        await _carService.setSelectedCarId(car.id);
      }
    }

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Car Setup',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Step 2: Add your vehicle information',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 40),
                // Display added cars
                if (_cars.isNotEmpty) ...[
                  ...List.generate(_cars.length, (index) {
                    final car = _cars[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${car['model']} (${car['year']})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                onPressed: () {
                                  setState(() {
                                    _cars.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'License: ${car['licensePlate']}',
                            style: const TextStyle(color: AppTheme.textSecondaryColor),
                          ),
                          if (car['vin']!.isNotEmpty)
                            Text(
                              'VIN: ${car['vin']}',
                              style: const TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                // Car Model Input
                TextFormField(
                  controller: _carModelController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Car Model',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  validator: (value) {
                    // Only require if we're on the first car and haven't added any yet
                    if (_cars.isEmpty && (value == null || value.trim().isEmpty)) {
                      return 'Car model is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Year Input
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    // Only require if we're on the first car and haven't added any yet
                    if (_cars.isEmpty && (value == null || value.trim().isEmpty)) {
                      return 'Year is required';
                    }
                    if (value != null && value.isNotEmpty) {
                      final year = int.tryParse(value);
                      if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                        return 'Please enter a valid year';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // License Plate Input
                TextFormField(
                  controller: _licensePlateController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'License Plate',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) {
                    // Only require if we're on the first car and haven't added any yet
                    if (_cars.isEmpty && (value == null || value.trim().isEmpty)) {
                      return 'License plate is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // VIN Input (optional)
                TextFormField(
                  controller: _vinController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'VIN (Optional)',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 24),
                // Add Car / Add Another Car Button
                if (_cars.isEmpty)
                  OutlinedButton(
                    onPressed: _addCar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentColor,
                      side: const BorderSide(color: AppTheme.accentColor),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add Car'),
                  ),
                if (_cars.isNotEmpty)
                  OutlinedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _addCar();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentColor,
                      side: const BorderSide(color: AppTheme.accentColor),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add Another Car'),
                  ),
                if (_cars.isNotEmpty || (_carModelController.text.isNotEmpty || _yearController.text.isNotEmpty || _licensePlateController.text.isNotEmpty))
                  const SizedBox(height: 16),
                // Finish Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleFinish,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundColor),
                          ),
                        )
                      : Text(
                          _cars.isEmpty ? 'Finish' : 'Complete Setup',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

