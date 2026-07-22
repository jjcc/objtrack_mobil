import 'package:flutter/material.dart';
import 'package:objtrack_mobil/shared/widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Settings stub')),
    );
  }
}
