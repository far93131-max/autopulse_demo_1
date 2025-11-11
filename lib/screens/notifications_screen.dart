import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../services/maintenance_service.dart';
import '../models/car.dart';
import '../models/maintenance_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _carService = CarService();
  final _maintenanceService = MaintenanceService();
  final _authService = AuthService();
  
  bool _notificationsEnabled = true;
  bool _overdueAlerts = true;
  bool _dueSoonAlerts = true;
  bool _upcomingAlerts = true;
  bool _weeklyReminders = true;
  bool _emailNotifications = false;
  
  int _daysBeforeDue = 30;
  int _kmBeforeDue = 2000;
  
  Car? _selectedCar;
  List<Car> _cars = [];
  List<MaintenanceLog> _allLogs = [];
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadNotifications();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _overdueAlerts = prefs.getBool('overdue_alerts') ?? true;
      _dueSoonAlerts = prefs.getBool('due_soon_alerts') ?? true;
      _upcomingAlerts = prefs.getBool('upcoming_alerts') ?? true;
      _weeklyReminders = prefs.getBool('weekly_reminders') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _daysBeforeDue = prefs.getInt('days_before_due') ?? 30;
      _kmBeforeDue = prefs.getInt('km_before_due') ?? 2000;
    });
  }

  Future<void> _saveSettings({bool showMessage = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('overdue_alerts', _overdueAlerts);
    await prefs.setBool('due_soon_alerts', _dueSoonAlerts);
    await prefs.setBool('upcoming_alerts', _upcomingAlerts);
    await prefs.setBool('weekly_reminders', _weeklyReminders);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setInt('days_before_due', _daysBeforeDue);
    await prefs.setInt('km_before_due', _kmBeforeDue);
    
    if (showMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved'),
          backgroundColor: AppTheme.accentColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    _userId = await _authService.getCurrentUserId() ?? await _authService.getSavedEmail() ?? 'default_user';
    final cars = await _carService.getCars(_userId!);
    final selectedCarId = await _carService.getSelectedCarId();
    
    Car? selectedCar;
    if (selectedCarId != null && cars.isNotEmpty) {
      try {
        selectedCar = cars.firstWhere((car) => car.id == selectedCarId);
      } catch (e) {
        selectedCar = cars.isNotEmpty ? cars.first : null;
      }
    } else if (cars.isNotEmpty) {
      selectedCar = cars.first;
    }

    List<MaintenanceLog> logs = [];
    if (selectedCar != null) {
      logs = await _maintenanceService.getLogs(selectedCar.id);
    }

    final serviceLogs = logs.where((log) {
      return log.serviceTypeId != MaintenanceService.mileageUpdateServiceTypeId &&
          log.serviceTypeId != MaintenanceService.mileageUpdateWarningServiceTypeId;
    }).toList();

    setState(() {
      _cars = cars;
      _selectedCar = selectedCar;
      _allLogs = serviceLogs;
      _isLoading = false;
    });
  }

  int _getNotificationCount() {
    if (_selectedCar == null) return 0;
    
    int count = 0;
    for (var log in _allLogs) {
      final nextDueKm = log.mileage + 10000;
      final nextDueDate = log.dateOfService.add(const Duration(days: 180));
      final kmUntil = nextDueKm - _selectedCar!.currentMileage;
      final daysUntil = nextDueDate.difference(DateTime.now()).inDays;
      
      if (kmUntil < 0 || daysUntil < 0) {
        if (_overdueAlerts) count++;
      } else if (kmUntil <= _kmBeforeDue || daysUntil <= _daysBeforeDue) {
        if (_dueSoonAlerts) count++;
      } else if (kmUntil <= _kmBeforeDue * 2 || daysUntil <= _daysBeforeDue * 2) {
        if (_upcomingAlerts) count++;
      }
    }
    return count;
  }

  ServiceStatus _getServiceStatus(MaintenanceLog log, Car car) {
    final nextDueKm = log.mileage + 10000;
    final nextDueDate = log.dateOfService.add(const Duration(days: 180));
    
    final kmUntilDue = nextDueKm - car.currentMileage;
    final daysUntilDue = nextDueDate.difference(DateTime.now()).inDays;
    
    if (kmUntilDue < 0 || daysUntilDue < 0) return ServiceStatus.overdue;
    if (kmUntilDue <= _kmBeforeDue || daysUntilDue <= _daysBeforeDue) return ServiceStatus.due;
    if (kmUntilDue <= _kmBeforeDue * 2 || daysUntilDue <= _daysBeforeDue * 2) return ServiceStatus.dueSoon;
    return ServiceStatus.ok;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveSettings(showMessage: true),
            tooltip: 'Save settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          _getNotificationCount().toString(),
                          'Active Alerts',
                          AppTheme.errorColor,
                        ),
                        Builder(
                          builder: (_) {
                            if (_allLogs.isEmpty) {
                              return _buildStatItem(
                                '0',
                                'Service Alerts',
                                AppTheme.accentColor,
                              );
                            }
                            return _buildStatItem(
                              _allLogs.length.toString(),
                              'Service Alerts',
                              AppTheme.accentColor,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // General Settings
                  _buildSectionHeader('General Settings'),
                  _buildSwitchTile(
                    title: 'Enable Notifications',
                    subtitle: 'Turn all notifications on/off',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      _saveSettings(showMessage: false);
                    },
                    icon: Icons.notifications,
                  ),
                  const SizedBox(height: 16),
                  
                  // Alert Types
                  if (_notificationsEnabled) ...[
                    _buildSectionHeader('Alert Types'),
                    _buildSwitchTile(
                      title: 'Overdue Alerts',
                      subtitle: 'Notify when services are overdue',
                      value: _overdueAlerts,
                    onChanged: (value) {
                      setState(() => _overdueAlerts = value);
                      _saveSettings(showMessage: false);
                    },
                      icon: Icons.error_outline,
                      iconColor: AppTheme.errorColor,
                    ),
                    _buildSwitchTile(
                      title: 'Due Soon Alerts',
                      subtitle: 'Notify when services are due soon',
                      value: _dueSoonAlerts,
                    onChanged: (value) {
                      setState(() => _dueSoonAlerts = value);
                      _saveSettings(showMessage: false);
                    },
                      icon: Icons.warning_amber,
                      iconColor: Colors.orange,
                    ),
                    _buildSwitchTile(
                      title: 'Upcoming Alerts',
                      subtitle: 'Notify about upcoming services',
                      value: _upcomingAlerts,
                    onChanged: (value) {
                      setState(() => _upcomingAlerts = value);
                      _saveSettings(showMessage: false);
                    },
                      icon: Icons.info_outline,
                      iconColor: AppTheme.accentColor,
                    ),
                    const SizedBox(height: 16),
                    
                    // Alert Thresholds
                    _buildSectionHeader('Alert Thresholds'),
                    _buildSliderTile(
                      title: 'Days Before Due',
                      subtitle: 'Days before service due date to alert',
                      value: _daysBeforeDue.toDouble(),
                      min: 7,
                      max: 90,
                      divisions: 83,
                      onChanged: (value) {
                        setState(() => _daysBeforeDue = value.toInt());
                        _saveSettings(showMessage: false);
                      },
                    ),
                    _buildSliderTile(
                      title: 'KM Before Due',
                      subtitle: 'Kilometers before service due to alert',
                      value: _kmBeforeDue.toDouble(),
                      min: 500,
                      max: 5000,
                      divisions: 45,
                      onChanged: (value) {
                        setState(() => _kmBeforeDue = value.toInt());
                        _saveSettings(showMessage: false);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Reminder Settings
                    _buildSectionHeader('Reminders'),
                    _buildSwitchTile(
                      title: 'Weekly Reminders',
                      subtitle: 'Receive weekly summary of services',
                      value: _weeklyReminders,
                    onChanged: (value) {
                      setState(() => _weeklyReminders = value);
                      _saveSettings(showMessage: false);
                    },
                      icon: Icons.calendar_today,
                    ),
                    _buildSwitchTile(
                      title: 'Email Notifications',
                      subtitle: 'Send notifications via email',
                      value: _emailNotifications,
                    onChanged: (value) {
                      setState(() => _emailNotifications = value);
                      _saveSettings(showMessage: false);
                    },
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Active Notifications List
                  _buildSectionHeader('Active Notifications'),
                  if (_selectedCar == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Please select a car to view notifications',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    )
                  else if (_getNotificationCount() == 0)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No active notifications',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    )
                  else
                    ..._allLogs.where((log) {
                      final status = _getServiceStatus(log, _selectedCar!);
                      if (!_notificationsEnabled) return false;
                      if (status == ServiceStatus.overdue && !_overdueAlerts) return false;
                      if (status == ServiceStatus.due && !_dueSoonAlerts) return false;
                      if (status == ServiceStatus.dueSoon && !_upcomingAlerts) return false;
                      return status != ServiceStatus.ok;
                    }).map((log) => _buildNotificationCard(log)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.accentColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppTheme.accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(MaintenanceLog log) {
    final status = _getServiceStatus(log, _selectedCar!);
    final nextDueKm = log.mileage + 10000;
    final nextDueDate = log.dateOfService.add(const Duration(days: 180));
    final kmUntil = nextDueKm - _selectedCar!.currentMileage;
    final daysUntil = nextDueDate.difference(DateTime.now()).inDays;
    
    String message = '';
    Color color = AppTheme.accentColor;
    IconData icon = Icons.info;
    
    if (status == ServiceStatus.overdue) {
      message = '${log.serviceType?.name ?? "Service"} is overdue';
      color = AppTheme.errorColor;
      icon = Icons.error;
    } else if (status == ServiceStatus.due) {
      message = '${log.serviceType?.name ?? "Service"} is due soon';
      color = Colors.orange;
      icon = Icons.warning;
    } else {
      message = '${log.serviceType?.name ?? "Service"} coming up';
      color = AppTheme.accentColor;
      icon = Icons.info_outline;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kmUntil > 0 && daysUntil > 0
                      ? '$kmUntil KM or $daysUntil days remaining'
                      : 'Overdue - Action needed',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

