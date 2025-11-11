import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MileageUpdateResult {
  final int mileage;
  final bool hasWarning;

  const MileageUpdateResult({
    required this.mileage,
    required this.hasWarning,
  });
}

class UpdateMileageModal extends StatefulWidget {
  final int currentMileage;

  const UpdateMileageModal({
    super.key,
    required this.currentMileage,
  });

  @override
  State<UpdateMileageModal> createState() => _UpdateMileageModalState();
}

class _UpdateMileageModalState extends State<UpdateMileageModal> {
  final _controller = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _controller.text = widget.currentMileage.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Update Mileage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Mileage (km)',
                prefixIcon: Icon(Icons.speed),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter mileage';
                }
                final mileage = int.tryParse(value);
                if (mileage == null || mileage < 0) {
                  return 'Please enter a valid mileage';
                }
                return null;
              },
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
                  onPressed: () async {
                    final mileage = int.tryParse(_controller.text);
                    if (mileage == null || mileage < 0) return;

                    final current = widget.currentMileage;
                    final isDecrease = mileage < current;
                    final isJump = mileage - current > 20000;

                    if (!isDecrease && !isJump) {
                      Navigator.pop(
                        context,
                        MileageUpdateResult(
                          mileage: mileage,
                          hasWarning: false,
                        ),
                      );
                      return;
                    }

                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppTheme.surfaceColor,
                        title: const Text('Confirm Mileage Update'),
                        content: Text(
                          isDecrease
                              ? 'The new mileage ($mileage km) is less than the current reading ($current km).\n\nAre you sure you want to proceed?'
                              : 'The new mileage ($mileage km) is more than 20,000 km above the current reading ($current km).\n\nPlease confirm this large jump.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Proceed'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      Navigator.pop(
                        context,
                        MileageUpdateResult(
                          mileage: mileage,
                          hasWarning: true,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

