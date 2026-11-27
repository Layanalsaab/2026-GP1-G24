import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/shared_ui/widgets/forms/app_text_field.dart';
import 'package:startsa/shared_ui/widgets/forms/no_emoji_formatter.dart';
import 'package:startsa/shared_ui/widgets/nav/home_search_bar.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';

TextEditingValue _type(String old, String typed) {
  final next = old + typed;
  return const NoEmojiFormatter().formatEditUpdate(
    TextEditingValue(
      text: old,
      selection: TextSelection.collapsed(offset: old.length),
    ),
    TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('typing an emoji does nothing', () {
    for (final e in [
      '😀',
      '👍🏽',
      '🇸🇦',
      '1️⃣',
      '❤️',
      '👨‍👩‍👧',
      '🏽',
      '️',
    ]) {
      final v = _type('Hi', e);
      expect(v.text, 'Hi', reason: e);
      expect(v.selection.baseOffset, 2, reason: e);
    }
  });

  test('an emoji with the space the keyboard adds types nothing', () {
    expect(_type('Hi', '😀 ').text, 'Hi');
    expect(_type('Hi', '😀').text, 'Hi');
    expect(_type('Hi', ' ').text, 'Hi');
    expect(_type('Hi', ' ').text, 'Hi ');
  });

  test('normal text is kept: letters, Arabic, numbers and symbols', () {
    for (final s in ['a', 'محمد', 'é', '7', '#', '@', '-', ' ']) {
      expect(_type('Hi', s).text, 'Hi$s', reason: s);
    }
  });

  test('a paste with an emoji is refused', () {
    expect(_type('', 'Fin😀tech').text, '');
  });

  test('text saved earlier with an emoji can still be edited', () {
    expect(_type('Hi😀', '!').text, 'Hi😀!');
  });

  testWidgets('every kind of text box rejects emojis', (t) async {
    final a = TextEditingController();
    final b = TextEditingController();
    final search = TextEditingController();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    addTearDown(search.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              LabeledTextField(label: 'Name', controller: a, maxLength: 40),
              AppTextField(controller: b),
              HomeSearchBar(controller: search, onFilterTap: () {}, overlap: 0),
              Builder(
                builder: (c) => TextButton(
                  onPressed: () => showPickerSheet(
                    c,
                    title: 'Commerce model',
                    options: const ['B2B', 'Other'],
                    otherNoun: 'commerce model',
                    searchHint: 'Search',
                  ),
                  child: const Text('open'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final boxes = find.byType(TextField);
    for (var i = 0; i < 3; i++) {
      await t.enterText(boxes.at(i), 'ok');
      await t.enterText(boxes.at(i), 'ok😀');
    }
    expect(a.text, 'ok');
    expect(b.text, 'ok');
    expect(search.text, 'ok');

    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Other'));
    await t.pumpAndSettle();
    final sheetBoxes = find.descendant(
      of: find.byType(PickerSheet),
      matching: find.byType(TextField),
    );
    for (var i = 0; i < 2; i++) {
      await t.enterText(sheetBoxes.at(i), 'ok');
      await t.enterText(sheetBoxes.at(i), 'ok🚀');
      await t.pump();
      expect(
        t.widget<TextField>(sheetBoxes.at(i)).controller!.text,
        'ok',
        reason: 'sheet box $i',
      );
    }
    await t.pump(const Duration(seconds: 1));
  });
}
