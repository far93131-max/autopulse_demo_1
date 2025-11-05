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
  // This method ensures all services are in the database, updating existing ones if needed
  Future<void> seedPredefinedServices() async {
    final db = await _db;
    final groups = getServiceGroups();
    
    // Get all existing service names for comparison (since UUIDs are generated dynamically)
    final existingServices = await db.query(
      'service_types',
      where: 'user_id IS NULL AND is_custom = 0',
      columns: ['id', 'name', 'category'],
    );
    final existingNames = existingServices.map((e) => e['name'] as String).toSet();
    final existingMap = <String, Map<String, dynamic>>{};
    for (var service in existingServices) {
      existingMap[service['name'] as String] = service;
    }
    
    final batch = db.batch();
    int newServicesCount = 0;
    int updatedServicesCount = 0;

    // Insert or update all services from all groups
    for (var group in groups) {
      for (var service in group.services) {
        final serviceData = {
          'user_id': null,
          'name': service.name,
          'category': group.name,
          'is_custom': 0,
          'icon_name': _getIconNameForService(service.name),
        };
        
        if (existingNames.contains(service.name)) {
          // Update existing service (keep existing ID)
          final existingService = existingMap[service.name]!;
          final existingId = existingService['id'] as String;
          batch.update(
            'service_types',
            serviceData,
            where: 'id = ?',
            whereArgs: [existingId],
          );
          updatedServicesCount++;
        } else {
          // Insert new service
          final serviceDataWithId = {
            'id': service.id,
            ...serviceData,
          };
          batch.insert('service_types', serviceDataWithId);
          newServicesCount++;
        }

        // Insert or update sub-items if they exist
        if (service.subItems != null) {
          for (var subItem in service.subItems!) {
            final subItemData = {
              'user_id': null,
              'name': subItem.name,
              'category': group.name,
              'is_custom': 0,
              'icon_name': _getIconNameForService(subItem.name),
            };
            
            if (existingNames.contains(subItem.name)) {
              // Update existing sub-item (keep existing ID)
              final existingSubItem = existingMap[subItem.name]!;
              final existingSubItemId = existingSubItem['id'] as String;
              batch.update(
                'service_types',
                subItemData,
                where: 'id = ?',
                whereArgs: [existingSubItemId],
              );
              updatedServicesCount++;
            } else {
              // Insert new sub-item
              final subItemDataWithId = {
                'id': subItem.id,
                ...subItemData,
              };
              batch.insert('service_types', subItemDataWithId);
              newServicesCount++;
            }
          }
        }
      }
    }

    await batch.commit(noResult: true);
    
    // Optional: Log the seeding results
    if (newServicesCount > 0 || updatedServicesCount > 0) {
      print('Service seeding completed: $newServicesCount new services, $updatedServicesCount updated');
    }
  }
  
  // Verify all services are in the database and return missing ones
  Future<Map<String, List<String>>> verifyServicesInDatabase() async {
    final db = await _db;
    final groups = getServiceGroups();
    final missingServices = <String, List<String>>{};
    
    // Get all existing service names
    final existingServices = await db.query(
      'service_types',
      where: 'user_id IS NULL AND is_custom = 0',
      columns: ['name'],
    );
    final existingNames = existingServices.map((e) => e['name'] as String).toSet();
    
    // Check each group
    for (var group in groups) {
      final missingInGroup = <String>[];
      
      for (var service in group.services) {
        if (!existingNames.contains(service.name)) {
          missingInGroup.add(service.name);
        }
        
        // Check sub-items
        if (service.subItems != null) {
          for (var subItem in service.subItems!) {
            if (!existingNames.contains(subItem.name)) {
              missingInGroup.add(subItem.name);
            }
          }
        }
      }
      
      if (missingInGroup.isNotEmpty) {
        missingServices[group.name] = missingInGroup;
      }
    }
    
    return missingServices;
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

