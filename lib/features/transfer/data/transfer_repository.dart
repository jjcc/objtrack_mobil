import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/features/auth/data/profile_repository.dart';

class TransferRepository {
  TransferRepository({ProfileRepository? profiles})
    : _profiles = profiles ?? ProfileRepository();

  final ProfileRepository _profiles;

  Future<void> requestTransfer({
    required int objectId,
    required String toUserId,
  }) async {
    final me = SupabaseService.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    await SupabaseService.client.rpc(
      'request_transfer',
      params: {'p_object_id': objectId, 'p_to_user_id': toUserId},
    );
  }

  Future<List<Map<String, dynamic>>> myRequests() async {
    final me = SupabaseService.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    final data = await SupabaseService.client
        .from('transfer_requests')
        .select('*, objects(name)')
        .eq('from_user_id', me.id)
        .order('created_at', ascending: false);
    return _withProfileNames(data, 'to_user_id', 'to_user_name');
  }

  Future<List<Map<String, dynamic>>> pendingApprovals() async {
    final me = SupabaseService.client.auth.currentUser;
    if (me == null) throw Exception('Not logged in');
    final data = await SupabaseService.client
        .from('transfer_requests')
        .select('*, objects(name)')
        .eq('to_user_id', me.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return _withProfileNames(data, 'from_user_id', 'from_user_name');
  }

  Future<void> approve(int requestId) async {
    await SupabaseService.client.rpc(
      'approve_transfer',
      params: {'p_request_id': requestId},
    );
  }

  Future<List<Map<String, dynamic>>> _withProfileNames(
    List<dynamic> data,
    String userIdKey,
    String nameKey,
  ) async {
    final rows = data
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final names = await _profiles.namesFor(
      rows.map((row) => row[userIdKey]).whereType<String>(),
    );
    for (final row in rows) {
      final userId = row[userIdKey] as String?;
      if (userId != null) row[nameKey] = names[userId] ?? userId;
    }
    return rows;
  }
}
