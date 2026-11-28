import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/founder_tools_strings.dart';
import 'package:startsa/app_constants/validation_strings.dart';
import 'package:startsa/features/startups/widgets/founder_details_sheet.dart';
import 'package:startsa/models/team_member.dart';

void main() {
  Future<void> open(WidgetTester tester, TeamMember me) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showFounderDetailsSheet(context, startupId: 's1', me: me),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  const empty = TeamMember(
    name: 'Layan',
    role: '',
    contribution: '',
    isFounder: true,
  );

  testWidgets('Save with empty fields shows the team step errors', (
    tester,
  ) async {
    await open(tester, empty);
    expect(find.text(FounderToolsStrings.titleYourDetails), findsOneWidget);
    await tester.tap(find.text(FounderToolsStrings.saveMemberButton));
    await tester.pumpAndSettle();
    expect(find.text(ValidationStrings.memberRoleRequired), findsOneWidget);
    expect(
      find.text(ValidationStrings.memberContributionRequired),
      findsOneWidget,
    );
    expect(find.text(FounderToolsStrings.titleYourDetails), findsOneWidget);
  });

  testWidgets('it can not be closed with back or a tap outside', (
    tester,
  ) async {
    await open(tester, empty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text(FounderToolsStrings.titleYourDetails), findsOneWidget);
  });

  testWidgets('a role with numbers is refused', (tester) async {
    await open(tester, empty);
    await tester.enterText(find.byType(EditableText).first, 'CTO 2');
    await tester.pump();
    expect(find.text(ValidationStrings.memberRoleNoNumbers), findsOneWidget);
  });

  testWidgets('an existing role and contribution are filled in', (
    tester,
  ) async {
    await open(
      tester,
      const TeamMember(
        name: 'Layan',
        role: 'CTO',
        contribution: 'Builds the app',
        isFounder: true,
      ),
    );
    expect(find.text('CTO'), findsOneWidget);
    expect(find.text('Builds the app'), findsOneWidget);
  });
}
