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
          .eq('from_user_id', me.id)
          .order('created_at', ascending: false);
      final ids = (data as List)
          .map((e) => (e['to_user_id'] as String?)?.trim())
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

  String _toUserName(String? userId) {
    if (userId == null) return '';
    final m = _nameMap[userId] ?? const {};
    final full = '${(m['first_name'] ?? '').trim()} ${(m['last_name'] ?? '').trim()}'.trim();
    return full.isEmpty ? userId : full;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      drawer: const AppDrawer(),
      body: isLoading
          ? const LoadingIndicator()
          : error != null
              ? ErrorMessage(message: error!)
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final r = requests[index];
                    final object = r['objects'];
                    return ListTile(
                      title: Text(object?['name'] ?? 'Object'),
                      subtitle: Text('To: ${_toUserName(r['to_user_id'] as String?)}'),
                      trailing: Chip(label: Text(r['status'] ?? 'pending')),
                    );
                  },
                ),
    );
  }
}
