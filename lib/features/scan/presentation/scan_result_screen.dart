import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/shared/widgets/loading_indicator.dart';
import 'package:objtrack_mobil/shared/widgets/error_message.dart';
import 'package:objtrack_mobil/shared/widgets/owner_badge.dart';
import 'package:objtrack_mobil/features/object_details/data/object_repository.dart';

class ScanResultScreen extends StatefulWidget {
  final int objectId;
  const ScanResultScreen({super.key, required this.objectId});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  Map<String, dynamic>? object;
  List<dynamic> events = const [];
  Map<String, String>? currentOwner;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { isLoading = true; error = null; });
    try {
      final repo = ObjectRepository();
      object = await repo.getObject(widget.objectId);
      final owner = await repo.getCurrentOwner(widget.objectId);
      final rawEvents = await repo.getRecentEvents(widget.objectId);
      final enriched = await repo.getEnrichedRecentEvents(widget.objectId);
      if (!mounted) return;
      setState(() {
        events = enriched;
        currentOwner = owner;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Details')),
      body: isLoading ? const LoadingIndicator() : error != null ? ErrorMessage(message: error!) : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (object == null) return const Center(child: Text('Object not found'));
    final category = object!['categories'];
    final ownerName = currentOwner == null || currentOwner!.isEmpty ? null : currentOwner!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(object!['name'] ?? '', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (category != null) Chip(label: Text(category['name'] ?? '')),
        if (object!['model'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Model: ${object!['model']}')),
        if (object!['description'] != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(object!['description'])),
        const SizedBox(height: 16),
        const Text('Current Owner', style: TextStyle(fontWeight: FontWeight.w600)),
        OwnerBadge(name: ownerName),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => context.go('/transfer_request/${object!['id']}'), icon: const Icon(Icons.swap_horiz), label: const Text('Request Transfer')),
        const SizedBox(height: 20),
        const Text('Recent Events', style: TextStyle(fontWeight: FontWeight.w600)),
        ...events.map((e) => ListTile(title: Text(e['event_types']?['label'] ?? 'Event'), subtitle: Text((e['created_at'] ?? '').toString()))),
      ],
    );
  }
}
