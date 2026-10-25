import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/profiles/screens/edit_account_screen.dart';
import 'package:startsa/features/profiles/view_models/edit_account_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/shared_ui/widgets/forms/app_field.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../../support/fakes.dart';

const _bare = AppUser(
  uid: 'u2',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
  phone: '509876543',
  city: 'Riyadh',
);

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
  phone: '551234567',
  city: 'Riyadh',
  bio: 'Building things.',
  sectorsOfInterest: ['HealthTech'],
);

Future<void> _pump(WidgetTester t, Widget home) async {
  await t.binding.setSurfaceSize(const Size(412, 6000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    MaterialApp(navigatorKey: AppToast.navigatorKey, home: home),
  );
  await t.pump(const Duration(milliseconds: 800));
}

void main() {
  _extraTests();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('an investor with no saved answers opens in the right order', (
    t,
  ) async {
    await _pump(t, const EditProfileScreen(user: _bare));
    expect(t.takeException(), isNull);
    final order = [
      'Profile Photo',
      'Full Name',
      'Bio',
      'Email Address',
      'Phone Number',
      'LinkedIn Profile',
      'Which city are you in?',
      'What can you offer startups?',
      'What are you looking for in startups?',
      'How many years have you been investing?',
      'How many startups have you invested in so far?',
      'Have you ever led an investment round?',
      'Which sectors are you interested in?',
      'Which stages do you invest in?',
      'Which commerce models do you invest in?',
    ];
    var last = -1.0;
    for (final label in order) {
      final f = find.textContaining(label, findRichText: true);
      expect(f, findsWidgets, reason: label);
      final y = t.getTopLeft(f.first).dy;
      expect(y, greaterThan(last), reason: '$label is out of order');
      last = y;
    }
    // Deals not answered yet: the amount row is not there.
    expect(find.text('Minimum'), findsNothing);
    expect(find.textContaining('Select all that apply'), findsNothing);
  });

  testWidgets('investor and founder edit forms share the same spacing', (
    t,
  ) async {
    Future<({Set<double> gaps, Set<double> lefts, Set<double> rights})> measure(
      AppUser u,
    ) async {
      await _pump(t, const SizedBox());
      await _pump(t, EditProfileScreen(user: u));
      final rects = [
        for (final e in find.byType(AppField).evaluate())
          t.getRect(find.byWidget(e.widget)),
      ]..sort((a, b) => a.top.compareTo(b.top));
      return (
        gaps: {
          for (var i = 1; i < rects.length; i++)
            (rects[i].top - rects[i - 1].bottom).roundToDouble(),
        },
        lefts: {for (final r in rects) r.left.roundToDouble()},
        rights: {for (final r in rects) r.right.roundToDouble()},
      );
    }

    final founder = await measure(_founder);
    final investor = await measure(_bare);
    expect(investor.gaps, founder.gaps);
    expect(investor.lefts, founder.lefts);
    expect(investor.rights, founder.rights);
  });

  test('changing the deals answer to 0 saves no round size', () async {
    final users = FakeUserRepository();
    final user = _bare.copyWith(
      bio: 'Angel investor.',
      valueOffered: 'Mentoring.',
      gain: 'Strong teams.',
      investorCriteria: const InvestorCriteria(
        yearsInvesting: '4–6 years',
        dealsCount: '4–6',
        roundMin: 50000,
        roundMax: 100000,
        hasLedRound: false,
        sectors: ['HealthTech'],
        stages: ['Seed'],
        commerceModels: ['Business-to-Business (B2B)'],
      ),
    );
    final vm = EditAccountViewModel(user: user, userRepository: users);
    expect(vm.criteria!.roundSize.minAmount, 50000);
    vm.criteria!.pickDeals('0');
    expect(vm.criteria!.showRoundSize, isFalse);
    final saved = await vm.submit();
    expect(saved, isNotNull);
    expect(saved!.investorCriteria!.dealsCount, '0');
    expect(saved.investorCriteria!.roundMin, isNull);
    expect(saved.investorCriteria!.roundMax, isNull);
    vm.dispose();
  });
}

void _extraTests() {
  testWidgets('Discard leaves the screen and Keep editing stays', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 6000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: AppToast.navigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EditProfileScreen(user: _bare),
                  ),
                ),
                child: const Text('open edit'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open edit'));
    await t.pumpAndSettle();
    expect(find.textContaining('Full Name', findRichText: true), findsWidgets);
    // Change something, then close.
    await t.enterText(find.byType(TextField).first, 'Layan Changed');
    await t.pump();
    await t.tap(find.bySemanticsLabel('Close'));
    await t.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await t.tap(find.text('Keep editing'));
    await t.pumpAndSettle();
    expect(find.textContaining('Full Name', findRichText: true), findsWidgets);
    await t.tap(find.bySemanticsLabel('Close'));
    await t.pumpAndSettle();
    await t.tap(find.text('Discard'));
    await t.pumpAndSettle();
    expect(find.text('open edit'), findsOneWidget);
  });
}
