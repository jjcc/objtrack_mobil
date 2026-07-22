import 'package:flutter/material.dart';
import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/shared/widgets/app_drawer.dart';
import 'package:objtrack_mobil/shared/widgets/loading_indicator.dart';
import 'package:objtrack_mobil/shared/widgets/error_message.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<dynamic> requests = const [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = SupabaseService.client.auth.currentUser;
    if (me == null) {
      if (!mounted) return;
      setState(() { isLoading = false; error = 'Not logged in'; });
      return;
    }
    setState(() { isLoading = true; error = null; });
    try {
      final data = await SupabaseService.client
          .from('transfer_requests')
          .select('*, objects(name), to_user:user_profiles!transfer_requests_to_user_id_fkey(first_name, last_name)')
          .eq('from_user_id', me.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() { requests = data; isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      drawer: const AppDrawer(),
      body: isLoading ? const LoadingIndicator() : error != null ? ErrorMessage(message: error!) : ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final r = requests[index];
          final object = r['objects'];
          final toUser = r['to_user'];
          return ListTile(
            title: Text(object?['name'] ?? 'Object'),
            subtitle: Text('To: ${(toUser?['first_name'] ?? '')} ${(toUser?['last_name'] ?? '')}'),
            trailing: Chip(label: Text(r['status'] ?? 'pending')),
          );
        },
      ),
    );
  }
}
