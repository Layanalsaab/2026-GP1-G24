import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:startsa/shared_ui/widgets/cards/avatars.dart';
import 'package:startsa/shared_ui/widgets/cards/charts.dart';
import 'package:startsa/shared_ui/widgets/cards/home_card.dart';
import 'package:startsa/shared_ui/widgets/lists/segmented_switch.dart';
import 'package:startsa/shared_ui/widgets/nav/app_bottom_nav.dart';
import 'package:startsa/shared_ui/widgets/nav/home_search_bar.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_bottom_sheet.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_dropdown.dart';

Widget _wrap(Widget child) => MaterialApp(
  navigatorKey: AppToast.navigatorKey,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('initials rule', () {
    expect(appInitials('Shahad Alabdulkarim'), 'SA');
    expect(appInitials('Naql'), 'NA');
    expect(appInitials(''), '');
  });

  testWidgets('home card, switch, nav', (tester) async {
    var idx = 0;
    var nav = 1;
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, set) => Column(
            children: [
              HomeCard(
                name: 'Ahmad Hassan',
                tag: 'HealthTech',
                city: 'Riyadh',
                body: 'Backing early-stage founders.',
                kind: HueAvatarKind.investor,
                onTap: () => taps++,
                onShare: () {},
                onBookmark: () {},
                matchPercent: 92,
                matchReason: 'Same sector',
              ),
              SegmentedSwitch(
                labels: const ['Startups', 'Investors'],
                selectedIndex: idx,
                onChanged: (i) => set(() => idx = i),
              ),
              AppBottomNav(
                currentIndex: nav,
                onSelect: (i) => set(() => nav = i),
              ),
              AreaChart(
                values: const [1, 3, 2, 5],
                axisLabels: const ['a', 'b'],
              ),
              const RevenueBars(
                values: [1, 4, 9],
                labels: ['Year 1', 'Year 2', 'Year 3'],
                valueLabels: ['1M', '4M', '9M'],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('92% match'), findsOneWidget);
    await tester.tap(find.text('Investors'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(idx, 1);
    await tester.tap(find.bySemanticsLabel('Explore'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(nav, 2);
  });

  testWidgets('toast and sheet', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (c) => Column(
            children: [
              TextButton(
                onPressed: () => AppToast.show(c, 'Link copied'),
                child: const Text('t'),
              ),
              TextButton(
                onPressed: () => showInfoSheet(c, title: 'Title', text: 'Body'),
                child: const Text('s'),
              ),
              RangeDropdown(
                options: const ['Today', 'Last 7 days'],
                selectedIndex: 1,
                onSelected: (_) {},
              ),
              const SizedBox(height: 40),
              HomeSearchBar(
                controller: TextEditingController(),
                onFilterTap: () {},
                activeCount: 2,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('t'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Link copied'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Link copied'), findsNothing);

    await tester.tap(find.text('s'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsNothing);

    await tester.tap(find.text('Last 7 days'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing);
  });
}
