import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:objtrack_mobil/core/supabase.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
            child: Text('ObjectTrack\n${user?.email ?? ''}'),
          ),
          ListTile(title: const Text('Home'), onTap: () => context.go('/home')),
          ListTile(title: const Text('Scan'), onTap: () => context.go('/scan')),
          ListTile(title: const Text('My Requests'), onTap: () => context.go('/my_requests')),
          ListTile(title: const Text('Approvals'), onTap: () => context.go('/approvals')),
          ListTile(title: const Text('Settings'), onTap: () => context.go('/settings')),
          ListTile(title: const Text('Logout'), onTap: () async {
            await SupabaseService.client.auth.signOut();
            if (context.mounted) context.go('/login');
          }),
        ],
      ),
    );
  }
}
