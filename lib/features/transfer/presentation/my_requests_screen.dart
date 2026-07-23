import 'package:flutter/material.dart';
import 'package:objtrack_mobil/features/transfer/data/transfer_repository.dart';
import 'package:objtrack_mobil/shared/widgets/app_drawer.dart';
import 'package:objtrack_mobil/shared/widgets/loading_indicator.dart';
import 'package:objtrack_mobil/shared/widgets/error_message.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<Map<String, dynamic>> requests = const [];
  bool isLoading = true;
  String? error;

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
      final data = await TransferRepository().myRequests();
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
                  subtitle: Text('To: ${r['to_user_name'] ?? ''}'),
                  trailing: Chip(label: Text(r['status'] ?? 'pending')),
                );
              },
            ),
    );
  }
}
