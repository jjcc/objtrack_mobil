import 'package:flutter/material.dart';
import 'package:objtrack_mobil/core/supabase.dart';

class TransferRepository {
  Future<void> requestTransfer({
    required int objectId,
    required int toUserId,
    int? groupId,
  }) async {
    final me = SupabaseService.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    await SupabaseService.client.from('transfer_requests').insert({
      'object_id': objectId,
      'from_user_id': me.id,
      'to_user_id': toUserId,
      'group_id': groupId,
      'status': 'pending',
    });
  }

  Future<List<dynamic>> myRequests() async {
    final me = SupabaseService.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    return await SupabaseService.client
        .from('transfer_requests')
        .select('*, objects(name)')
        .eq('from_user_id', me.id)
        .order('created_at', ascending: false);
  }

  Future<List<dynamic>> pendingApprovals() async {
    final me = SupabaseService.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    return await SupabaseService.client
        .from('transfer_requests')
        .select('*, objects(name)')
        .eq('to_user_id', me.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  Future<void> approve(int requestId) async {
    await SupabaseService.client.rpc(
      'approve_transfer',
      params: {'p_request_id': requestId},
    );
  }
}
