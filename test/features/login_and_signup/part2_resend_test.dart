import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/login_and_signup/widgets/resend_row.dart';

Widget _row({
  required int seconds,
  bool busy = false,
  required VoidCallback onResend,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 360,
        child: ResendRow(
          seconds: seconds,
          error: null,
          busy: busy,
          onResend: onResend,
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Resend email', () {
    testWidgets('ready: one tap sends, on the words or around them', (t) async {
      var taps = 0;
      await t.pumpWidget(_row(seconds: 0, onResend: () => taps++));
      await t.pumpAndSettle();
      final area = find.byKey(const ValueKey('resend-area'));
      await t.tap(find.textContaining('Resend email'));
      expect(taps, 1);
      // A tap in the row's padding (above the words) counts too.
      await t.tapAt(t.getTopLeft(area) + const Offset(20, 4));
      expect(taps, 2);
    });

    testWidgets('busy: taps are ignored', (t) async {
      var taps = 0;
      await t.pumpWidget(_row(seconds: 0, busy: true, onResend: () => taps++));
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Resend email'));
      await t.tapAt(
        t.getTopLeft(find.byKey(const ValueKey('resend-area'))) +
            const Offset(20, 4),
      );
      expect(taps, 0);
    });

    testWidgets('during the countdown it is muted and not tappable', (t) async {
      var taps = 0;
      await t.pumpWidget(_row(seconds: 42, onResend: () => taps++));
      await t.pumpAndSettle();
      expect(find.textContaining('Resend in'), findsOneWidget);
      expect(find.textContaining('0:42'), findsOneWidget);
      await t.tap(find.textContaining('Resend in'));
      await t.tapAt(
        t.getTopLeft(find.byKey(const ValueKey('resend-area'))) +
            const Offset(20, 4),
      );
      expect(taps, 0);
    });
  });
}
