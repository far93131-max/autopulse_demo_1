import '../data/car_maintenance_services.dart';
import '../models/service_group.dart';
import '../models/service_type.dart';
import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ServiceGroupService {
  final _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  // Get all service groups
  List<ServiceGroup> getServiceGroups() {
    return CarMaintenanceServices.getServiceGroups();
  }

  // Get all services flattened from all groups
  List<ServiceItem> getAllServices() {
    return CarMaintenanceServices.getAllServices();
  }

  // Get a specific service by name
  ServiceItem? getServiceByName(String name) {
    return CarMaintenanceServices.getServiceByName(name);
  }

  // Get the group that contains a specific service
  ServiceGroup? getGroupForService(String serviceName) {
    return CarMaintenanceServices.getGroupForService(serviceName);
  }

  // Seed all predefined services into the database
  Future<void> seedPredefinedServices() async {
    final db = await _db;
    
    // Check if services are already seeded
    final existingServices = await db.query(
      'service_types',
      where: 'user_id IS NULL AND is_custom = 0',
      limit: 1,
    );

    // If services already exist, skip seeding
    if (existingServices.isNotEmpty) {
      return;
    }

    final groups = getServiceGroups();
    final batch = db.batch();

    // Insert all services from all groups
    for (var group in groups) {
      for (var service in group.services) {
        // Insert main service
        batch.insert('service_types', {
          'id': service.id,
          'user_id': null,
          'name': service.name,
          'category': group.name,
          'is_custom': 0,
          'icon_name': _getIconNameForService(service.name),
        });

        // Insert sub-items if they exist
        if (service.subItems != null) {
          for (var subItem in service.subItems!) {
            batch.insert('service_types', {
              'id': subItem.id,
              'user_id': null,
              'name': subItem.name,
              'category': group.name,
              'is_custom': 0,
              'icon_name': _getIconNameForService(subItem.name),
            });
          }
        }
      }
    }

    await batch.commit(noResult: true);
  }

  // Helper method to get icon name based on service name
  String? _getIconNameForService(String serviceName) {
    final lowerName = serviceName.toLowerCase();
    
    if (lowerName.contains('oil')) return 'oil';
    if (lowerName.contains('brake')) return 'brake';
    if (lowerName.contains('tire') || lowerName.contains('wheel')) return 'tire';
    if (lowerName.contains('battery')) return 'battery';
    if (lowerName.contains('coolant') || lowerName.contains('cooling')) return 'coolant';
    if (lowerName.contains('transmission')) return 'transmission';
    if (lowerName.contains('suspension') || lowerName.contains('steering')) return 'suspension';
    if (lowerName.contains('fuel')) return 'fuel';
    if (lowerName.contains('exhaust')) return 'exhaust';
    if (lowerName.contains('ac') || lowerName.contains('hvac')) return 'ac';
    if (lowerName.contains('diagnostic') || lowerName.contains('scan')) return 'diagnostic';
    if (lowerName.contains('body') || lowerName.contains('glass')) return 'body';
    
    return null;
  }

  // Get service types grouped by category from database
  Future<Map<String, List<ServiceType>>> getServiceTypesByGroup() async {
    final db = await _db;
    final maps = await db.query(
      'service_types',
      where: 'user_id IS NULL OR user_id = ?',
      orderBy: 'category ASC, name ASC',
    );

    final grouped = <String, List<ServiceType>>{};
    
    for (var map in maps) {
      final category = map['category'] as String? ?? 'Other';
      final serviceType = ServiceType(
        id: map['id'] as String,
        userId: map['user_id'] as String? ?? '',
        name: map['name'] as String,
        category: category,
        isCustom: (map['is_custom'] as int? ?? 0) == 1,
        iconName: map['icon_name'] as String?,
      );

      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(serviceType);
    }

    return grouped;
  }
}

