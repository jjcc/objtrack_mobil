import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  RealtimeChannel? _channel;

  void listenForNotifications({
    required String userId,
    required void Function(Map<String, dynamic> payload) onNotification,
  }) {
    _channel = Supabase.instance.client
        .channel('notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            column: 'user_id',
            type: PostgresChangeFilterType.eq,
            value: userId,
          ),
          callback: (payload) {
            onNotification(payload.newRecord);
          },
        )
        .subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
  }
}
