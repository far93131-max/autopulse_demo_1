import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/service_type.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import '../database/database_helper.dart';
import 'add_service_step2_screen.dart';

class AddServiceStep1Screen extends StatefulWidget {
  const AddServiceStep1Screen({super.key});

  @override
  State<AddServiceStep1Screen> createState() => _AddServiceStep1ScreenState();
}

class _AddServiceStep1ScreenState extends State<AddServiceStep1Screen> {
  final _maintenanceService = MaintenanceService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  List<ServiceType> _serviceTypes = [];
  List<ServiceType> _filteredTypes = [];
  String? _selectedCategory;
  bool _isLoading = true;
  String? _userId;

  final Map<String, IconData> _categoryIcons = {
    'Engine': Icons.settings,
    'Brakes': Icons.stop_circle,
    'Tires': Icons.tire_repair,
    'Battery': Icons.battery_charging_full,
    'Cooling': Icons.ac_unit,
    'Transmission': Icons.speed,
    'Suspension': Icons.waves,
    'Fuel': Icons.local_gas_station,
    'Exhaust': Icons.construction,
    'Body': Icons.directions_car,
  };

  final List<String> _categories = [
    'Engine',
    'Brakes',
    'Tires',
    'Battery',
    'Cooling',
    'Transmission',
    'Suspension',
    'Fuel',
    'Exhaust',
    'Body',
  ];

  @override
  void initState() {
    super.initState();
    _loadServiceTypes();
    _searchController.addListener(_filterTypes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceTypes() async {
    _userId = await _authService.getCurrentUserId() ?? await _authService.getSavedEmail() ?? 'default_user';
    
    final types = await _maintenanceService.getServiceTypes(_userId!);
    setState(() {
      _serviceTypes = types;
      _filteredTypes = types;
      _isLoading = false;
    });
  }

  void _filterTypes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTypes = _serviceTypes.where((type) {
        final matchesCategory = _selectedCategory == null || type.category == _selectedCategory;
        final matchesSearch = type.name.toLowerCase().contains(query) ||
            (type.category?.toLowerCase().contains(query) ?? false);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _createCustomService() async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Custom Service',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        Navigator.pop(context, {
                          'name': nameController.text,
                          'category': categoryController.text,
                        });
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && _userId != null) {
      final dbHelper = DatabaseHelper.instance;
      final customType = ServiceType(
        id: dbHelper.generateId(),
        userId: _userId!,
        name: result['name']!,
        category: result['category']?.isNotEmpty == true ? result['category'] : null,
        isCustom: true,
      );
      await _maintenanceService.saveServiceType(customType);
      await _loadServiceTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Service Type'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterTypes();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                // Category Filter Chips
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = null;
                            _filterTypes();
                          });
                        },
                        selectedColor: AppTheme.accentColor.withOpacity(0.3),
                        checkmarkColor: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 8),
                      ..._categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : null;
                                _filterTypes();
                              });
                            },
                            selectedColor: AppTheme.accentColor.withOpacity(0.3),
                            checkmarkColor: AppTheme.accentColor,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredTypes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppTheme.textSecondaryColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No services found',
                                style: TextStyle(color: AppTheme.textSecondaryColor),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _filteredTypes.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _filteredTypes.length) {
                              return _buildCategoryCard(
                                'Custom Service',
                                Icons.add_circle_outline,
                                () => _createCustomService(),
                              );
                            }
                            final type = _filteredTypes[index];
                            return _buildCategoryCard(
                              type.name,
                              _categoryIcons[type.category] ?? Icons.build,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddServiceStep2Screen(serviceType: type),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.accentColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

