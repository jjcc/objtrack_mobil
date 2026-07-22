import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/shared/widgets/loading_indicator.dart';
import 'package:objtrack_mobil/shared/widgets/error_message.dart';
import 'package:objtrack_mobil/shared/widgets/owner_badge.dart';

class ObjectDetailsScreen extends StatefulWidget {
  final int objectId;
  const ObjectDetailsScreen({super.key, required this.objectId});

  @override
  State<ObjectDetailsScreen> createState() => _ObjectDetailsScreenState();
}

class _ObjectDetailsScreenState extends State<ObjectDetailsScreen> {
  Map<String, dynamic>? object;
  List<dynamic> events = const [];
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
      final client = SupabaseService.client;
      final obj = await client.from('objects').select('*, categories(name)').eq('id', widget.objectId).maybeSingle();
      final eventList = await client.from('events').select('*, event_types(label), to:user_profiles!events_e_to_fkey(first_name, last_name)').eq('object_id', widget.objectId).order('created_at', ascending: false).limit(10);
      if (!mounted) return;
      setState(() {
        object = obj;
        events = eventList;
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
      body: isLoading
          ? const LoadingIndicator()
          : error != null
              ? ErrorMessage(message: error!)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (object == null) return const Center(child: Text('Object not found'));
    final latestEvent = events.isNotEmpty ? events.first : null;
    final owner = latestEvent != null && latestEvent['to'] != null
        ? '${latestEvent['to']['first_name'] ?? ''} ${latestEvent['to']['last_name'] ?? ''}'.trim()
        : 'Unassigned';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(object!['name'] ?? '', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (object!['description'] != null) Text(object!['description']),
        const SizedBox(height: 16),
        const Text('Current Owner', style: TextStyle(fontWeight: FontWeight.w600)),
        OwnerBadge(name: owner.isEmpty ? 'Unassigned' : owner),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.go('/transfer_request/${object!['id']}'),
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Request Transfer'),
        ),
        const SizedBox(height: 20),
        const Text('Recent Events', style: TextStyle(fontWeight: FontWeight.w600)),
        ...events.map((e) => ListTile(
              title: Text(e['event_types']?['label'] ?? 'Event'),
              subtitle: Text(e['created_at'] ?? ''),
            )),
      ],
    );
  }
}
