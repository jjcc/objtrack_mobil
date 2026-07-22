import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/shared/widgets/app_drawer.dart';
import 'package:objtrack_mobil/shared/widgets/loading_indicator.dart';
import 'package:objtrack_mobil/shared/widgets/error_message.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
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
          .select('*, objects(name), from_user:user_profiles!transfer_requests_from_user_id_fkey(first_name, last_name)')
          .eq('to_user_id', me.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() { requests = data; isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  Future<void> _approve(int requestId) async {
    await SupabaseService.client.rpc('approve_transfer', params: {'p_request_id': requestId});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer approved')),
    );
    context.go('/my_requests');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      drawer: const AppDrawer(),
      body: isLoading ? const LoadingIndicator() : error != null ? ErrorMessage(message: error!) : requests.isEmpty ? const Center(child: Text('No pending approvals')) : ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final r = requests[index];
          return ListTile(
            title: Text(r['objects']?['name'] ?? 'Object'),
            subtitle: Text('From: ${(r['from_user']?['first_name'] ?? '')} ${(r['from_user']?['last_name'] ?? '')}'),
            trailing: FilledButton(onPressed: () => _approve(r['id']), child: const Text('Approve')),
          );
        },
      ),
    );
  }
}
