// Pulling a page down reads its data again, so a change made elsewhere (a
// teammate added you to a startup) shows without logging out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/shared_ui/widgets/cards/home_card.dart';
import 'package:startsa/shared_ui/widgets/lists/app_refresh.dart';

import '../support/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('My Startups: pulling down loads a startup added meanwhile', (
    t,
  ) async {
    final repo = FakeStartupRepository();
    StartupRepository.instance = repo;
    AppSession.instance = AppSession();
    repo.startups.add(PrototypeSeed.rafeeq);
    t.view.physicalSize = const Size(412, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const MaterialApp(home: MyStartupsScreen(teamStartups: [])),
    );
    await t.pumpAndSettle();
    expect(find.byType(HomeCard), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    // Someone added the person to another startup.
    repo.startups.add(PrototypeSeed.daftar);
    await t.fling(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 400),
      1000,
    );
    await t.pumpAndSettle();
    expect(find.byType(HomeCard), findsNWidgets(2));
  });

  testWidgets('a short page can still be pulled', (t) async {
    var calls = 0;
    await t.pumpWidget(
      MaterialApp(
        home: AppRefresh(
          onRefresh: () async => calls++,
          child: const SingleChildScrollView(
            physics: AppRefresh.physics,
            child: SizedBox(height: 50, child: Text('short')),
          ),
        ),
      ),
    );
    await t.fling(find.text('short'), const Offset(0, 300), 1000);
    await t.pumpAndSettle();
    expect(calls, 1);
  });
}
