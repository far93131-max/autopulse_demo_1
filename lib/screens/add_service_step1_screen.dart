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
  Map<String, bool> _expandedGroups = {}; // Track which groups are expanded
  Map<String, bool> _expandedServices = {}; // Track which services with sub-items are expanded
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
      // Expand first group by default
      if (_serviceGroups.isNotEmpty) {
        _expandedGroups[_serviceGroups.first.id] = true;
      }
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
                // Service groups list
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _getFilteredGroups().length + 1, // +1 for custom service
                          itemBuilder: (context, index) {
                            if (index == _getFilteredGroups().length) {
                              return _buildCustomServiceCard();
                            }
                            
                            final group = _getFilteredGroups()[index];
                            final isExpanded = _expandedGroups[group.id] ?? false;
                            final filteredServices = _getFilteredServices(group);
                            
                            if (filteredServices.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            
                            return _buildGroupCard(group, isExpanded, filteredServices);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupCard(ServiceGroup group, bool isExpanded, List<ServiceItem> services) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: group.color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Group header
          InkWell(
            onTap: () {
              setState(() {
                _expandedGroups[group.id] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: group.color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: group.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.build,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${services.length} service${services.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: group.color,
                  ),
                ],
              ),
            ),
          ),
          // Services list
          if (isExpanded)
            ...services.map((service) => _buildServiceItem(service, group.color, group.name)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(ServiceItem service, Color groupColor, String groupName) {
    final hasSubItems = service.subItems != null && service.subItems!.isNotEmpty;
    final isServiceExpanded = _expandedServices[service.id] ?? false;
    
    return Column(
      children: [
        // Main service item
        InkWell(
          onTap: () {
            if (hasSubItems) {
              // Toggle expansion for services with sub-items
              setState(() {
                _expandedServices[service.id] = !isServiceExpanded;
              });
            } else {
              // Select the service directly
              _selectService(service.name, groupName);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: groupColor,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                if (hasSubItems)
                  Icon(
                    isServiceExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: groupColor,
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: groupColor.withOpacity(0.5),
                  ),
              ],
            ),
          ),
        ),
        // Sub-items
        if (hasSubItems && isServiceExpanded)
          ...service.subItems!.map((subItem) => InkWell(
                onTap: () => _selectService(subItem.name, groupName),
                child: Container(
                  padding: const EdgeInsets.only(left: 32, right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: groupColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: groupColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subItem.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: groupColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildCustomServiceCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _createCustomService,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
