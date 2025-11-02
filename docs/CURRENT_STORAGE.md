# Current Data Storage - SharedPreferences

## 📍 Storage Location

The app currently uses **SharedPreferences**, which stores data as JSON strings on the device:

- **Android**: `/data/data/com.example.autopulse_demo_1/shared_prefs/FlutterSharedPreferences.xml`
- **iOS**: App's Documents directory  
- **Web**: Browser localStorage
- **Desktop**: Platform-specific local storage

## 📦 Current Data Keys

| Key | Data Type | Description |
|-----|-----------|-------------|
| `cars_data` | JSON String | Array of all cars |
| `selected_car_id` | String | Currently selected car ID |
| `maintenance_logs_data` | JSON String | Array of all maintenance logs |
| `service_types_data` | JSON String | Array of service types |
| `is_logged_in` | Boolean | Login status |
| `remember_me` | Boolean | Remember me preference |
| `saved_email` | String | Saved email address |

## ⚠️ Limitations

1. No relational database structure
2. All data loaded into memory at once
3. No foreign key constraints
4. Limited query capabilities
5. Performance degrades with large datasets
6. No transaction support

## 🔄 Your SQL Schema (Not Implemented Yet)

You provided a proper SQL schema earlier with:
- `users` table
- `cars` table  
- `maintenance_logs` table
- `service_types` table
- `maintenance_rules` table
- etc.

This is **NOT currently implemented**. The app uses SharedPreferences instead.

## ✅ Options

1. **Keep SharedPreferences** - Simple, works for small data
2. **Implement SQLite** - Proper database matching your schema (recommended)
3. **Hybrid approach** - SQLite for data, SharedPreferences for settings

Would you like me to implement SQLite database now?

