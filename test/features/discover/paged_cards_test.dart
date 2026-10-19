import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/search/widgets/home_layout.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';

HomeItem _item(int i) => HomeItem(
  kind: HomeItemKind.startup,
  id: 's$i',
  name: 'Startup $i',
  initials: 'S$i',
  tag: 'Fintech',
  city: 'Riyadh',
  line: 'Line $i',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a long list builds 20 cards and grows by pages', (t) async {
    t.view.physicalSize = const Size(412, 20000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final items = [for (var i = 0; i < 45; i++) _item(i)];
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: PagedCards(items: items)),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(HomeItemCard), findsNWidgets(20));
    expect(find.text('Show more (25 more)'), findsOneWidget);

    await t.tap(find.text('Show more (25 more)'));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(HomeItemCard), findsNWidgets(40));
    expect(find.text('Show more (5 more)'), findsOneWidget);

    await t.tap(find.text('Show more (5 more)'));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(HomeItemCard), findsNWidgets(45));
    expect(find.textContaining('Show more'), findsNothing);
  });

  testWidgets('a different list starts again from the first page', (t) async {
    t.view.physicalSize = const Size(412, 20000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final all = [for (var i = 0; i < 45; i++) _item(i)];
    Widget app(List<HomeItem> items) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(child: PagedCards(items: items)),
      ),
    );
    await t.pumpWidget(app(all));
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text('Show more (25 more)'));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(HomeItemCard), findsNWidgets(40));
    await t.pumpWidget(app(all.sublist(5)));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(HomeItemCard), findsNWidgets(20));
  });

  testWidgets('a very long description stops at 3 lines with an ellipsis', (
    t,
  ) async {
    t.view.physicalSize = const Size(412, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final long = List.filled(80, 'Backing early-stage founders').join(' ');
    final item = HomeItem(
      kind: HomeItemKind.investor,
      id: 'i1',
      name: 'Ahmad Hassan',
      initials: 'AH',
      tag: 'Fintech',
      city: 'Riyadh',
      line: long,
    );
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: PagedCards(items: [item])),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    final text = t.widget<Text>(find.text(long));
    expect(text.maxLines, 3);
    expect(text.overflow, TextOverflow.ellipsis);
    final lineHeight = 23.0;
    expect(
      t.getSize(find.text(long)).height,
      lessThanOrEqualTo(lineHeight * 3 + 1),
    );
  });
}
