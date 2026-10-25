import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/shared_ui/widgets/forms/select_field.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_bottom_sheet.dart';
import 'package:startsa/models/app_user.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
);

Future<StartupStepsViewModel> _pump(
  WidgetTester t,
  int step, {
  Size size = const Size(360, 740),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final vm = StartupStepsViewModel();
  vm.selectStage('Pre-seed');
  addTearDown(vm.dispose);
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: StartupStepBody(vm: vm, step: step),
        ),
      ),
    ),
  );
  return vm;
}

/// The open / close animation starts on the first frame and runs on the next.
Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    AppSession.instance = AppSession();
    AppSession.instance.signIn(_founder);
  });

  testWidgets('Finance and Growth: fields, order and live runway', (t) async {
    final vm = await _pump(t, 3);
    for (final label in [
      'Current financial year revenue',
      'Current available capital',
      'Monthly burn rate',
      'Current company valuation',
      'Expected revenue, next 3 years (SAR)',
      'Explain your business model',
    ]) {
      expect(
        find.textContaining(label, findRichText: true),
        findsOneWidget,
        reason: label,
      );
    }
    expect(find.textContaining('growth', findRichText: true), findsNothing);
    vm.capital.text = '300,000';
    vm.burn.text = '100,000';
    await t.pump();
    expect(find.text('About 3 months of runway'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Startup Ask: boxes reveal their own questions', (t) async {
    await _pump(t, 4, size: const Size(360, 1400));
    expect(find.text('Funding'), findsOneWidget);
    expect(find.text('Partnership'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.textContaining('How much are you raising?'), findsNothing);
    await t.tap(find.text('Funding'));
    await _settle(t);
    expect(
      find.textContaining('How much are you raising?', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Pre-seed: SAR 150,000 to 2,000,000'), findsOneWidget);
    expect(
      find.textContaining('already raised', findRichText: true),
      findsOneWidget,
    );
    await t.tap(find.text('Partnership'));
    await _settle(t);
    expect(
      find.textContaining('What type of partner', findRichText: true),
      findsOneWidget,
    );
    await t.tap(find.byType(SelectField).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Select partner types'), findsNWidgets(2));
    expect(find.text('Distribution'), findsOneWidget);
    expect(find.text('Corporate'), findsOneWidget);
    // Like the Stage / Commerce model pickers: as tall as its options (not
    // a whole page), growing by the text box when Other is ticked.
    final height = t.getSize(find.byType(AppSheetScaffold)).height;
    expect(height, lessThan(700));
    await t.tap(find.text('Other').last);
    await _settle(t);
    expect(
      t.getSize(find.byType(AppSheetScaffold)).height,
      greaterThan(height),
    );
    expect(find.text('Type your other partner type'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Startup Ask: each question opens under its own card', (t) async {
    final vm = await _pump(t, 4);
    double y(String text) =>
        t.getTopLeft(find.textContaining(text, findRichText: true).first).dy;
    // Tick in a "wrong" order: Support, then Funding, then Partnership.
    await t.tap(find.text('Support'));
    await _settle(t);
    await t.tap(find.text('Funding'));
    await _settle(t);
    await t.tap(find.text('Partnership'));
    await _settle(t);
    final order = [
      y('Funding'),
      y('How much are you raising?'),
      y('already raised'),
      y('lead investor'),
      y('Partnership'),
      y('What type of partner'),
      y('Support'),
      y('What type of support'),
    ];
    final sorted = [...order]..sort();
    expect(order, sorted);
    // Unticking hides only its own questions and keeps what was typed.
    vm.funding.text = '1,000,000';
    await t.tap(find.text('Funding'));
    await _settle(t);
    expect(find.textContaining('How much are you raising?'), findsNothing);
    expect(
      find.textContaining('What type of partner', findRichText: true),
      findsOneWidget,
    );
    expect(vm.funding.text, '1,000,000');
    expect(t.takeException(), isNull);
  });

  testWidgets('Startup Team: founder card first with its tag', (t) async {
    await _pump(t, 5);
    expect(find.text('Shahad Alabdulkarim'), findsOneWidget);
    expect(find.text('You · Founder'), findsOneWidget);
    expect(find.text('Add team member'), findsOneWidget);
    expect(find.textContaining('Including you as a founder'), findsOneWidget);
    await t.tap(find.text('Add team member'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Add member'), findsOneWidget);
    expect(find.text('Co-founder'), findsOneWidget);
    expect(
      find.textContaining('Contribution', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Specialization', findRichText: true),
      findsNothing,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('Startup Team: card, tags, editor and invite dialog', (t) async {
    final vm = await _pump(t, 5, size: const Size(360, 1400));
    // My card: tag, "Add your role" until it is filled in, pencil label.
    expect(find.text('You · Founder'), findsOneWidget);
    expect(find.text('Add your role'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit Shahad Alabdulkarim'), findsOneWidget);
    // My editor replaces my card: locked name and e-mail, no Co-founder box.
    await t.tap(find.bySemanticsLabel('Edit Shahad Alabdulkarim'));
    await _settle(t);
    expect(find.text('Your details'), findsOneWidget);
    expect(find.text('Add team member'), findsNothing, reason: 'hidden');
    expect(find.text('shahad@gmail.com'), findsOneWidget);
    expect(find.text('Co-founder'), findsNothing);
    expect(find.text('Remove this member'), findsNothing);
    expect(find.text('Save'), findsOneWidget);
    vm.memberRole.text = 'CEO';
    vm.memberContribution.text = 'Leads the company';
    await t.pump();
    await t.tap(find.text('Save'));
    await _settle(t);
    expect(find.text('CEO'), findsOneWidget);
    expect(find.text('Add team member'), findsOneWidget);
    // A new member: "Add member", Co-founder box, no Remove.
    await t.tap(find.text('Add team member'));
    await _settle(t);
    expect(find.text('New team member'), findsOneWidget);
    expect(find.text('Add member'), findsOneWidget);
    expect(find.text('Co-founder'), findsOneWidget);
    expect(find.text('Remove this member'), findsNothing);
    vm.memberName.text = 'Sara Alamri';
    vm.memberEmail.text = 'sara.alamri@gmail.com';
    vm.memberRole.text = 'COO';
    vm.memberContribution.text = 'Operations';
    await t.pump();
    await t.tap(find.text('Add member'));
    await _settle(t);
    expect(find.text('This person isn’t on Start.sa yet'), findsOneWidget);
    expect(find.text('Send invite'), findsOneWidget);
    await t.tap(find.text('Send invite'));
    await _settle(t);
    expect(find.text('Invited'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit Sara Alamri'), findsOneWidget);
    // Editing an existing member: Remove is there.
    await t.tap(find.bySemanticsLabel('Edit Sara Alamri'));
    await _settle(t);
    expect(find.text('Edit team member'), findsOneWidget);
    expect(find.text('Remove this member'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    expect(t.takeException(), isNull);
  });
}
