import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/maintenance_log.dart';
import '../services/maintenance_service.dart';

class EditServiceModal extends StatefulWidget {
  final MaintenanceLog log;

  const EditServiceModal({super.key, required this.log});

  @override
  State<EditServiceModal> createState() => _EditServiceModalState();
}

class _EditServiceModalState extends State<EditServiceModal> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _mechanicController = TextEditingController();
  final _notesController = TextEditingController();
  final _maintenanceService = MaintenanceService();

  DateTime _serviceDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mileageController.text = widget.log.mileage.toString();
    _costController.text = widget.log.cost?.toString() ?? '';
    _mechanicController.text = widget.log.mechanicName ?? '';
    _notesController.text = widget.log.notes ?? '';
    _serviceDate = widget.log.dateOfService;
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _mechanicController.dispose();
    _notesController.dispose();
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedLog = MaintenanceLog(
      id: widget.log.id,
      carId: widget.log.carId,
      serviceTypeId: widget.log.serviceTypeId,
      serviceType: widget.log.serviceType,
      mileage: int.parse(_mileageController.text),
      dateOfService: _serviceDate,
      cost: double.tryParse(_costController.text),
      mechanicName: _mechanicController.text.isEmpty ? null : _mechanicController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      receiptUrl: widget.log.receiptUrl,
      parts: widget.log.parts,
      createdAt: widget.log.createdAt,
    );

    await _maintenanceService.saveLog(updatedLog);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 24),
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
                    child: Text('${_serviceDate.day}/${_serviceDate.month}/${_serviceDate.year}'),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cost',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

