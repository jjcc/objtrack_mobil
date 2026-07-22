import 'package:flutter_test/flutter_test.dart';
import 'package:objtrack_mobil/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ObjtrackApp());
    expect(find.text('ObjectTrack'), findsOneWidget);
  });
}
