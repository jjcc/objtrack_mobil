import 'package:supabase_flutter/supabase_flutter.dart';

class ObjectRepository {
  Future<Map<String, dynamic>?> getObject(int id) async {
    return await Supabase.instance.client
        .from('objects').select('*, categories(name)').eq('id', id).maybeSingle();
  }

  Future<Map<String, dynamic>?> getCurrentOwner(int objectId) async {
    final event = await Supabase.instance.client
        .from('events')
        .select('e_to')
        .eq('object_id', objectId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return event?['e_to'];
  }

  Future<List<dynamic>> getRecentEvents(int objectId) async {
    return await Supabase.instance.client
        .from('events')
        .select('*, event_types(label), to:user_profiles!events_e_to_fkey(first_name, last_name)')
        .eq('object_id', objectId)
        .order('created_at', ascending: false)
        .limit(10);
  }
}
