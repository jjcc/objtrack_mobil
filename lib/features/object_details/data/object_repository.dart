import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/features/auth/data/profile_repository.dart';

class ObjectRepository {
  ObjectRepository({ProfileRepository? profiles})
    : _profiles = profiles ?? ProfileRepository();

  final ProfileRepository _profiles;

  Future<Map<String, dynamic>?> getObject(int id) async {
    return await SupabaseService.client
        .from('objects')
        .select('*, categories(name)')
        .eq('id', id)
        .maybeSingle();
  }

  Future<String?> getCurrentOwner(int objectId) async {
    final object = await SupabaseService.client
        .from('objects')
        .select('current_owner_id')
        .eq('id', objectId)
        .maybeSingle();
    final userId = object?['current_owner_id'] as String?;
    if (userId == null) return null;
    final names = await _profiles.namesFor([userId]);
    return names[userId];
  }

  Future<List<dynamic>> getRecentEvents(int objectId) async {
    return await SupabaseService.client
        .from('events')
        .select('*, event_types(label)')
        .eq('object_id', objectId)
        .order('created_at', ascending: false)
        .limit(10);
  }

  Future<List<Map<String, dynamic>>> getEnrichedRecentEvents(
    int objectId,
  ) async {
    final events = await getRecentEvents(objectId);
    final userIds = <String>{};
    for (final e in events) {
      final from = (e['e_from'] as String?)?.trim();
      final to = (e['e_to'] as String?)?.trim();
      if (from != null) userIds.add(from);
      if (to != null) userIds.add(to);
    }
    final nameCache = await _profiles.namesFor(userIds);
    return events.map((e) => Map<String, dynamic>.from(e)).map((e) {
      final from = e['e_from'] as String?;
      final to = e['e_to'] as String?;
      if (from != null) e['from_name'] = nameCache[from] ?? from;
      if (to != null) e['to_name'] = nameCache[to] ?? to;
      return e;
    }).toList();
  }
}
