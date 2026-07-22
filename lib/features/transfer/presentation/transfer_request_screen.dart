import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/shared/widgets/loading_indicator.dart';
import 'package:objtrack_mobil/shared/widgets/error_message.dart';

class TransferRequestScreen extends StatefulWidget {
  final int objectId;
  const TransferRequestScreen({super.key, required this.objectId});

  @override
  State<TransferRequestScreen> createState() => _TransferRequestScreenState();
}

class _TransferRequestScreenState extends State<TransferRequestScreen> {
  List<dynamic> users = const [];
  int? selectedUserId;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { isLoading = true; error = null; });
    try {
      final data = await SupabaseService.client.from('user_profiles').select('id, first_name, last_name');
      if (!mounted) return;
      setState(() { users = data; isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  Future<void> _submit() async {
    if (selectedUserId == null) return;
    final me = SupabaseService.client.auth.currentUser;
    if (me == null) {
      if (!mounted) return;
      setState(() => error = 'Not logged in');
      return;
    }
    setState(() { isLoading = true; error = null; });
    try {
      await SupabaseService.client.from('transfer_requests').insert({
        'object_id': widget.objectId,
        'from_user_id': me.id,
        'to_user_id': selectedUserId,
        'group_id': me.userMetadata?['group_id'],
        'status': 'pending',
      });
      if (!mounted) return;
      context.go('/my_requests');
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Transfer')),
      body: isLoading
          ? const LoadingIndicator()
          : error != null
              ? ErrorMessage(message: error!)
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Transfer to'),
                        items: users
                            .map((u) => DropdownMenuItem(value: u['id'] as int, child: Text('${u['first_name'] ?? ''} ${u['last_name'] ?? ''}')))
                            .toList(),
                        onChanged: (v) => setState(() => selectedUserId = v),
                        validator: (v) => v == null ? 'Select a user' : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(onPressed: _submit, child: const Text('Submit Request')),
                    ],
                  ),
                ),
    );
  }
}
