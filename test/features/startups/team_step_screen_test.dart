import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/startups/screens/startup_steps_screen.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/role_tag.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/team_member.dart';

import '../../support/fakes.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Startup Team screen: tags hug their text, button is pinned', (
    t,
  ) async {
    StartupRepository.instance = FakeStartupRepository();
    AppSession.instance = AppSession()..signIn(_founder);
    t.view.physicalSize = const Size(412, 892);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: StartupStepsScreen(
          mode: StartupStepsMode.edit,
          onlySection: StartupStepsViewModel.teamStep,
          startup: PrototypeSeed.rafeeq.copyWith(
            founderId: 'u1',
            team: const [
              TeamMember(
                name: 'Shahad Alabdulkarim',
                email: 'shahad@gmail.com',
                role: 'CEO',
                contribution: 'Leads the company',
                isFounder: true,
                uid: 'u1',
              ),
              TeamMember(
                name: 'Ggg Yyuu',
                email: 'g@example.com',
                role: 'CTO',
                contribution: 'Builds the product',
                coFounder: true,
                invited: true,
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    final button = t.getRect(find.text('Save'));
    expect(button.bottom, lessThanOrEqualTo(892));
    for (final label in ['Co-founder', 'Invited']) {
      final tag = find.ancestor(
        of: find.text(label),
        matching: find.byType(RoleTag),
      );
      final r = t.getRect(tag);
      expect(r.height, 20);
      expect(r.width, lessThan(200), reason: label);
    }
    final founderTag = t.getRect(find.byType(RoleTag).first);
    expect(founderTag.width, lessThan(200));
    expect(t.takeException(), isNull);
    await t.tap(find.text('Add team member'));
    await t.pumpAndSettle();
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await t.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    expect(t.getRect(find.text('Save')).bottom, lessThan(892 - 300));
    expect(t.takeException(), isNull);
  });
}
