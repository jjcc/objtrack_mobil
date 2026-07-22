import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objtrack_mobil/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
