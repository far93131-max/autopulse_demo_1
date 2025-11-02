import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import 'splash_intro_screen.dart';
import 'add_car_modal.dart';

class MoreSettingsScreen extends StatelessWidget {
  const MoreSettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = AuthService();
      await authService.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashIntroScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          _buildSectionHeader('Profile'),
          FutureBuilder<String?>(
            future: AuthService().getSavedEmail(),
            builder: (context, snapshot) {
              final email = snapshot.data ?? 'User';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppTheme.accentColor),
                ),
                title: Text(email),
                subtitle: const Text('User Account'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit profile feature coming soon')),
                    );
                  },
                ),
              );
            },
          ),
          const Divider(),
          
          // Car Management
          _buildSectionHeader('Car Management'),
          ListTile(
            leading: const Icon(Icons.directions_car, color: AppTheme.accentColor),
            title: const Text('My Cars'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCarManagement(context),
          ),
          const Divider(),
          
          // Settings
          _buildSectionHeader('Settings'),
          ListTile(
            leading: const Icon(Icons.language, color: AppTheme.accentColor),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language selection coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: AppTheme.accentColor),
            title: const Text('Theme'),
            subtitle: const Text('Dark'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme selection coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: AppTheme.accentColor),
            title: const Text('Notifications'),
            subtitle: const Text('Enabled'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppTheme.accentColor,
            ),
          ),
          const Divider(),
          
          // Data Management
          _buildSectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.download, color: AppTheme.accentColor),
            title: const Text('Export Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload, color: AppTheme.accentColor),
            title: const Text('Import Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Import feature coming soon')),
              );
            },
          ),
          const Divider(),
          
          // Support
          _buildSectionHeader('Support'),
          ListTile(
            leading: const Icon(Icons.info, color: AppTheme.accentColor),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help, color: AppTheme.accentColor),
            title: const Text('FAQ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FAQ coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support, color: AppTheme.accentColor),
            title: const Text('Contact Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondaryColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Future<void> _showCarManagement(BuildContext context) async {
    final carService = CarService();
    final cars = await carService.getAllCars();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Cars',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.accentColor),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddCarModal()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: cars.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64,
                            color: AppTheme.textSecondaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No cars added',
                            style: TextStyle(color: AppTheme.textSecondaryColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddCarModal()),
                              );
                            },
                            child: const Text('Add Car'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: cars.length,
                      itemBuilder: (context, index) {
                        final car = cars[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                              child: const Icon(Icons.directions_car, color: AppTheme.accentColor),
                            ),
                            title: Text(car.displayName),
                            subtitle: Text(car.licensePlate ?? 'No license plate'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    // Edit car
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                  onPressed: () async {
                                    await carService.deleteCar(car.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Car deleted')),
                                    );
                                  },
                                ),
                              ],
                            ),
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
}

