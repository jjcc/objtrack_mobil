import 'package:objtrack_mobil/core/supabase.dart';

class ProfileRepository {
  Future<List<Map<String, dynamic>>> groupDirectory() async {
    final data = await SupabaseService.client.rpc('group_profile_directory');
    return (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, String>> namesFor(Iterable<String> userIds) async {
    final ids = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return const {};

    final data = await SupabaseService.client.rpc(
      'profile_names',
      params: {'p_user_ids': ids.toList()},
    );
    final names = <String, String>{};
    for (final rawRow in data as List) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final id = row['id'] as String;
      final name =
          '${(row['first_name'] ?? '').toString().trim()} '
                  '${(row['last_name'] ?? '').toString().trim()}'
              .trim();
      if (name.isNotEmpty) names[id] = name;
    }
    return names;
  }
}
