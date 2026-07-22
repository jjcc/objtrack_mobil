import 'package:flutter/material.dart';
import 'package:objtrack_mobil/core/supabase.dart';

class ObjectRepository {
  Future<Map<String, dynamic>?> getObject(int id) async {
    return await SupabaseService.client
        .from('objects')
        .select('*, categories(name)')
        .eq('id', id)
        .maybeSingle();
  }

  Future<Map<String, String>?> getCurrentOwner(int objectId) async {
    final event = await SupabaseService.client
        .from('events')
        .select('e_to')
        .eq('object_id', objectId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final userId = event?['e_to'] as String?;
    if (userId == null) return null;
    final profile = await SupabaseService.client
        .from('user_profiles')
        .select('first_name,last_name')
        .eq('id', userId)
        .maybeSingle();
    if (profile == null) return null;
    return Map<String, String>.from(profile);
  }

  Future<List<dynamic>> getRecentEvents(int objectId) async {
    return await SupabaseService.client
        .from('events')
        .select('*, event_types(label)')
        .eq('object_id', objectId)
        .order('created_at', ascending: false)
        .limit(10);
  }

  Future<List<Map<String, dynamic>>> getEnrichedRecentEvents(int objectId) async {
    final events = await getRecentEvents(objectId);
    final userIds = <String>{};
    for (final e in events) {
      final from = (e['e_from'] as String?)?.trim();
      final to = (e['e_to'] as String?)?.trim();
      if (from != null) userIds.add(from);
      if (to != null) userIds.add(to);
    }
    final nameCache = <String, String>{};
    for (final uid in userIds) {
      final profile = await SupabaseService.client
          .from('user_profiles')
          .select('first_name,last_name')
          .eq('id', uid)
          .maybeSingle();
      if (profile != null) {
        final m = Map<String, String>.from(profile);
        final name = '${(m['first_name'] ?? '').trim()} ${(m['last_name'] ?? '').trim()}'.trim();
        if (name.isNotEmpty) nameCache[uid] = name;
      }
    }
    return events
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) {
          final from = e['e_from'] as String?;
          final to = e['e_to'] as String?;
          if (from != null) e['from_name'] = nameCache[from] ?? from;
          if (to != null) e['to_name'] = nameCache[to] ?? to;
          return e;
        })
        .toList();
  }
}
