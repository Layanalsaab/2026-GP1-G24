import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/shared_ui/widgets/forms/app_field.dart';
import 'package:startsa/shared_ui/widgets/forms/app_text_field.dart';
import 'package:startsa/shared_ui/widgets/forms/select_field.dart';
import 'package:startsa/shared_ui/widgets/forms/visibility_pill.dart';

/// The spacing rule of every form: label -> control 8 px, control -> next
/// label 28 px, whatever sits in the helper line (counter, hint, error, link)
/// or in the label row (a pill).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester t, List<Widget> fields) async {
    await t.binding.setSurfaceSize(const Size(412, 1600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: FormFieldColumn(children: fields)),
        ),
      ),
    );
    await t.pump();
  }

  double top(WidgetTester t, Finder f) => t.getTopLeft(f).dy;

  testWidgets('every field is 106 px from the next, whatever is under it', (
    t,
  ) async {
    final c = List.generate(6, (_) => TextEditingController());
    addTearDown(() {
      for (final x in c) {
        x.dispose();
      }
    });
    await pump(t, [
      // 0: plain, 1: counter, 2: error, 3: hint, 4: link, 5: dropdown
      LabeledTextField(label: 'Field 0', controller: c[0]),
      LabeledTextField(label: 'Field 1', controller: c[1], maxLength: 50),
      LabeledTextField(
        label: 'Field 2',
        controller: c[2],
        maxLength: 50,
        error: 'Something is wrong',
      ),
      LabeledTextField(label: 'Field 3', controller: c[3], hint: 'A hint'),
      LabeledTextField(
        label: 'Field 4',
        controller: c[4],
        linkLabel: 'Forgot password?',
        onLink: () {},
      ),
      AppField(
        label: 'Field 5',
        child: SelectField(placeholder: 'Choose', onTap: () {}),
      ),
    ]);
    final tops = [for (var i = 0; i < 6; i++) top(t, find.text('Field $i'))];
    for (var i = 1; i < tops.length; i++) {
      // The field with a link ("Forgot password?") has a little extra room
      // under it so the link text is not cut off.
      final expected = i == 5 ? 116 : 106;
      expect(tops[i] - tops[i - 1], expected, reason: 'field $i');
    }
    // The first label sits 28 px below the top of the card.
    expect(tops.first, closeTo(28, 4));
  });

  testWidgets('label to control is 8 px and control to next label 28 px', (
    t,
  ) async {
    final a = TextEditingController();
    final b = TextEditingController();
    addTearDown(() {
      a.dispose();
      b.dispose();
    });
    await pump(t, [
      LabeledTextField(label: 'First', controller: a, maxLength: 20),
      LabeledTextField(label: 'Second', controller: b),
    ]);
    final fields = find.byType(AppTextField);
    final label = find.text('First');
    final labelBottom = t.getBottomLeft(label).dy;
    expect(t.getTopLeft(fields.first).dy - labelBottom, closeTo(8, 3));
    final inputBottom = t.getBottomLeft(fields.first).dy;
    expect(top(t, find.text('Second')) - inputBottom, closeTo(28, 3));
  });

  testWidgets('a pill in the label row does not make the row taller', (
    t,
  ) async {
    final a = TextEditingController();
    final b = TextEditingController();
    final c = TextEditingController();
    addTearDown(() {
      a.dispose();
      b.dispose();
      c.dispose();
    });
    var isPublic = false;
    await pump(t, [
      LabeledTextField(label: 'Before', controller: a),
      StatefulBuilder(
        builder: (context, setState) => LabeledTextField(
          label: 'With Pill',
          controller: b,
          labelTrailing: VisibilityPill(
            isPublic: isPublic,
            fieldName: 'email',
            onChanged: (v) => setState(() => isPublic = v),
          ),
        ),
      ),
      LabeledTextField(label: 'After', controller: c),
    ]);
    expect(top(t, find.text('With Pill')) - top(t, find.text('Before')), 106);
    expect(top(t, find.text('After')) - top(t, find.text('With Pill')), 106);

    // One tap switches Private -> Public (no sheet), and back.
    expect(find.text('Private'), findsOneWidget);
    await t.tap(find.text('Private'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Private'), findsNothing);
    expect(top(t, find.text('After')) - top(t, find.text('With Pill')), 106);
    await t.tap(find.text('Public'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Private'), findsOneWidget);
  });
}
