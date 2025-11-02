# User Information Storage

## 📍 Where User Information is Stored

User information is stored in **TWO places**:

### 1. **SQLite Database - `users` table** (Primary Storage)

**Location:** `lib/database/database_helper.dart` creates the table  
**Database File:** `autocare.db` on device

**Table Structure:**
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  full_name TEXT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  language_preference TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

**Physical Location:**
- **Android**: `/data/data/com.example.autopulse_demo_1/databases/autocare.db`
- **iOS**: App's Documents directory
- **Desktop**: Platform-specific app data directory

**Stored Information:**
- ✅ User ID (UUID)
- ✅ Full Name
- ✅ Email (unique)
- ✅ Password Hash
- ✅ Language Preference
- ✅ Created/Updated timestamps

**Operations:**
- **Created during**: Signup (via `AuthService.signup()`)
- **Read during**: Login, user lookup
- **Location**: `lib/services/auth_service.dart`

---

### 2. **SharedPreferences** (Session/Temporary Storage)

**Used for:**
- Login session state (`is_logged_in`)
- Current user ID (`user_id`) 
- Remember me preference
- Saved email (if "Remember me" is checked)

**NOT used for:**
- User profile data
- Full user information
- Password storage

**Keys:**
- `is_logged_in` - Boolean
- `user_id` - String (UUID)
- `remember_me` - Boolean
- `saved_email` - String

---

## 🔍 Code Locations

### User Creation:
**File:** `lib/services/auth_service.dart`
- Line 155-162: New user inserted into `users` table during signup
- Line 35-42: Demo users auto-created on first login

### User Retrieval:
**File:** `lib/services/auth_service.dart`
- Line 67-72: Login queries `users` table by email
- Line 54-57: Gets current user ID from SharedPreferences

### User Table Schema:
**File:** `lib/database/database_helper.dart`
- Line 31-41: `users` table creation SQL

---

## 📊 Data Flow

```
Signup → SQLite (users table) → SharedPreferences (session)
Login → SQLite (users table) → SharedPreferences (session)
```

1. **Signup**: Creates user record in SQLite `users` table
2. **Login**: Queries SQLite `users` table, saves session to SharedPreferences
3. **Session**: User ID stored in SharedPreferences for quick access
4. **Profile**: All user data persists in SQLite database

---

## 🔑 Important Notes

- ✅ **User data**: Stored permanently in SQLite `users` table
- ✅ **Session data**: Stored temporarily in SharedPreferences
- ✅ **Password**: Currently stored as plain text (should be hashed in production)
- ✅ **User ID**: Generated as UUID using `DatabaseHelper.generateId()`

---

## 📝 Example User Record

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "full_name": "John Doe",
  "email": "john@example.com",
  "password_hash": "password123",
  "language_preference": null,
  "created_at": 1704067200000,
  "updated_at": 1704067200000
}
```

This record is stored in SQLite database file: `autocare.db` → `users` table

