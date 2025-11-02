import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'saved_email';
  static const String _userIdKey = 'user_id';

  final _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  // Mock users for demo (these are seeded in the database on first run)
  static const Map<String, String> _mockUsers = {
    'demo@autocare.com': 'password123',
    'user@example.com': 'password123',
  };

  // Initialize demo users if they don't exist
  Future<void> _ensureDemoUsers() async {
    final db = await _db;
    
    for (var entry in _mockUsers.entries) {
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [entry.key],
        limit: 1,
      );
      
      if (existing.isEmpty) {
        final now = DateTime.now();
        await db.insert('users', {
          'id': _dbHelper.generateId(),
          'full_name': entry.key.split('@')[0],
          'email': entry.key,
          'password_hash': entry.value, // In real app, this should be hashed
          'created_at': _dbHelper.dateToTimestamp(now),
          'updated_at': _dbHelper.dateToTimestamp(now),
        });
      }
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Login with email/username and password
  Future<AuthResult> login(String emailOrUsername, String password, {bool rememberMe = false}) async {
    await _ensureDemoUsers();
    
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    final db = await _db;
    final users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [emailOrUsername],
      limit: 1,
    );

    if (users.isEmpty) {
      return AuthResult(
        success: false,
        errorMessage: 'Invalid credentials. Please try again.',
      );
    }

    final user = users.first;
    // In real app, verify password hash
    final storedPassword = user['password_hash'] as String;
    
    if (storedPassword != password && !_mockUsers.containsKey(emailOrUsername)) {
      return AuthResult(
        success: false,
        errorMessage: 'Invalid credentials. Please try again.',
      );
    }

    // Check mock users if not in database
    if (_mockUsers.containsKey(emailOrUsername) && _mockUsers[emailOrUsername] != password) {
      return AuthResult(
        success: false,
        errorMessage: 'Invalid credentials. Please try again.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setBool(_rememberMeKey, rememberMe);
    await prefs.setString(_userIdKey, user['id'] as String);
    
    if (rememberMe) {
      await prefs.setString(_emailKey, emailOrUsername);
    } else {
      await prefs.remove(_emailKey);
    }

    return AuthResult(success: true);
  }

  // Signup
  Future<AuthResult> signup(String fullName, String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Validation
    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      return AuthResult(
        success: false,
        errorMessage: 'All fields are required.',
      );
    }

    if (password.length < 6) {
      return AuthResult(
        success: false,
        errorMessage: 'Password must be at least 6 characters.',
      );
    }

    final db = await _db;
    
    // Check if user already exists
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return AuthResult(
        success: false,
        errorMessage: 'An account with this email already exists.',
      );
    }

    // Create new user
    final now = DateTime.now();
    final userId = _dbHelper.generateId();
    
    await db.insert('users', {
      'id': userId,
      'full_name': fullName,
      'email': email,
      'password_hash': password, // In real app, hash this password
      'created_at': _dbHelper.dateToTimestamp(now),
      'updated_at': _dbHelper.dateToTimestamp(now),
    });

    // Auto-login
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_userIdKey, userId);

    return AuthResult(success: true);
  }

  // Get saved email if remember me is enabled
  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (rememberMe) {
      return prefs.getString(_emailKey);
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userIdKey);
  }

  // Reset password (mock)
  Future<bool> resetPassword(String email) async {
    await _ensureDemoUsers();
    
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    final db = await _db;
    final users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    // Check if email exists
    if (users.isNotEmpty || _mockUsers.containsKey(email)) {
      // In real app, send reset link via email
      return true;
    }
    return false;
  }
}

class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult({required this.success, this.errorMessage});
}
