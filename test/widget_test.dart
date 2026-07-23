import 'package:flutter_test/flutter_test.dart';
import 'package:objtrack_mobil/core/supabase.dart';
import 'package:objtrack_mobil/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initSupabase();
  });

  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ObjtrackApp());
    await tester.pumpAndSettle();
    expect(find.text('ObjectTrack'), findsOneWidget);
  });
}
