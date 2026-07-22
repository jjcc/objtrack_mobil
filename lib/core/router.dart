import 'package:go_router/go_router.dart';
import 'package:objtrack_mobil/features/auth/presentation/login_screen.dart';
import 'package:objtrack_mobil/features/home/presentation/home_screen.dart';
import 'package:objtrack_mobil/features/object_details/presentation/object_details_screen.dart';
import 'package:objtrack_mobil/features/scan/presentation/scanner_screen.dart';
import 'package:objtrack_mobil/features/scan/presentation/scan_result_screen.dart';
import 'package:objtrack_mobil/features/transfer/presentation/approvals_screen.dart';
import 'package:objtrack_mobil/features/transfer/presentation/my_requests_screen.dart';
import 'package:objtrack_mobil/features/transfer/presentation/transfer_request_screen.dart';
import 'package:objtrack_mobil/features/settings/presentation/settings_screen.dart';
import 'package:objtrack_mobil/core/supabase.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = SupabaseService.client.auth.currentUser != null;
    final isLoginPage = state.matchedLocation == '/login';
    if (!isLoggedIn && !isLoginPage) return '/login';
    if (isLoggedIn && isLoginPage) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/scan', builder: (_, __) => const ScannerScreen()),
    GoRoute(path: '/scan_result/:id', builder: (context, state) {
      final id = int.parse(state.pathParameters['id']!);
      return ScanResultScreen(objectId: id);
    }),
    GoRoute(path: '/object/:id', builder: (context, state) {
      final id = int.parse(state.pathParameters['id']!);
      return ObjectDetailsScreen(objectId: id);
    }),
    GoRoute(
      path: '/transfer_request/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return TransferRequestScreen(objectId: id);
      },
    ),
    GoRoute(path: '/my_requests', builder: (_, __) => const MyRequestsScreen()),
    GoRoute(path: '/approvals', builder: (_, __) => const ApprovalsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
