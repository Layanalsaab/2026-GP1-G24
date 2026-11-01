import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/helpers/startup_validators.dart';
import 'package:startsa/shared_ui/widgets/forms/app_text_field.dart';

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
}
