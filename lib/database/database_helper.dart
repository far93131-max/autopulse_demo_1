import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../data/car_maintenance_services.dart';

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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

    // Marketplace Tables
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        image_url TEXT,
        stock INTEGER DEFAULT 0,
        brand TEXT,
        rating REAL,
        review_count INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        payment_method TEXT,
        shipping_address TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    // Insert default service types (will be seeded by ServiceGroupService on first access)
    await _insertDefaultServiceTypes(db);
    
    // Insert sample products
    await _insertSampleProducts(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add marketplace tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS products (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          category TEXT NOT NULL,
          price REAL NOT NULL,
          image_url TEXT,
          stock INTEGER DEFAULT 0,
          brand TEXT,
          rating REAL,
          review_count INTEGER,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cart_items (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS orders (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          total REAL NOT NULL,
          status TEXT NOT NULL,
          payment_method TEXT,
          shipping_address TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS order_items (
          id TEXT PRIMARY KEY,
          order_id TEXT NOT NULL,
          product_id TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products(id)
        )
      ''');

      await _insertSampleProducts(db);
    }
  }

  Future<void> _insertSampleProducts(Database db) async {
    final now = dateToTimestamp(DateTime.now());
    final sampleProducts = [
      {
        'id': _uuid.v4(),
        'name': 'Premium Motor Oil 5W-30',
        'description': 'Full synthetic motor oil for optimal engine performance and protection.',
        'category': 'Engine',
        'price': 39.99,
        'brand': 'AutoPro',
        'rating': 4.5,
        'review_count': 234,
        'stock': 50,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Brake Pad Set - Front',
        'description': 'High-performance ceramic brake pads for improved stopping power.',
        'category': 'Brakes',
        'price': 89.99,
        'brand': 'StopSafe',
        'rating': 4.8,
        'review_count': 156,
        'stock': 30,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Car Battery 12V 800CCA',
        'description': 'Long-lasting car battery with 5-year warranty.',
        'category': 'Battery',
        'price': 149.99,
        'brand': 'PowerMax',
        'rating': 4.6,
        'review_count': 89,
        'stock': 25,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Air Filter - Premium',
        'description': 'High-efficiency air filter for cleaner engine air intake.',
        'category': 'Engine',
        'price': 24.99,
        'brand': 'BreathEasy',
        'rating': 4.4,
        'review_count': 312,
        'stock': 75,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Tire Pressure Gauge',
        'description': 'Digital tire pressure gauge with backlit display.',
        'category': 'Tires',
        'price': 19.99,
        'brand': 'CheckIT',
        'rating': 4.7,
        'review_count': 445,
        'stock': 100,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Coolant/Antifreeze 50/50',
        'description': 'Pre-mixed coolant for year-round protection.',
        'category': 'Cooling',
        'price': 34.99,
        'brand': 'FreezeGuard',
        'rating': 4.3,
        'review_count': 178,
        'stock': 60,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Spark Plug Set (4-pack)',
        'description': 'Iridium spark plugs for better fuel economy.',
        'category': 'Engine',
        'price': 54.99,
        'brand': 'Ignite',
        'rating': 4.9,
        'review_count': 567,
        'stock': 40,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Windshield Wiper Blades (Pair)',
        'description': 'All-weather windshield wiper blades with easy installation.',
        'category': 'Accessories',
        'price': 29.99,
        'brand': 'ClearView',
        'rating': 4.5,
        'review_count': 892,
        'stock': 80,
        'created_at': now,
      },
    ];

    final batch = db.batch();
    for (var product in sampleProducts) {
      batch.insert('products', product);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _insertDefaultServiceTypes(Database db) async {
    final groups = CarMaintenanceServices.getServiceGroups();
    final batch = db.batch();

    // Helper function to get icon name
    String? getIconName(String serviceName) {
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
          'icon_name': getIconName(service.name),
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
              'icon_name': getIconName(subItem.name),
            });
          }
        }
      }
    }

    await batch.commit(noResult: true);
  }

  String generateId() => _uuid.v4();

  int dateToTimestamp(DateTime date) => date.millisecondsSinceEpoch;
  DateTime timestampToDate(int timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

