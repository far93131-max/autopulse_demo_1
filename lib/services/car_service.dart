import 'package:sqflite/sqflite.dart';
import '../models/car.dart';
import '../database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarService {
  static const String _selectedCarKey = 'selected_car_id';
  final _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  Future<List<Car>> getCars(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'cars',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToCar(map)).toList();
  }

  Future<Car?> getCar(String carId) async {
    final db = await _db;
    final maps = await db.query(
      'cars',
      where: 'id = ?',
      whereArgs: [carId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToCar(maps.first);
  }

  Future<List<Car>> getAllCars() async {
    final db = await _db;
    final maps = await db.query('cars', orderBy: 'created_at DESC');
    return maps.map((map) => _mapToCar(map)).toList();
  }

  Future<void> saveCar(Car car) async {
    final db = await _db;
    await db.insert(
      'cars',
      _carToMap(car),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCar(String carId) async {
    final db = await _db;
    await db.delete(
      'cars',
      where: 'id = ?',
      whereArgs: [carId],
    );
  }

  Future<void> updateCarMileage(String carId, int mileage) async {
    final db = await _db;
    await db.update(
      'cars',
      {
        'current_mileage': mileage,
        'updated_at': DatabaseHelper.instance.dateToTimestamp(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [carId],
    );
  }

  Future<String?> getSelectedCarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedCarKey);
  }

  Future<void> setSelectedCarId(String? carId) async {
    final prefs = await SharedPreferences.getInstance();
    if (carId != null) {
      await prefs.setString(_selectedCarKey, carId);
    } else {
      await prefs.remove(_selectedCarKey);
    }
  }

  Map<String, dynamic> _carToMap(Car car) {
    return {
      'id': car.id,
      'user_id': car.userId,
      'nickname': car.nickname,
      'make': car.make,
      'model': car.model,
      'year': car.year,
      'license_plate': car.licensePlate,
      'vin': car.vin,
      'image_url': car.imageUrl,
      'current_mileage': car.currentMileage,
      'created_at': DatabaseHelper.instance.dateToTimestamp(car.createdAt),
      'updated_at': DatabaseHelper.instance.dateToTimestamp(car.updatedAt),
    };
  }

  Car _mapToCar(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      nickname: map['nickname'] as String?,
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      licensePlate: map['license_plate'] as String?,
      vin: map['vin'] as String?,
      imageUrl: map['image_url'] as String?,
      currentMileage: map['current_mileage'] as int? ?? 0,
      createdAt: DatabaseHelper.instance.timestampToDate(map['created_at'] as int),
      updatedAt: DatabaseHelper.instance.timestampToDate(map['updated_at'] as int),
    );
  }
}
