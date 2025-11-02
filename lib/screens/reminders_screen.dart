import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'rules_tips_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: const RulesTipsScreen(),
    );
  }
}

