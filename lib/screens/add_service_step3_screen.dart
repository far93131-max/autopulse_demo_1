import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/service_type.dart';
import '../models/maintenance_log.dart';
import '../services/maintenance_service.dart';
import 'main_navigation.dart';

class AddServiceStep3Screen extends StatefulWidget {
  final ServiceType serviceType;
  final MaintenanceLog log;

  const AddServiceStep3Screen({
    super.key,
    required this.serviceType,
    required this.log,
  });

  @override
  State<AddServiceStep3Screen> createState() => _AddServiceStep3ScreenState();
}

class _AddServiceStep3ScreenState extends State<AddServiceStep3Screen> {
  final _maintenanceService = MaintenanceService();
  bool _isSaving = false;

  Future<void> _saveRecord() async {
    setState(() => _isSaving = true);

    // Add service type to log
    final logWithType = MaintenanceLog(
      id: widget.log.id,
      carId: widget.log.carId,
      serviceTypeId: widget.log.serviceTypeId,
      serviceType: widget.serviceType,
      mileage: widget.log.mileage,
      dateOfService: widget.log.dateOfService,
      cost: widget.log.cost,
      mechanicName: widget.log.mechanicName,
      notes: widget.log.notes,
      receiptUrl: widget.log.receiptUrl,
      parts: widget.log.parts,
      createdAt: widget.log.createdAt,
    );

    await _maintenanceService.saveLog(logWithType);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
        (route) => route.isFirst ? false : true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm & Save'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppTheme.surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Service', widget.serviceType.name),
                    _buildSummaryRow('Date', _formatDate(widget.log.dateOfService)),
                    _buildSummaryRow('Mileage', '${widget.log.mileage.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} km'),
                    if (widget.log.cost != null)
                      _buildSummaryRow('Cost', '\$${widget.log.cost!.toStringAsFixed(2)}'),
                    if (widget.log.mechanicName != null)
                      _buildSummaryRow('Mechanic', widget.log.mechanicName!),
                    if (widget.log.notes != null && widget.log.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.log.notes!,
                        style: const TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ],
                    if (widget.log.parts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Parts:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.log.parts.map((part) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(part.name, style: const TextStyle(color: AppTheme.textSecondaryColor)),
                            if (part.cost != null)
                              Text(
                                '\$${part.cost!.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppTheme.textSecondaryColor),
                              ),
                          ],
                        ),
                      )),
                    ],
                    if (widget.log.totalCost > 0) ...[
                      const Divider(),
                      _buildSummaryRow(
                        'Total Cost',
                        '\$${widget.log.totalCost.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Edit Details'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRecord,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Record'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppTheme.accentColor : AppTheme.textSecondaryColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppTheme.accentColor : AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Service added successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Home'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                  );
                },
                child: const Text('View History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

