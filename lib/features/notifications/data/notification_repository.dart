class NotificationRepository {
  /// TODO: Wire up realtime notifications once the `notifications` table
  /// exists in Supabase. For now this is a stub.
  void listenForNotifications({
    required String userId,
    required void Function(Map<String, dynamic> payload) onNotification,
  }) {}

  void dispose() {}
}
