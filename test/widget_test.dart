import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/main.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('splash shows, then the three intros in order', (tester) async {
    await tester.pumpWidget(const StartSaApp());
    expect(find.text('Start.sa'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pumpAndSettle();
    expect(find.textContaining('Where Saudi startups'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Programs, insights'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
