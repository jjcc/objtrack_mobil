import 'package:flutter/material.dart';
import 'package:objtrack_mobil/features/transfer/data/transfer_repository.dart';
import 'package:objtrack_mobil/shared/widgets/app_drawer.dart';
import 'package:objtrack_mobil/shared/widgets/loading_indicator.dart';
import 'package:objtrack_mobil/shared/widgets/error_message.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  List<Map<String, dynamic>> requests = const [];
  bool isLoading = true;
  String? error;
  int? approvingRequestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await TransferRepository().pendingApprovals();
      if (!mounted) return;
      setState(() {
        requests = data;
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

  Future<void> _approve(int requestId) async {
    setState(() {
      approvingRequestId = requestId;
      error = null;
    });
    try {
      await TransferRepository().approve(requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transfer approved')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => approvingRequestId = null);
    }
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
                  subtitle: Text('From: ${r['from_user_name'] ?? ''}'),
                  trailing: FilledButton(
                    onPressed: approvingRequestId == null
                        ? () => _approve(r['id'] as int)
                        : null,
                    child: approvingRequestId == r['id']
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Approve'),
                  ),
                );
              },
            ),
    );
  }
}
