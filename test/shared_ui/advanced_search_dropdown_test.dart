import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/overlays/advanced_search_sheet.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const groups = [
    AdvancedSearchGroup(
      title: 'Sector',
      options: ['Fintech', 'HealthTech', 'Other'],
      drop: true,
      otherHint: 'Type a sector, e.g. SportsTech',
    ),
    AdvancedSearchGroup(title: 'Stage', options: ['Seed', 'Series A']),
    AdvancedSearchGroup(
      title: 'City',
      options: ['Riyadh', 'Jeddah'],
      drop: true,
    ),
  ];

  late List<AdvancedSelection> drafts;

  Future<void> pump(
    WidgetTester t, {
    AdvancedSelection initial = const {},
  }) async {
    t.view.physicalSize = const Size(1236, 2676);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    drafts = [];
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AdvancedSearchSheet(
              groups: groups,
              initial: initial,
              countFor: (d) {
                drafts.add({
                  for (final e in d.entries) e.key: {...e.value},
                });
                return 3;
              },
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  /// The write-in box of the picker (the search box is the first field).
  Finder otherBox() => find.byType(TextField).last;

  testWidgets('a long list is a dropdown, a short one stays chips', (t) async {
    await pump(t);
    expect(find.text('Select sector'), findsOneWidget);
    expect(find.text('Select city'), findsOneWidget);
    // The stage options are chips; the sector options are not on the sheet.
    expect(find.text('Seed'), findsOneWidget);
    expect(find.text('Fintech'), findsNothing);
  });

  testWidgets('Other shows the same text box as everywhere else', (t) async {
    await pump(t);
    await t.tap(find.text('Select sector'));
    await t.pumpAndSettle();
    expect(find.text('Fintech'), findsOneWidget);
    expect(find.text('Type a sector, e.g. SportsTech'), findsNothing);
    await t.tap(find.text('Other'));
    await t.pumpAndSettle();
    // The box is in the picker, with the helper line of a filter.
    expect(otherBox(), findsOneWidget);
    expect(
      find.text('Leave empty to see every sector not in the list'),
      findsOneWidget,
    );
    await t.enterText(otherBox(), 'SportsTech');
    await t.pumpAndSettle();
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    // The select box shows what was typed; the draft has it as one filter.
    expect(find.text('Other: SportsTech'), findsOneWidget);
    expect(drafts.last['Sector'], {'Other'});
    expect(drafts.last['__other:Sector'], {'SportsTech'});
    expect(find.text('Show 3 results'), findsOneWidget);
  });

  testWidgets('Other with nothing typed is a valid filter (not in the list)', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('Select sector'));
    await t.pumpAndSettle();
    await t.tap(find.text('Other'));
    await t.pumpAndSettle();
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(
      find.text('Please type your sector — it can’t be blank.'),
      findsNothing,
    );
    expect(find.text('Other'), findsOneWidget);
    expect(drafts.last['Sector'], {'Other'});
    expect(drafts.last.containsKey('__other:Sector'), isFalse);
  });

  testWidgets('typing a sector that is in the list ticks that one, not Other', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('Select sector'));
    await t.pumpAndSettle();
    await t.tap(find.text('Other'));
    await t.pumpAndSettle();
    // Capital letters, spaces and a plural do not make it different. After a
    // short pause the listed sector is ticked and Other goes, with its text.
    await t.enterText(otherBox(), 'Fin Techs');
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();
    expect(drafts.last['Sector'], {'Fintech'});
    expect(drafts.last.containsKey('__other:Sector'), isFalse);
    expect(find.text('Type a sector, e.g. SportsTech'), findsNothing);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(find.text('Fintech'), findsOneWidget);
    expect(find.text('Other'), findsNothing);
  });

  testWidgets('a different text stays as Other', (t) async {
    await pump(t);
    await t.tap(find.text('Select sector'));
    await t.pumpAndSettle();
    await t.tap(find.text('Other'));
    await t.pumpAndSettle();
    await t.enterText(otherBox(), 'Fintech Labs');
    await t.pumpAndSettle();
    expect(
      find.text('This option is already in the list. Select it instead.'),
      findsNothing,
    );
    expect(drafts.last['Sector'], {'Other'});
    expect(drafts.last['__other:Sector'], {'Fintech Labs'});
  });

  testWidgets('unticking Other forgets what was typed', (t) async {
    await pump(
      t,
      initial: {
        'Sector': {'Other'},
        '__other:Sector': {'SportsTech'},
      },
    );
    expect(find.text('Other: SportsTech'), findsOneWidget);
    await t.tap(find.text('Other: SportsTech'));
    await t.pumpAndSettle();
    await t.tap(find.text('Other'));
    await t.pumpAndSettle();
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.text('Select sector'), findsOneWidget);
    expect(drafts.last.containsKey('__other:Sector'), isFalse);
  });

  testWidgets('Clear all empties the choice and the text', (t) async {
    await pump(
      t,
      initial: {
        'Sector': {'Other'},
        '__other:Sector': {'SportsTech'},
      },
    );
    await t.tap(find.text('Clear all'));
    await t.pumpAndSettle();
    expect(find.text('Other: SportsTech'), findsNothing);
    expect(find.text('Select sector'), findsOneWidget);
  });
}
