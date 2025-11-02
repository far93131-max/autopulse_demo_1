import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/service_type.dart';
import '../models/car.dart';
import '../models/maintenance_log.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../database/database_helper.dart';
import 'add_service_step3_screen.dart';

class AddServiceStep2Screen extends StatefulWidget {
  final ServiceType serviceType;

  const AddServiceStep2Screen({
    super.key,
    required this.serviceType,
  });

  @override
  State<AddServiceStep2Screen> createState() => _AddServiceStep2ScreenState();
}

class _AddServiceStep2ScreenState extends State<AddServiceStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _mechanicController = TextEditingController();
  final _notesController = TextEditingController();
  final _partNameController = TextEditingController();
  final _partCostController = TextEditingController();

  final _carService = CarService();
  
  DateTime _serviceDate = DateTime.now();
  final List<ServicePart> _parts = [];
  Car? _selectedCar;

  @override
  void initState() {
    super.initState();
    _loadSelectedCar();
  }

  Future<void> _loadSelectedCar() async {
    final selectedCarId = await _carService.getSelectedCarId();
    if (selectedCarId != null) {
      final car = await _carService.getCar(selectedCarId);
      setState(() {
        _selectedCar = car;
        if (car != null) {
          _mileageController.text = car.currentMileage.toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _mechanicController.dispose();
    _notesController.dispose();
    _partNameController.dispose();
    _partCostController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _serviceDate = picked);
    }
  }

  void _addPart() {
    if (_partNameController.text.isNotEmpty) {
      setState(() {
        _parts.add(ServicePart(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _partNameController.text,
          cost: double.tryParse(_partCostController.text),
        ));
        _partNameController.clear();
        _partCostController.clear();
      });
    }
  }

  void _removePart(int index) {
    setState(() => _parts.removeAt(index));
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car first')),
      );
      return;
    }

    final dbHelper = DatabaseHelper.instance;
    final log = MaintenanceLog(
      id: dbHelper.generateId(),
      carId: _selectedCar!.id,
      serviceTypeId: widget.serviceType.id,
      mileage: int.parse(_mileageController.text),
      dateOfService: _serviceDate,
      cost: double.tryParse(_costController.text),
      mechanicName: _mechanicController.text.isEmpty ? null : _mechanicController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      parts: _parts,
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceStep3Screen(
          serviceType: widget.serviceType,
          log: log,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedCar == null)
                Card(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Please select a car in Settings first',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mileage (km) *',
                  prefixIcon: Icon(Icons.speed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mileage is required';
                  }
                  final mileage = int.tryParse(value);
                  if (mileage == null || mileage < 0) {
                    return 'Please enter a valid mileage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Service',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_serviceDate.day}/${_serviceDate.month}/${_serviceDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost (optional)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mechanicController,
                decoration: const InputDecoration(
                  labelText: 'Mechanic / Service Center',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Add Parts (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _partNameController,
                      decoration: const InputDecoration(
                        labelText: 'Part Name',
                        hintText: 'e.g., Oil Filter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _partCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cost',
                        hintText: '\$',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: AppTheme.accentColor,
                    onPressed: _addPart,
                  ),
                ],
              ),
              if (_parts.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._parts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final part = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(part.name),
                      subtitle: part.cost != null
                          ? Text('\$${part.cost!.toStringAsFixed(2)}')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        onPressed: () => _removePart(index),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _handleNext,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

