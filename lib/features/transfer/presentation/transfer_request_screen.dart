import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/features/auth/data/profile_repository.dart';
import 'package:objtrack_mobil/features/transfer/data/transfer_repository.dart';
import 'package:objtrack_mobil/shared/widgets/loading_indicator.dart';
import 'package:objtrack_mobil/shared/widgets/error_message.dart';

class TransferRequestScreen extends StatefulWidget {
  final int objectId;
  const TransferRequestScreen({super.key, required this.objectId});

  @override
  State<TransferRequestScreen> createState() => _TransferRequestScreenState();
}

class _TransferRequestScreenState extends State<TransferRequestScreen> {
  List<Map<String, dynamic>> users = const [];
  String? selectedUserId;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ProfileRepository().groupDirectory();
      final me = SupabaseService.client.auth.currentUser;
      if (!mounted) return;
      setState(() {
        users = data.where((user) => user['id'] != me?.id).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (selectedUserId == null) return;
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      await TransferRepository().requestTransfer(
        objectId: widget.objectId,
        toUserId: selectedUserId!,
      );
      if (!mounted) return;
      context.go('/my_requests');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
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
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Transfer to'),
                    items: users
                        .map(
                          (u) => DropdownMenuItem(
                            value: u['id'] as String,
                            child: Text(
                              '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'
                                  .trim(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedUserId = v),
                    validator: (v) => v == null ? 'Select a user' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit Request'),
                  ),
                ],
              ),
            ),
    );
  }
}
