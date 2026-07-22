import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:objtrack_mobil/shared/widgets/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), centerTitle: true),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FilledCardWithIcon(icon: Icons.qr_code_scanner, title: 'Scan', subtitle: 'Scan barcode', onTap: () => context.go('/scan')),
          const SizedBox(height: 12),
          FilledCardWithIcon(icon: Icons.checklist, title: 'My Requests', subtitle: 'Pending transfers', onTap: () => context.go('/my_requests')),
          const SizedBox(height: 12),
          FilledCardWithIcon(icon: Icons.approval, title: 'Approvals', subtitle: 'Approve transfers', onTap: () => context.go('/approvals')),
        ],
      ),
    );
  }
}

class FilledCardWithIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const FilledCardWithIcon({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
