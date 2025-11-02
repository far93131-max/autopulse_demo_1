import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RulesTipsScreen extends StatelessWidget {
  const RulesTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Rules'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter by car type
            Card(
              color: AppTheme.surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Car Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Gasoline', 'Diesel', 'Hybrid'].map((type) {
                        return FilterChip(
                          label: Text(type),
                          selected: type == 'All',
                          onSelected: (selected) {},
                          selectedColor: AppTheme.accentColor.withOpacity(0.3),
                          checkmarkColor: AppTheme.accentColor,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Maintenance Tips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ..._maintenanceTips.map((tip) => _buildTipCard(tip)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tip['icon'] as IconData, color: AppTheme.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip['title'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Interval: ${tip['interval'] as String}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tip['description'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Show more details
              },
              child: const Text('Learn More'),
            ),
          ],
        ),
      ),
    );
  }

  static final List<Map<String, dynamic>> _maintenanceTips = [
    {
      'title': 'Oil Change',
      'icon': Icons.oil_barrel,
      'interval': 'Every 10,000 km / 6 months',
      'description':
          'Regular oil changes keep your engine running smoothly and extend its lifespan. Check your oil level monthly.',
    },
    {
      'title': 'Tire Rotation',
      'icon': Icons.tire_repair,
      'interval': 'Every 10,000 km / 6 months',
      'description':
          'Rotating tires ensures even wear and extends tire life. Check tire pressure monthly and tread depth regularly.',
    },
    {
      'title': 'Brake Inspection',
      'icon': Icons.stop_circle,
      'interval': 'Every 20,000 km / 12 months',
      'description':
          'Brake pads and rotors should be inspected regularly. Listen for squeaking or grinding noises as warning signs.',
    },
    {
      'title': 'Battery Check',
      'icon': Icons.battery_charging_full,
      'interval': 'Every 12 months',
      'description':
          'Car batteries typically last 3-5 years. Have your battery tested annually, especially before winter.',
    },
    {
      'title': 'Coolant Flush',
      'icon': Icons.ac_unit,
      'interval': 'Every 80,000 km / 5 years',
      'description':
          'Coolant prevents engine overheating and freezing. Replace according to manufacturer recommendations.',
    },
    {
      'title': 'Air Filter Replacement',
      'icon': Icons.air,
      'interval': 'Every 15,000 - 30,000 km',
      'description':
          'A clean air filter improves fuel efficiency and engine performance. Check during every oil change.',
    },
  ];
}

