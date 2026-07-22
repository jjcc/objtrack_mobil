import 'package:flutter/material.dart';
import 'package:objtrack_mobil/core/router.dart';
import 'package:objtrack_mobil/core/theme.dart';
import 'package:objtrack_mobil/core/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ObjtrackApp());
}

class ObjtrackApp extends StatelessWidget {
  const ObjtrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ObjectTrack',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
