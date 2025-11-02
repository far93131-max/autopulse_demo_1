import 'package:sqflite/sqflite.dart';
import '../models/maintenance_log.dart';
import '../models/service_type.dart';
import '../database/database_helper.dart';

class MaintenanceService {
  final _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  // Service Types
  Future<List<ServiceType>> getServiceTypes(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'service_types',
      where: 'user_id = ? OR user_id IS NULL',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    if (maps.isEmpty) {
      // Default types should already be inserted by database helper
      return await getServiceTypes(userId);
    }

    return maps.map((map) => _mapToServiceType(map)).toList();
  }

  Future<void> saveServiceType(ServiceType type) async {
    final db = await _db;
    await db.insert(
      'service_types',
      _serviceTypeToMap(type),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ServiceType>> getAllServiceTypes() async {
    final db = await _db;
    final maps = await db.query('service_types', orderBy: 'name ASC');
    return maps.map((map) => _mapToServiceType(map)).toList();
  }

  // Maintenance Logs
  Future<List<MaintenanceLog>> getLogs(String carId) async {
    final db = await _db;
    final maps = await db.query(
      'maintenance_logs',
      where: 'car_id = ?',
      whereArgs: [carId],
      orderBy: 'date_of_service DESC',
    );

    final logs = <MaintenanceLog>[];
    for (var map in maps) {
      final log = await _mapToMaintenanceLog(map);
      logs.add(log);
    }

    return logs;
  }

  Future<List<MaintenanceLog>> getAllLogs() async {
    final db = await _db;
    final maps = await db.query('maintenance_logs', orderBy: 'date_of_service DESC');

    final logs = <MaintenanceLog>[];
    for (var map in maps) {
      final log = await _mapToMaintenanceLog(map);
      logs.add(log);
    }

    return logs;
  }

  Future<void> saveLog(MaintenanceLog log) async {
    final db = await _db;
    
    await db.transaction((txn) async {
      // Insert or update maintenance log
      await txn.insert(
        'maintenance_logs',
        _maintenanceLogToMap(log),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Delete existing parts
      await txn.delete(
        'service_parts',
        where: 'maintenance_log_id = ?',
        whereArgs: [log.id],
      );

      // Insert new parts
      for (var part in log.parts) {
        await txn.insert('service_parts', {
          'id': part.id,
          'maintenance_log_id': log.id,
          'name': part.name,
          'cost': part.cost,
        });
      }
    });
  }

  Future<void> deleteLog(String logId) async {
    final db = await _db;
    // Parts will be deleted automatically due to CASCADE
    await db.delete(
      'maintenance_logs',
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  Future<List<MaintenanceLog>> searchLogs(String carId, String query) async {
    final db = await _db;
    final lowerQuery = '%${query.toLowerCase()}%';
    final maps = await db.query(
      'maintenance_logs',
      where: 'car_id = ? AND (notes LIKE ? OR mechanic_name LIKE ?)',
      whereArgs: [carId, lowerQuery, lowerQuery],
      orderBy: 'date_of_service DESC',
    );

    final logs = <MaintenanceLog>[];
    for (var map in maps) {
      final log = await _mapToMaintenanceLog(map);
      // Also check service type name
      if (log.serviceType?.name.toLowerCase().contains(query.toLowerCase()) == true) {
        logs.add(log);
      }
    }

    return logs;
  }

  Map<String, dynamic> _serviceTypeToMap(ServiceType type) {
    return {
      'id': type.id,
      'user_id': type.userId.isEmpty ? null : type.userId,
      'name': type.name,
      'category': type.category,
      'is_custom': type.isCustom ? 1 : 0,
      'icon_name': type.iconName,
    };
  }

  ServiceType _mapToServiceType(Map<String, dynamic> map) {
    return ServiceType(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String,
      category: map['category'] as String?,
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
      iconName: map['icon_name'] as String?,
    );
  }

  Map<String, dynamic> _maintenanceLogToMap(MaintenanceLog log) {
    return {
      'id': log.id,
      'car_id': log.carId,
      'service_type_id': log.serviceTypeId,
      'mileage': log.mileage,
      'date_of_service': DatabaseHelper.instance.dateToTimestamp(log.dateOfService),
      'cost': log.cost,
      'mechanic_name': log.mechanicName,
      'notes': log.notes,
      'receipt_url': log.receiptUrl,
      'created_at': DatabaseHelper.instance.dateToTimestamp(log.createdAt),
    };
  }

  Future<MaintenanceLog> _mapToMaintenanceLog(Map<String, dynamic> map) async {
    final db = await _db;
    
    // Get service type
    ServiceType? serviceType;
    if (map['service_type_id'] != null) {
      final typeMaps = await db.query(
        'service_types',
        where: 'id = ?',
        whereArgs: [map['service_type_id']],
        limit: 1,
      );
      if (typeMaps.isNotEmpty) {
        serviceType = _mapToServiceType(typeMaps.first);
      }
    }

    // Get parts
    final partMaps = await db.query(
      'service_parts',
      where: 'maintenance_log_id = ?',
      whereArgs: [map['id']],
    );
    final parts = partMaps.map((partMap) => ServicePart(
      id: partMap['id'] as String,
      name: partMap['name'] as String,
      cost: partMap['cost'] as double?,
    )).toList();

    return MaintenanceLog(
      id: map['id'] as String,
      carId: map['car_id'] as String,
      serviceTypeId: map['service_type_id'] as String,
      serviceType: serviceType,
      mileage: map['mileage'] as int,
      dateOfService: DatabaseHelper.instance.timestampToDate(map['date_of_service'] as int),
      cost: map['cost'] as double?,
      mechanicName: map['mechanic_name'] as String?,
      notes: map['notes'] as String?,
      receiptUrl: map['receipt_url'] as String?,
      parts: parts,
      createdAt: DatabaseHelper.instance.timestampToDate(map['created_at'] as int),
    );
  }
}
