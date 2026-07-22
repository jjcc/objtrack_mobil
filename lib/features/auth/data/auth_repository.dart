import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  Future<AuthResponse> login(String email, String password) async {
    return await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  bool get isLoggedIn => Supabase.instance.client.auth.currentUser != null;
}
