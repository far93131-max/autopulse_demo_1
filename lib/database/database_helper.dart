import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final _uuid = const Uuid();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('autocare.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT,
        language_preference TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Cars Table
    await db.execute('''
      CREATE TABLE cars (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        nickname TEXT,
        make TEXT,
        model TEXT,
        year INTEGER,
        license_plate TEXT,
        vin TEXT,
        image_url TEXT,
        current_mileage INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Service Types Table
    await db.execute('''
      CREATE TABLE service_types (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        category TEXT,
        is_custom INTEGER DEFAULT 1,
        icon_name TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Maintenance Logs Table
    await db.execute('''
      CREATE TABLE maintenance_logs (
        id TEXT PRIMARY KEY,
        car_id TEXT NOT NULL,
        service_type_id TEXT,
        mileage INTEGER NOT NULL,
        date_of_service INTEGER NOT NULL,
        cost REAL,
        mechanic_name TEXT,
        notes TEXT,
        receipt_url TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
        FOREIGN KEY (service_type_id) REFERENCES service_types(id)
      )
    ''');

    // Service Parts Table (for maintenance log parts)
    await db.execute('''
      CREATE TABLE service_parts (
        id TEXT PRIMARY KEY,
        maintenance_log_id TEXT NOT NULL,
        name TEXT NOT NULL,
        cost REAL,
        FOREIGN KEY (maintenance_log_id) REFERENCES maintenance_logs(id) ON DELETE CASCADE
      )
    ''');

    // Maintenance Rules Table
    await db.execute('''
      CREATE TABLE maintenance_rules (
        id TEXT PRIMARY KEY,
        car_id TEXT NOT NULL,
        service_type_id TEXT,
        interval_km INTEGER,
        interval_days INTEGER,
        last_service_id TEXT,
        next_due_km INTEGER,
        next_due_date INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
        FOREIGN KEY (service_type_id) REFERENCES service_types(id),
        FOREIGN KEY (last_service_id) REFERENCES maintenance_logs(id)
      )
    ''');

    // Exports Table
    await db.execute('''
      CREATE TABLE exports (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        export_type TEXT CHECK (export_type IN ('pdf', 'json')),
        car_id TEXT,
        export_data TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (car_id) REFERENCES cars(id)
      )
    ''');

    // Activity Log Table
    await db.execute('''
      CREATE TABLE activity_log (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        action TEXT,
        context TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // User Settings Table
    await db.execute('''
      CREATE TABLE user_settings (
        user_id TEXT PRIMARY KEY,
        theme TEXT DEFAULT 'dark',
        preferred_units TEXT DEFAULT 'km',
        notifications_enabled INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Insert default service types
    await _insertDefaultServiceTypes(db);
  }

  Future<void> _insertDefaultServiceTypes(Database db) async {
    final defaultTypes = [
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Oil Change', 'category': 'Engine', 'is_custom': 0, 'icon_name': 'oil'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Tire Rotation', 'category': 'Tires', 'is_custom': 0, 'icon_name': 'tire'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Brake Service', 'category': 'Brakes', 'is_custom': 0, 'icon_name': 'brake'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Battery Check', 'category': 'Battery', 'is_custom': 0, 'icon_name': 'battery'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Coolant Flush', 'category': 'Cooling', 'is_custom': 0, 'icon_name': 'coolant'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Transmission Service', 'category': 'Transmission', 'is_custom': 0, 'icon_name': 'transmission'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Suspension Check', 'category': 'Suspension', 'is_custom': 0, 'icon_name': 'suspension'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Fuel Filter', 'category': 'Fuel', 'is_custom': 0, 'icon_name': 'fuel'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Exhaust Check', 'category': 'Exhaust', 'is_custom': 0, 'icon_name': 'exhaust'},
      {'id': _uuid.v4(), 'user_id': null, 'name': 'Body Repair', 'category': 'Body', 'is_custom': 0, 'icon_name': 'body'},
    ];

    final batch = db.batch();
    for (var type in defaultTypes) {
      batch.insert('service_types', type);
    }
    await batch.commit(noResult: true);
  }

  String generateId() => _uuid.v4();

  int dateToTimestamp(DateTime date) => date.millisecondsSinceEpoch;
  DateTime timestampToDate(int timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

