import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:startsa/shared_ui/widgets/chips/app_chip.dart';
import 'package:startsa/shared_ui/widgets/forms/app_text_field.dart';
import 'package:startsa/shared_ui/widgets/forms/money_field.dart';
import 'package:startsa/shared_ui/widgets/forms/password_rules.dart';
import 'package:startsa/shared_ui/widgets/headers/auth_headers.dart';
import 'package:startsa/shared_ui/widgets/headers/overlap_layout.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('step header height and overlap', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 892));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StepHeader(step: 1, total: 6, title: 'Hi', onBack: () {}),
              const AuthCard(child: SizedBox(height: 50)),
            ],
          ),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    expect(t.getSize(find.byType(StepHeader)).height, 190 - 44);
    expect(find.text('STEP 1 OF 6'), findsOneWidget);
  });

  test('thousands formatter', () {
    const f = ThousandsFormatter();
    final v = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1200000',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    expect(v.text, '1,200,000');
    expect(passwordRulesMet('Abcdef1!'), isTrue);
  });

  testWidgets('text field with controller and chip tap', (t) async {
    final c = TextEditingController();
    var tapped = false;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              LabeledTextField(
                label: 'Full name',
                required: true,
                controller: c,
                maxLength: 50,
              ),
              AppChip(
                label: 'Seed',
                selected: false,
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );
    await t.enterText(find.byType(TextField), 'Sara');
    await t.pump();
    expect(c.text, 'Sara');
    expect(find.text('4/50'), findsOneWidget);
    await t.tap(find.text('Seed'));
    expect(tapped, isTrue);
  });
}
