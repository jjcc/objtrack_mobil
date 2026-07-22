import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://hdpfxqqvrpmelcregemq.supabase.co',
    publishableKey: '<SECRET_f934a1bb>',
    debug: true,
  );
}

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
}
