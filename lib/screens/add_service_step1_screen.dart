import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/service_type.dart';
import '../models/service_group.dart';
import '../services/maintenance_service.dart';
import '../services/service_group_service.dart';
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
  final _serviceGroupService = ServiceGroupService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  List<ServiceGroup> _serviceGroups = [];
  List<ServiceType> _serviceTypesMap = []; // Map from database for navigation
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    
    // Ensure services are seeded
    await _serviceGroupService.seedPredefinedServices();
    
    // Get service groups with colors
    final groups = _serviceGroupService.getServiceGroups();
    
    // Get service types from database for navigation
    _userId = await _authService.getCurrentUserId() ?? await _authService.getSavedEmail() ?? 'default_user';
    final types = await _maintenanceService.getServiceTypes(_userId!);
    
    setState(() {
      _serviceGroups = groups;
      _serviceTypesMap = types;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    setState(() {
      // Filtering will be handled in build method
    });
  }

  List<ServiceGroup> _getFilteredGroups() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      return _serviceGroups;
    }
    
    // Filter groups that have matching services
    return _serviceGroups.where((group) {
      return group.services.any((service) {
        final serviceMatches = service.name.toLowerCase().contains(query);
        final subItemMatches = service.subItems?.any(
          (subItem) => subItem.name.toLowerCase().contains(query)
        ) ?? false;
        return serviceMatches || subItemMatches;
      });
    }).toList();
  }

  List<ServiceItem> _getFilteredServices(ServiceGroup group) {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      return group.services;
    }
    
    return group.services.where((service) {
      final serviceMatches = service.name.toLowerCase().contains(query);
      final subItemMatches = service.subItems?.any(
        (subItem) => subItem.name.toLowerCase().contains(query)
      ) ?? false;
      return serviceMatches || subItemMatches;
    }).toList();
  }

  ServiceType? _findServiceType(String serviceName) {
    try {
      return _serviceTypesMap.firstWhere(
        (type) => type.name == serviceName,
      );
    } catch (e) {
      return null;
    }
  }

  void _selectService(String serviceName, String? groupName) {
    final serviceType = _findServiceType(serviceName);
    
    if (serviceType == null || serviceType.id.isEmpty) {
      // Service not found in database, create it on the fly
      _showServiceNotFoundDialog(serviceName, groupName);
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceStep2Screen(serviceType: serviceType),
      ),
    );
  }

  void _handleServiceTap(ServiceItem service, String groupName, Color groupColor) {
    // If service has sub-items, show bottom sheet
    if (service.subItems != null && service.subItems!.isNotEmpty) {
      _showSubItemsBottomSheet(service, groupName, groupColor);
    } else {
      // Select the service directly
      _selectService(service.name, groupName);
    }
  }

  void _showSubItemsBottomSheet(ServiceItem service, String groupName, Color groupColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getServiceIcon(service.name),
                    color: groupColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Select option',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sub-items list
            ...service.subItems!.map((subItem) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: groupColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getServiceIcon(subItem.name),
                  color: groupColor,
                  size: 20,
                ),
              ),
              title: Text(
                subItem.name,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: groupColor,
              ),
              onTap: () {
                Navigator.pop(context);
                _selectService(subItem.name, groupName);
              },
            )),
            const SizedBox(height: 8),
            // Option to select parent service
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: groupColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: groupColor,
                  size: 20,
                ),
              ),
              title: const Text(
                'Select general service',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: groupColor,
              ),
              onTap: () {
                Navigator.pop(context);
                _selectService(service.name, groupName);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    final lowerName = serviceName.toLowerCase();
    
    // Engine & Oil
    if (lowerName.contains('oil')) return Icons.oil_barrel;
    if (lowerName.contains('filter')) return Icons.filter_alt;
    if (lowerName.contains('spark')) return Icons.electric_bolt;
    if (lowerName.contains('engine')) return Icons.engineering;
    
    // Brakes
    if (lowerName.contains('brake')) return Icons.stop_circle;
    if (lowerName.contains('pad')) return Icons.disc_full;
    
    // Tires & Wheels
    if (lowerName.contains('tire') || lowerName.contains('wheel')) return Icons.tire_repair;
    if (lowerName.contains('alignment')) return Icons.straighten;
    if (lowerName.contains('balance')) return Icons.balance;
    
    // Battery & Electrical
    if (lowerName.contains('battery')) return Icons.battery_charging_full;
    if (lowerName.contains('alternator')) return Icons.power;
    if (lowerName.contains('starter')) return Icons.play_circle;
    if (lowerName.contains('fuse')) return Icons.electric_meter;
    
    // Cooling System
    if (lowerName.contains('coolant') || lowerName.contains('cooling')) return Icons.water_drop;
    if (lowerName.contains('radiator')) return Icons.ac_unit;
    if (lowerName.contains('thermostat')) return Icons.device_thermostat;
    if (lowerName.contains('water pump')) return Icons.water;
    
    // Transmission
    if (lowerName.contains('transmission')) return Icons.speed;
    if (lowerName.contains('clutch')) return Icons.settings;
    
    // Suspension & Steering
    if (lowerName.contains('suspension') || lowerName.contains('shock')) return Icons.waves;
    if (lowerName.contains('steering')) return Icons.settings;
    
    // Fuel System
    if (lowerName.contains('fuel')) return Icons.local_gas_station;
    if (lowerName.contains('injector')) return Icons.settings;
    
    // Exhaust
    if (lowerName.contains('exhaust') || lowerName.contains('muffler')) return Icons.build;
    if (lowerName.contains('catalytic')) return Icons.eco;
    
    // HVAC
    if (lowerName.contains('ac') || lowerName.contains('hvac')) return Icons.ac_unit;
    if (lowerName.contains('cabin filter')) return Icons.air;
    if (lowerName.contains('heater')) return Icons.heat_pump;
    
    // Diagnostics
    if (lowerName.contains('diagnostic') || lowerName.contains('scan') || lowerName.contains('obd')) return Icons.bug_report;
    if (lowerName.contains('check engine')) return Icons.warning;
    
    // Body & Glass
    if (lowerName.contains('wiper')) return Icons.water_drop;
    if (lowerName.contains('light') || lowerName.contains('bulb')) return Icons.lightbulb;
    if (lowerName.contains('windshield') || lowerName.contains('glass')) return Icons.window;
    if (lowerName.contains('body')) return Icons.car_repair;
    
    // Default
    return Icons.build_circle;
  }

  void _showServiceNotFoundDialog(String serviceName, String? groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Service Not Found'),
        content: Text('Service "$serviceName" is not available in the database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      await _loadServices();
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
                // Search bar
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
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                // Service groups with icon grid
                Expanded(
                  child: _getFilteredGroups().isEmpty
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
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _getFilteredGroups().length + 1, // +1 for custom service
                          itemBuilder: (context, index) {
                            if (index == _getFilteredGroups().length) {
                              return _buildCustomServiceIcon();
                            }
                            
                            final group = _getFilteredGroups()[index];
                            final filteredServices = _getFilteredServices(group);
                            
                            if (filteredServices.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            
                            return _buildGroupSection(group, filteredServices);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupSection(ServiceGroup group, List<ServiceItem> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: group.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: group.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: group.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${services.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        // Services grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceIconCard(service, group.color, group.name);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildServiceIconCard(ServiceItem service, Color groupColor, String groupName) {
    final hasSubItems = service.subItems != null && service.subItems!.isNotEmpty;
    
    return InkWell(
      onTap: () => _handleServiceTap(service, groupName, groupColor),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: groupColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: groupColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getServiceIcon(service.name),
                color: groupColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                service.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasSubItems)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: groupColor.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomServiceIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: _createCustomService,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Create Custom Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
