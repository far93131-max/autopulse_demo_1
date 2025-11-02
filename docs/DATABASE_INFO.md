# Database Information

## Current Storage Implementation

Currently, the app uses **SharedPreferences** for local storage. This is a key-value storage system that stores data as JSON strings on the device.

### Storage Locations:

**Data is stored locally on the device:**
- **Android**: `/data/data/com.example.autopulse_demo_1/shared_prefs/`
- **iOS**: In the app's sandbox directory
- **Web**: Browser's localStorage
- **Windows/Mac/Linux**: Platform-specific local storage

### Current Data Storage Keys:

1. **`cars_data`** - All cars stored as JSON array
2. **`selected_car_id`** - Currently selected car ID
3. **`maintenance_logs_data`** - All maintenance logs as JSON array
4. **`service_types_data`** - Service types as JSON array
5. **`is_logged_in`** - Login status
6. **`remember_me`** - Remember me preference
7. **`saved_email`** - Saved email address

### Services:

- **`lib/services/car_service.dart`** - Handles car CRUD operations
- **`lib/services/maintenance_service.dart`** - Handles maintenance logs and service types
- **`lib/services/auth_service.dart`** - Handles authentication state

## Limitations of Current Approach:

1. ❌ No relational database structure
2. ❌ No foreign key constraints
3. ❌ Limited query capabilities
4. ❌ Performance issues with large datasets
5. ❌ No transaction support
6. ❌ Data stored as JSON strings (slower access)

## Recommended: SQLite Database

For a proper database implementation matching your schema, you should use **sqflite** (SQLite for Flutter).

### Would you like me to:

1. ✅ **Keep current SharedPreferences** (Simple, works for small data)
2. ✅ **Implement SQLite database** (Proper database with your schema)
3. ✅ **Show both implementations** (Migration guide)

## Your Schema Design:

Based on your earlier requirements, the database should have:

- `users` table
- `cars` table
- `maintenance_logs` table
- `service_types` table
- `maintenance_rules` table
- `activity_log` table (optional)
- `exports` table (optional)
- `user_settings` table (optional)

**To implement SQLite, I would need to:**
1. Add `sqflite` package to `pubspec.yaml`
2. Create database helper class
3. Create tables based on your schema
4. Migrate services to use SQLite instead of SharedPreferences

Would you like me to implement the SQLite database now?

