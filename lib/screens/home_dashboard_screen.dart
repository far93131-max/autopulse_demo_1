import 'package:flutter/material.dart';
import 'dart:math';
import '../models/car.dart';
import '../models/maintenance_log.dart';
import '../models/service_type.dart';
import '../services/car_service.dart';
import '../services/maintenance_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'add_service_step1_screen.dart';
import 'history_screen.dart';
import 'update_mileage_modal.dart';
import 'more_settings_screen.dart';
import 'notifications_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _carService = CarService();
  final _maintenanceService = MaintenanceService();
  final _authService = AuthService();
  
  Car? _selectedCar;
  List<Car> _cars = [];
  List<MaintenanceLog> _allLogs = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      await _carService.setSelectedCarId(selectedCar.id);
    }

    List<MaintenanceLog> logs = [];
    if (selectedCar != null) {
      final fetchedLogs = await _maintenanceService.getLogs(selectedCar.id);
      final serviceTypes = await _maintenanceService.getServiceTypes(_userId!);
      logs = fetchedLogs.map((log) {
        final serviceType = serviceTypes.firstWhere(
          (st) => st.id == log.serviceTypeId,
          orElse: () => serviceTypes.isNotEmpty ? serviceTypes.first : ServiceType(id: '', userId: '', name: 'Service'),
        );
        return MaintenanceLog(
          id: log.id,
          carId: log.carId,
          serviceTypeId: log.serviceTypeId,
          serviceType: serviceType,
          mileage: log.mileage,
          dateOfService: log.dateOfService,
          cost: log.cost,
          mechanicName: log.mechanicName,
          notes: log.notes,
          receiptUrl: log.receiptUrl,
          parts: log.parts,
          createdAt: log.createdAt,
        );
      }).toList();
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

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _updateMileage(MileageUpdateResult result) async {
    final car = _selectedCar;
    if (car == null) return;

    final newMileage = result.mileage;

    if (newMileage == car.currentMileage) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mileage is already up to date')),
      );
      return;
    }

    await _carService.updateCarMileage(car.id, newMileage);
    await _maintenanceService.logMileageUpdate(
      carId: car.id,
      mileage: newMileage,
      hasWarning: result.hasWarning,
    );
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.hasWarning
              ? 'Mileage updated to $newMileage km (warning acknowledged)'
              : 'Mileage updated to $newMileage km',
        ),
      ),
    );
  }

  ServiceStatus _getServiceStatus(MaintenanceLog log, Car car) {
    final nextDueKm = log.mileage + 10000;
    final nextDueDate = log.dateOfService.add(const Duration(days: 180));
    
    final kmUntilDue = nextDueKm - car.currentMileage;
    final daysUntilDue = nextDueDate.difference(DateTime.now()).inDays;
    
    if (kmUntilDue < 0 || daysUntilDue < 0) return ServiceStatus.overdue;
    if (kmUntilDue < 2000 || daysUntilDue < 60) return ServiceStatus.due;
    if (kmUntilDue < 4000 || daysUntilDue < 90) return ServiceStatus.dueSoon;
    return ServiceStatus.ok;
  }

  Map<String, int> _getStatusCounts() {
    if (_selectedCar == null) return {'ok': 0, 'dueSoon': 0, 'due': 0, 'overdue': 0};
    
    int ok = 0, dueSoon = 0, due = 0, overdue = 0;
    for (var log in _allLogs) {
      final status = _getServiceStatus(log, _selectedCar!);
      switch (status) {
        case ServiceStatus.ok:
          ok++;
          break;
        case ServiceStatus.dueSoon:
          dueSoon++;
          break;
        case ServiceStatus.due:
          due++;
          break;
        case ServiceStatus.overdue:
          overdue++;
          break;
      }
    }
    return {'ok': ok, 'dueSoon': dueSoon, 'due': due, 'overdue': overdue};
  }

  MaintenanceLog? _getNextDueService() {
    if (_selectedCar == null || _allLogs.isEmpty) return null;
    
    MaintenanceLog? next;
    DateTime? earliestDate;
    
    for (var log in _allLogs) {
      final nextDueKm = log.mileage + 10000;
      final nextDueDate = log.dateOfService.add(const Duration(days: 180));
      
      if (earliestDate == null || nextDueDate.isBefore(earliestDate)) {
        earliestDate = nextDueDate;
        next = log;
      }
    }
    
    return next;
  }

  String _formatDueInfo(MaintenanceLog log, Car car) {
    final nextDueKm = log.mileage + 10000;
    final nextDueDate = log.dateOfService.add(const Duration(days: 180));
    
    final kmUntil = nextDueKm - car.currentMileage;
    final daysUntil = nextDueDate.difference(DateTime.now()).inDays;
    
    if (kmUntil < 0 && daysUntil < 0) {
      return 'Overdue';
    }
    
    final kmStr = kmUntil > 0 ? '$kmUntil KM' : 'Overdue';
    final months = (daysUntil / 30).floor();
    final daysStr = months > 0 ? '$months months' : '$daysUntil days';
    
    return '$kmStr or $daysStr';
  }

  int _getNotificationCount() {
    if (_selectedCar == null) return 0;
    
    int count = 0;
    for (var log in _allLogs) {
      final status = _getServiceStatus(log, _selectedCar!);
      if (status == ServiceStatus.overdue || status == ServiceStatus.due) {
        count++;
      }
    }
    return count;
  }

  void _showNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    return;
  }

  void _showNotificationsModal(BuildContext context) {
    if (_selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car first')),
      );
      return;
    }

    final notifications = <Map<String, dynamic>>[];
    
    for (var log in _allLogs) {
      final status = _getServiceStatus(log, _selectedCar!);
      if (status == ServiceStatus.overdue || status == ServiceStatus.due || status == ServiceStatus.dueSoon) {
        final nextDueKm = log.mileage + 10000;
        final nextDueDate = log.dateOfService.add(const Duration(days: 180));
        final kmUntil = nextDueKm - _selectedCar!.currentMileage;
        final daysUntil = nextDueDate.difference(DateTime.now()).inDays;
        
        String message = '';
        Color color = AppTheme.accentColor;
        
        if (status == ServiceStatus.overdue) {
          message = '${log.serviceType?.name ?? "Service"} is overdue';
          color = AppTheme.errorColor;
        } else if (status == ServiceStatus.due) {
          message = '${log.serviceType?.name ?? "Service"} is due soon';
          color = Colors.orange;
        } else {
          message = '${log.serviceType?.name ?? "Service"} coming up';
        }
        
        notifications.add({
          'log': log,
          'message': message,
          'color': color,
          'kmUntil': kmUntil,
          'daysUntil': daysUntil,
        });
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (notifications.isEmpty)
                  const Text(
                    'No notifications',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${notifications.length}',
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'All services are up to date!',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final log = notif['log'] as MaintenanceLog;
                    final message = notif['message'] as String;
                    final color = notif['color'] as Color;
                    final kmUntil = notif['kmUntil'] as int;
                    final daysUntil = notif['daysUntil'] as int;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning_rounded,
                              color: color,
                              size: 20,
                            ),
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
                                      ? '$kmUntil KM or ${daysUntil.toString()} days remaining'
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
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppTheme.surfaceColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.directions_car, size: 48, color: AppTheme.accentColor),
                  const SizedBox(height: 8),
                  Text(
                    'AutoCare',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppTheme.accentColor),
              title: const Text('History', style: TextStyle(color: AppTheme.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HistoryScreen(carId: _selectedCar?.id)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.accentColor),
              title: const Text('Settings', style: TextStyle(color: AppTheme.textPrimaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoreSettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryScreen(carId: _selectedCar?.id)),
            );
          },
        ),
        title: const Text(
          'Home',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotifications(context),
              ),
              if (_getNotificationCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_getNotificationCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.accentColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _selectedCar == null
                    ? _buildEmptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCarCard(),
                          const SizedBox(height: 24),
                          _buildMileageSection(),
                          const SizedBox(height: 24),
                          _buildNextUpCard(),
                          const SizedBox(height: 24),
                          _buildStatusSnapshot(),
                          const SizedBox(height: 24),
                          _buildServiceList(),
                        ],
                      ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddServiceStep1Screen()),
          ).then((_) => _refreshData());
        },
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add, color: AppTheme.backgroundColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No cars added yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first car in Settings',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard() {
    if (_selectedCar == null) return const SizedBox.shrink();

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.surfaceColor,
      ),
      child: Stack(
        children: [
          // Car Image Placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.directions_car,
                size: 120,
                color: AppTheme.accentColor,
              ),
            ),
          ),
          // Car Name Overlay (bottom left of image)
          Positioned(
            left: 16,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCar!.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AUTOCARE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMileageSection() {
    if (_selectedCar == null) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.access_time, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          '${_selectedCar!.currentMileage.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} KM',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () async {
            final result = await showDialog<MileageUpdateResult>(
              context: context,
              builder: (_) => UpdateMileageModal(
                currentMileage: _selectedCar!.currentMileage,
              ),
            );
            if (result != null) {
              await _updateMileage(result);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: AppTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Update KM',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildNextUpCard() {
    final nextService = _getNextDueService();
    if (nextService == null || _selectedCar == null) return const SizedBox.shrink();

    final status = _getServiceStatus(nextService, _selectedCar!);
    final dueInfo = _formatDueInfo(nextService, _selectedCar!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Up:',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextService.serviceType?.name ?? 'Service',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dueInfo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status, small: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSnapshot() {
    final counts = _getStatusCounts();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Snapshot',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildStatusPill('OK', counts['ok']!, Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusPill('Due Soon', counts['dueSoon']!, Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusPill('Due', counts['due']!, Colors.red),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatusPill('Overdue', counts['overdue']!, Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label:$count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildServiceList() {
    if (_selectedCar == null) return const SizedBox.shrink();

    final sortedLogs = List<MaintenanceLog>.from(_allLogs)
      ..sort((a, b) {
        final statusA = _getServiceStatus(a, _selectedCar!);
        final statusB = _getServiceStatus(b, _selectedCar!);
        final priority = {
          ServiceStatus.overdue: 0,
          ServiceStatus.due: 1,
          ServiceStatus.dueSoon: 2,
          ServiceStatus.ok: 3,
        };
        return (priority[statusA] ?? 3).compareTo(priority[statusB] ?? 3);
      });

    if (sortedLogs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.construction_outlined,
                size: 48,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No services logged yet',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next Up',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedLogs.take(5).map((log) {
          final status = _getServiceStatus(log, _selectedCar!);
          final nextDueKm = log.mileage + 10000;
          final nextDueDate = log.dateOfService.add(const Duration(days: 180));
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildStatusBadge(status, small: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.serviceType?.name ?? 'Service',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(nextDueDate)} • ${nextDueKm.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} KM',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddServiceStep1Screen()),
                    ).then((_) => _refreshData());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Log Service',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusBadge(ServiceStatus status, {bool small = false}) {
    late Color color;
    late String text;
    
    switch (status) {
      case ServiceStatus.ok:
        color = Colors.green;
        text = 'OK';
        break;
      case ServiceStatus.dueSoon:
        color = Colors.orange;
        text = 'Due Soon';
        break;
      case ServiceStatus.due:
        color = Colors.red;
        text = 'Due';
        break;
      case ServiceStatus.overdue:
        color = Colors.grey;
        text = 'Overdue';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 10 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
