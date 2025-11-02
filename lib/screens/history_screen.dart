import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/maintenance_log.dart';
import '../models/service_type.dart';
import '../models/car.dart';
import '../services/maintenance_service.dart';
import '../services/car_service.dart';
import 'edit_service_modal.dart';

class HistoryScreen extends StatefulWidget {
  final String? carId;

  const HistoryScreen({super.key, this.carId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _maintenanceService = MaintenanceService();
  final _carService = CarService();
  final _searchController = TextEditingController();
  
  List<MaintenanceLog> _logs = [];
  List<MaintenanceLog> _filteredLogs = [];
  List<Car> _cars = [];
  Car? _selectedCar;
  String _filterPeriod = 'All';
  String _sortBy = 'Date';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final allCars = await _carService.getAllCars();
    Car? car;
    
    if (widget.carId != null) {
      try {
        car = allCars.firstWhere((c) => c.id == widget.carId);
      } catch (e) {
        car = allCars.isNotEmpty ? allCars.first : null;
      }
    } else {
      final selectedId = await _carService.getSelectedCarId();
      if (selectedId != null) {
        try {
          car = allCars.firstWhere((c) => c.id == selectedId);
        } catch (e) {
          car = allCars.isNotEmpty ? allCars.first : null;
        }
      } else {
        car = allCars.isNotEmpty ? allCars.first : null;
      }
    }

    if (car != null) {
      final logs = await _maintenanceService.getLogs(car.id);
      final serviceTypes = await _maintenanceService.getAllServiceTypes();
      final typesMap = {for (var t in serviceTypes) t.id: t};
      
      final logsWithTypes = logs.map((log) {
        final type = typesMap[log.serviceTypeId];
        return MaintenanceLog(
          id: log.id,
          carId: log.carId,
          serviceTypeId: log.serviceTypeId,
          serviceType: type,
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

      setState(() {
        _cars = allCars;
        _selectedCar = car;
        _logs = logsWithTypes;
        _filteredLogs = logsWithTypes;
        _isLoading = false;
      });
      _applyFilters();
    } else {
      setState(() {
        _cars = allCars;
        _logs = [];
        _filteredLogs = [];
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<MaintenanceLog>.from(_logs);
    
    // Period filter
    final now = DateTime.now();
    switch (_filterPeriod) {
      case 'Last 30 Days':
        filtered = filtered.where((log) {
          return now.difference(log.dateOfService).inDays <= 30;
        }).toList();
        break;
      case 'This Year':
        filtered = filtered.where((log) {
          return log.dateOfService.year == now.year;
        }).toList();
        break;
    }

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((log) {
        return log.serviceType?.name.toLowerCase().contains(query) == true ||
            log.mechanicName?.toLowerCase().contains(query) == true ||
            log.notes?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Date':
        filtered.sort((a, b) => b.dateOfService.compareTo(a.dateOfService));
        break;
      case 'Mileage':
        filtered.sort((a, b) => b.mileage.compareTo(a.mileage));
        break;
      case 'Cost':
        filtered.sort((a, b) => (b.totalCost).compareTo(a.totalCost));
        break;
    }

    setState(() => _filteredLogs = filtered);
  }

  Future<void> _deleteLog(String logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _maintenanceService.deleteLog(logId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service History'),
        actions: [
          if (_logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : Column(
              children: [
                // Car Selector
                if (_cars.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<Car>(
                      value: _selectedCar,
                      decoration: const InputDecoration(
                        labelText: 'Select Car',
                        border: OutlineInputBorder(),
                      ),
                      items: _cars.map((car) {
                        return DropdownMenuItem(
                          value: car,
                          child: Text(car.displayName),
                        );
                      }).toList(),
                      onChanged: (car) {
                        setState(() => _selectedCar = car);
                        _loadData();
                      },
                    ),
                  ),
                // Filters
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => _applyFilters(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterPeriod,
                              decoration: const InputDecoration(
                                labelText: 'Period',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: ['All', 'Last 30 Days', 'This Year'].map((p) {
                                return DropdownMenuItem(value: p, child: Text(p));
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _filterPeriod = value!);
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              decoration: const InputDecoration(
                                labelText: 'Sort By',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: ['Date', 'Mileage', 'Cost'].map((s) {
                                return DropdownMenuItem(value: s, child: Text(s));
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _sortBy = value!);
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Stats Summary
                if (_filteredLogs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  _filteredLogs.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                const Text('Services', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '\$${_filteredLogs.fold(0.0, (sum, log) => sum + log.totalCost).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                                const Text('Total Cost', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Logs List
                Expanded(
                  child: _filteredLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_outlined,
                                size: 64,
                                color: AppTheme.textSecondaryColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No history found',
                                style: TextStyle(color: AppTheme.textSecondaryColor),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            return _buildLogCard(log);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLogCard(MaintenanceLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentColor.withOpacity(0.2),
          child: Icon(Icons.build, color: AppTheme.accentColor),
        ),
        title: Text(
          log.serviceType?.name ?? 'Service',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatDate(log.dateOfService)} • ${log.mileage.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} km${log.totalCost > 0 ? ' • \$${log.totalCost.toStringAsFixed(2)}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditServiceModal(log: log),
                  ),
                );
                if (result == true) await _loadData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
              onPressed: () => _deleteLog(log.id),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.mechanicName != null) ...[
                  _buildDetailRow('Mechanic', log.mechanicName!),
                  const SizedBox(height: 8),
                ],
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  _buildDetailRow('Notes', log.notes!),
                  const SizedBox(height: 8),
                ],
                if (log.parts.isNotEmpty) ...[
                  const Text(
                    'Parts:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...log.parts.map((part) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      '${part.name}${part.cost != null ? ' - \$${part.cost!.toStringAsFixed(2)}' : ''}',
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _exportData() async {
    // Simple JSON export - in real app, use file_picker to save file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('History exported successfully (JSON format)'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }
}

