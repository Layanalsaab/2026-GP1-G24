import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/helpers/startup_validators.dart';
import 'package:startsa/shared_ui/widgets/forms/app_text_field.dart';
import 'package:startsa/shared_ui/widgets/overlays/multi_picker_sheet.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('website needs a real top-level domain', () {
    test('real endings are accepted', () {
      for (final ok in [
        'example.com',
        'www.example.sa',
        'example.org',
        'startup.io',
        'my-site.co.uk',
        'example.com.sa',
        'EXAMPLE.COM',
        'https://example.com',
        'http://www.example.sa/path?x=1',
        'example.ai',
        'example.app',
      ]) {
        expect(StartupValidators.isWebsite(ok), isTrue, reason: ok);
      }
    });

    test('made-up endings and half-typed addresses are refused', () {
      for (final bad in [
        'example.iii',
        'example.abc',
        'example.comm',
        'example.c',
        'example.',
        'example',
        'e',
        'exa mple.com',
        'ftp://example.com',
        '.com',
      ]) {
        expect(StartupValidators.isWebsite(bad), isFalse, reason: bad);
        if (bad.trim().isNotEmpty) {
          expect(
            StartupValidators.websiteUrl(bad),
            'Enter a valid website, like example.com',
            reason: bad,
          );
        }
      }
    });
  });

  testWidgets('founded year: a fifth digit is simply not typed, no message', (
    t,
  ) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabeledTextField(
            label: 'Founded year',
            controller: c,
            maxLength: 4,
            showCounter: false,
            showOverflowMessage: false,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ),
    );
    await t.enterText(find.byType(TextField), '20245');
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(c.text, '2024');
    expect(find.textContaining('Maximum'), findsNothing);
  });

  testWidgets('other fields still say "Maximum N characters allowed"', (
    t,
  ) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabeledTextField(label: 'Name', controller: c, maxLength: 4),
        ),
      ),
    );
    await t.enterText(find.byType(TextField), 'abcdef');
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Maximum 4 characters allowed.'), findsOneWidget);
  });

  for (final multi in [false, true]) {
    testWidgets(
      '${multi ? 'several picks' : 'one pick'}: typing past 40 in Other '
      'stops at 40 and shows the red message',
      (t) async {
        await t.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (c) => TextButton(
                onPressed: () => multi
                    ? showMultiPickerSheet(
                        c,
                        title: 'Commerce models',
                        options: const ['B2B', 'Other'],
                        selected: const {},
                        onToggle: (_) {},
                        otherNoun: 'commerce model',
                      )
                    : showPickerSheet(
                        c,
                        title: 'Commerce model',
                        options: const ['B2B', 'Other'],
                        otherNoun: 'commerce model',
                      ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        await t.tap(find.text('Other'));
        await t.pumpAndSettle();
        final box = find.byType(TextField).last;
        await t.enterText(box, 'x' * 39);
        await t.pump();
        expect(find.text('Maximum 40 characters allowed.'), findsNothing);
        await t.enterText(box, 'x' * 45);
        await t.pump();
        await t.pump();
        expect(t.widget<TextField>(box).controller!.text.length, 40);
        expect(find.text('40/40'), findsOneWidget);
        expect(find.text('Maximum 40 characters allowed.'), findsOneWidget);
        await t.enterText(box, 'x' * 38);
        await t.pump();
        await t.pump();
        expect(find.text('Maximum 40 characters allowed.'), findsNothing);
        await t.pump(const Duration(seconds: 1));
      },
    );
  }
}
