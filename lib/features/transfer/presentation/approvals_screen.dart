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
  final Map<String, Map<String, String>> _nameMap = {};

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
          .select('*, objects(name)')
          .eq('to_user_id', me.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      final ids = (data as List)
          .map((e) => (e['from_user_id'] as String?)?.trim())
          .whereType<String>()
          .toSet()
          .toList();
      final Map<String, Map<String, String>> nameMap = {};
      for (final id in ids) {
        final profile = await SupabaseService.client
            .from('user_profiles')
            .select('first_name,last_name')
            .eq('id', id)
            .maybeSingle();
        if (profile != null) {
          nameMap[id] = Map<String, String>.from(profile);
        }
      }
      if (!mounted) return;
      setState(() {
        requests = data;
        _nameMap
          ..clear()
          ..addAll(nameMap);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  String _fromUserName(String? userId) {
    if (userId == null) return '';
    final m = _nameMap[userId] ?? const {};
    final full = '${(m['first_name'] ?? '').trim()} ${(m['last_name'] ?? '').trim()}'.trim();
    return full.isEmpty ? userId : full;
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
      body: isLoading
          ? const LoadingIndicator()
          : error != null
              ? ErrorMessage(message: error!)
              : requests.isEmpty
                  ? const Center(child: Text('No pending approvals'))
                  : ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final r = requests[index];
                        return ListTile(
                          title: Text(r['objects']?['name'] ?? 'Object'),
                          subtitle: Text('From: ${_fromUserName(r['from_user_id'] as String?)}'),
                          trailing: FilledButton(
                            onPressed: () => _approve(r['id'] as int),
                            child: const Text('Approve'),
                          ),
                        );
                      },
                    ),
    );
  }
}
