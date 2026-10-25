import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/features/login_and_signup/screens/investor_interests_screen.dart';
import 'package:startsa/features/login_and_signup/screens/investor_investments_screen.dart';
import 'package:startsa/features/login_and_signup/screens/signup_screen.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_flow.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/shared_ui/widgets/forms/app_field.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../../support/fakes.dart';

const _investor = AppUser(
  uid: 'u1',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
  phone: '509876543',
  city: 'Riyadh',
);

Future<void> _pump(WidgetTester t, Widget home) async {
  await t.binding.setSurfaceSize(const Size(412, 4000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    MaterialApp(navigatorKey: AppToast.navigatorKey, home: home),
  );
  await t.pump(const Duration(milliseconds: 800));
}

/// The vertical gap between each field and the next, and the left / right
/// margin of every field.
({Set<double> gaps, Set<double> lefts, Set<double> rights}) _measure(
  WidgetTester t,
) {
  final rects = [
    for (final e in find.byType(AppField).evaluate())
      t.getRect(find.byWidget(e.widget)),
  ]..sort((a, b) => a.top.compareTo(b.top));
  final gaps = <double>{};
  for (var i = 1; i < rects.length; i++) {
    gaps.add((rects[i].top - rects[i - 1].bottom).roundToDouble());
  }
  return (
    gaps: gaps,
    lefts: {for (final r in rects) r.left.roundToDouble()},
    rights: {for (final r in rects) r.right.roundToDouble()},
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AuthRepository.instance = FakeAuthRepository());

  testWidgets('founder and investor sign-up share the same spacing', (t) async {
    await _pump(
      t,
      SignupScreen(
        role: AccountRole.founder,
        flow: SignupFlow(role: AccountRole.founder),
      ),
    );
    final founder = _measure(t);
    await _pump(
      t,
      SignupScreen(
        role: AccountRole.investor,
        flow: SignupFlow(role: AccountRole.investor),
      ),
    );
    final investor = _measure(t);
    expect(investor.gaps, founder.gaps);
    expect(investor.lefts, founder.lefts);
    expect(investor.rights, founder.rights);
    expect(investor.gaps.length, 1);
  });

  testWidgets('steps 3 and 4 use the sign-up field gap', (t) async {
    final reference = await () async {
      await _pump(
        t,
        SignupScreen(
          role: AccountRole.founder,
          flow: SignupFlow(role: AccountRole.founder),
        ),
      );
      return _measure(t);
    }();

    await _pump(t, const InvestorInvestmentsScreen(user: _investor));
    final step3 = _measure(t);

    final vm = InvestorOnboardingViewModel(user: _investor);
    addTearDown(vm.dispose);
    await _pump(t, InvestorInterestsScreen(viewModel: vm));
    final step4 = _measure(t);

    for (final m in [step3, step4]) {
      expect(m.gaps, reference.gaps);
      expect(m.lefts, reference.lefts);
      expect(m.rights, reference.rights);
    }
  });
}
