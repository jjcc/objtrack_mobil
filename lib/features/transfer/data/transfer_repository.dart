import 'package:supabase_flutter/supabase_flutter.dart';

class TransferRepository {
  Future<void> requestTransfer({required int objectId, required int toUserId, int? groupId}) async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    await Supabase.instance.client.from('transfer_requests').insert({
      'object_id': objectId,
      'from_user_id': me.id,
      'to_user_id': toUserId,
      'group_id': groupId,
      'status': 'pending',
    });
  }

  Future<List<dynamic>> myRequests() async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    return await Supabase.instance.client
        .from('transfer_requests')
        .select('*, objects(name), to_user:user_profiles!transfer_requests_to_user_id_fkey(first_name, last_name)')
        .eq('from_user_id', me.id)
        .order('created_at', ascending: false);
  }

  Future<List<dynamic>> pendingApprovals() async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    return await Supabase.instance.client
        .from('transfer_requests')
        .select('*, objects(name), from_user:user_profiles!transfer_requests_from_user_id_fkey(first_name, last_name)')
        .eq('to_user_id', me.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  Future<void> approve(int requestId) async {
    await Supabase.instance.client.rpc('approve_transfer', params: {'p_request_id': requestId});
  }
}
