import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/matching_repository.dart';
import 'package:startsa/data_access/repositories/ticket_repository.dart';
import 'package:startsa/features/wallet/screens/wallet_screen.dart';
import 'package:startsa/features/wallet/view_models/wallet_view_model.dart';
import 'package:startsa/models/investment_ticket.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/chips/app_chip.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_dialog.dart';
import 'package:startsa/shared_ui/widgets/overlays/multi_picker_sheet.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import 'wallet_logic_test.dart' hide main;

/// The public startups for the matches (Rafeeq Health: HealthTech, Pre-seed,
/// raising SAR 500,000).
class StartupsFirestore extends MemoryFirestore {
  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async {
    if (collection == FirestoreCollections.startups) {
      final s = PrototypeSeed.rafeeq;
      return [(id: s.id, data: Map<String, dynamic>.from(s.toMap()))];
    }
    return super.queryWhereEqual(collection, field, value, limit: limit);
  }
}

late StartupsFirestore db;

Future<WalletViewModel> open(
  WidgetTester t, {
  List<InvestmentTicket> tickets = const [],
}) async {
  t.view.physicalSize = const Size(1236, 2676);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  for (final x in tickets) {
    (db.store[FirestoreCollections.tickets] ??= {})[x.id] = ticketDoc(
      x,
      created: DateTime.now().subtract(const Duration(days: 2)),
    );
  }
  final vm = WalletViewModel(
    investorId: 'inv1',
    tickets: TicketRepository(firestore: db),
    matching: MatchingRepository(firestore: db, live: false),
  );
  vm.setOptionOrder(
    sectors: const ['HealthTech', 'Fintech', 'Logistics'],
    stages: const ['Pre-seed', 'Seed'],
  );
  await vm.load();
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      navigatorKey: AppToast.navigatorKey,
      home: WalletScreen(viewModel: vm),
    ),
  );
  await t.pumpAndSettle();
  return vm;
}

/// Scrolls [finder] into view and taps it, like a person would.
Future<void> press(WidgetTester t, Finder finder) async {
  // A dialog is always on screen; only the page scrolls.
  if (find.byType(AppDialog).evaluate().isEmpty) {
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
  }
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => db = StartupsFirestore());

  testWidgets('empty wallet: heading, hint text and the add button', (t) async {
    await open(t);
    expect(find.text('Investment Wallet'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Investment tickets'), findsOneWidget);
    expect(find.text('All amounts in SAR'), findsOneWidget);
    expect(find.text('Add ticket'), findsOneWidget);
    expect(
      find.text(
        'No tickets yet. Add one to see startups that fit what you want to invest in.',
      ),
      findsOneWidget,
    );
    // The table header and the "tap" hint only appear with tickets.
    expect(find.text('TICKET'), findsOneWidget);
    expect(find.text('Tap a ticket to see its details.'), findsNothing);
  });

  testWidgets('the table: dot name, status word, sectors, amount, matches', (
    t,
  ) async {
    await open(
      t,
      tickets: [
        ticket(id: 'inv1-T1', sectors: ['HealthTech', 'Fintech', 'Logistics']),
        ticket(
          id: 'inv1-T2',
          name: 'Ticket 2',
          sectors: ['Fintech'],
          min: 200000,
          max: 400000,
          status: TicketStatus.closed,
        ),
      ],
    );
    expect(find.text('Ticket 1'), findsOneWidget);
    expect(find.text('Ticket 2'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    // At most two sectors, then +N.
    expect(find.text('HealthTech, Fintech +1 · Pre-seed'), findsOneWidget);
    expect(find.text('100K – 300K'), findsOneWidget);
    expect(find.text('200K – 400K'), findsOneWidget);
    expect(find.text('1 match'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Tap a ticket to see its details.'), findsOneWidget);
  });

  testWidgets('Add ticket: invalid shows the errors, valid asks to confirm', (
    t,
  ) async {
    final vm = await open(t);
    await press(t, find.text('Add ticket'));
    expect(find.text('New ticket'), findsOneWidget);
    // The default name.
    expect(find.text('Ticket 1'), findsOneWidget);
    // No limit from what the investor usually invests: no such hint.
    expect(find.textContaining('usual ticket size'), findsNothing);

    // Gray until valid: tapping shows the errors, no confirm.
    await press(t, find.text('Add ticket').last);
    expect(find.text('Select at least one sector.'), findsOneWidget);
    expect(find.text('Select at least one stage.'), findsOneWidget);
    expect(find.text('Enter the minimum amount.'), findsOneWidget);
    expect(find.text('Enter the maximum amount.'), findsOneWidget);
    expect(find.text('Add ticket?'), findsNothing);

    // Fill it in.
    vm.toggleSector('HealthTech');
    vm.toggleStage('Pre-seed');
    vm.min.text = '100,000';
    vm.max.text = '300,000';
    await t.pumpAndSettle();
    await press(t, find.text('Add ticket').last);
    expect(find.text('Add ticket?'), findsOneWidget);
    expect(
      find.text('This ticket will be added to your wallet.'),
      findsOneWidget,
    );

    await press(t, find.text('Add ticket').last);
    expect(find.text('Ticket added'), findsOneWidget);
    expect(find.text('New ticket'), findsNothing);
    expect(find.text('100K – 300K'), findsOneWidget);
    expect(db.store[FirestoreCollections.tickets]!.keys, ['inv1-T1']);
    // Let the toast go away.
    await t.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Cancel: the default name alone closes it, a change asks first', (
    t,
  ) async {
    final vm = await open(t);
    await press(t, find.text('Add ticket'));
    await press(t, find.text('Cancel'));
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('New ticket'), findsNothing);

    await press(t, find.text('Add ticket'));
    vm.toggleSector('HealthTech');
    await t.pumpAndSettle();
    await press(t, find.text('Cancel'));
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(
      find.text('If you go back now, your changes will be lost.'),
      findsOneWidget,
    );
    await press(t, find.text('Keep editing'));
    expect(find.text('New ticket'), findsOneWidget);
    await press(t, find.text('Cancel'));
    await press(t, find.text('Discard'));
    expect(find.text('New ticket'), findsNothing);
  });

  group('Other in the sectors (the same box as everywhere)', () {
    Future<void> openSectors(WidgetTester t) async {
      await press(t, find.text('Add ticket'));
      await press(t, find.text('Select sectors'));
      // The list is long: search for Other.
      await t.enterText(
        find
            .descendant(
              of: find.byType(MultiPickerSheet),
              matching: find.byType(TextField),
            )
            .first,
        'other',
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Other'));
      await t.pumpAndSettle();
    }

    Finder box() => find
        .descendant(
          of: find.byType(MultiPickerSheet),
          matching: find.byType(TextField),
        )
        .last;

    testWidgets('Other shows a text box; the typed sector is the ticket\'s', (
      t,
    ) async {
      final vm = await open(t);
      await openSectors(t);
      expect(find.text('Type a sector, e.g. SportsTech'), findsOneWidget);
      await t.enterText(box(), 'SportsTech');
      await t.pumpAndSettle();
      await press(t, find.text('Done'));
      // The select box shows what was typed, not "Other".
      expect(find.text('SportsTech'), findsOneWidget);
      vm.toggleStage('Seed');
      vm.min.text = '100,000';
      vm.max.text = '300,000';
      await t.pumpAndSettle();
      expect(vm.formValid, isTrue);
      expect(vm.sectorsToSave, ['SportsTech']);
    });

    testWidgets('Other left blank is refused, like in the forms', (t) async {
      await open(t);
      await openSectors(t);
      await press(t, find.text('Done'));
      expect(
        find.text('Please type your sector — it can’t be blank.'),
        findsOneWidget,
      );
      // Still open: write something to go on.
      await t.enterText(box(), 'Esports');
      await t.pumpAndSettle();
      await press(t, find.text('Done'));
      expect(find.text('Esports'), findsOneWidget);
    });

    testWidgets('a sector that is in the list ticks that one, not Other', (
      t,
    ) async {
      final vm = await open(t);
      await openSectors(t);
      // Capitals, spaces and a plural do not make it different. After a short
      // pause the listed sector is ticked and Other goes, with its text.
      await t.enterText(box(), 'health techs');
      await t.pump(const Duration(milliseconds: 700));
      await t.pumpAndSettle();
      expect(vm.sectors, {'HealthTech'});
      expect(vm.sectorOther, '');
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(find.text('HealthTech'), findsOneWidget);
      expect(find.text('Other'), findsNothing);
    });
  });

  testWidgets('the minimum amount is SAR 1,000', (t) async {
    final vm = await open(t);
    await press(t, find.text('Add ticket'));
    vm.min.text = '999';
    await t.pumpAndSettle();
    expect(
      find.text('The minimum must be at least SAR 1,000.'),
      findsOneWidget,
    );
    vm.min.text = '1,000';
    vm.max.text = '999';
    await t.pumpAndSettle();
    expect(find.text('The minimum must be at least SAR 1,000.'), findsNothing);
    expect(
      find.text('The maximum must be at least SAR 1,000.'),
      findsOneWidget,
    );
    vm.max.text = '1,000';
    await t.pumpAndSettle();
    expect(
      find.text('The maximum must be more than the minimum.'),
      findsOneWidget,
    );
    vm.max.text = '5,000';
    await t.pumpAndSettle();
    expect(find.textContaining('The maximum must'), findsNothing);
    expect(find.textContaining('The minimum must'), findsNothing);
  });

  testWidgets('the ticket page: card, requests, matches, edit and close', (
    t,
  ) async {
    await open(
      t,
      tickets: [ticket(id: 'inv1-T1', name: 'Health bets')],
    );
    await press(t, find.text('Health bets'));
    expect(find.text('All tickets'), findsOneWidget);
    expect(find.text('HealthTech · Pre-seed'), findsWidgets);
    expect(find.text('Minimum'), findsOneWidget);
    expect(find.text('SAR 100,000'), findsOneWidget);
    expect(find.text('SAR 300,000'), findsOneWidget);
    expect(find.text('Created 2d ago'), findsOneWidget);
    expect(find.text('Edit ticket'), findsOneWidget);
    expect(find.text('Close ticket'), findsOneWidget);
    expect(find.text('Requests'), findsWidgets);
    expect(find.text('Sent with this ticket'), findsOneWidget);
    expect(find.text('No requests sent with this ticket yet.'), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('Open rounds that fit this ticket'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rafeeq Health'), findsOneWidget);
    expect(find.text('HealthTech · Pre-seed'), findsWidgets);
    expect(find.text('Raising · SAR 500,000 left'), findsOneWidget);
    expect(find.text('83% match'), findsOneWidget);
    expect(find.text('Same sector and stage'), findsOneWidget);

    // Back on the list.
    await t.scrollUntilVisible(
      find.text('All tickets'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await press(t, find.text('All tickets'));
    expect(find.text('Investment tickets'), findsOneWidget);
  });

  testWidgets('Close ticket asks, closes and hides the buttons and matches', (
    t,
  ) async {
    await open(
      t,
      tickets: [ticket(id: 'inv1-T1', name: 'Health bets')],
    );
    await press(t, find.text('Health bets'));
    await press(t, find.text('Close ticket'));
    expect(find.text('Close Health bets?'), findsOneWidget);
    expect(
      find.text(
        'This ticket won’t match any round anymore. You can’t use it after closing it.',
      ),
      findsOneWidget,
    );
    await press(t, find.text('Close ticket').last);
    expect(find.text('Ticket closed'), findsOneWidget);
    expect(find.text('Edit ticket'), findsNothing);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Open rounds that fit this ticket'), findsNothing);
    // Let the toast go away.
    await t.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Edit ticket: the form with the values, Save changes confirms', (
    t,
  ) async {
    final vm = await open(
      t,
      tickets: [ticket(id: 'inv1-T1', name: 'Health bets')],
    );
    await press(t, find.text('Health bets'));
    await press(t, find.text('Edit ticket'));
    // The form replaces the buttons while it is open.
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Close ticket'), findsNothing);
    vm.max.text = '400,000';
    await t.pumpAndSettle();
    await press(t, find.text('Save changes'));
    expect(find.text('Save changes?'), findsOneWidget);
    expect(
      find.text('Your changes will be saved to this ticket.'),
      findsOneWidget,
    );
    await press(t, find.text('Save changes').last);
    expect(find.text('Ticket saved'), findsOneWidget);
    expect(find.text('SAR 400,000'), findsOneWidget);
    // Let the toast go away.
    await t.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Send request: form, errors, confirm, toast and the pill', (
    t,
  ) async {
    final vm = await open(
      t,
      tickets: [ticket(id: 'inv1-T1', name: 'Health bets')],
    );
    await press(t, find.text('Health bets'));
    await t.scrollUntilVisible(
      find.text('Send request'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await press(t, find.text('Send request'));
    expect(find.text('Between SAR 100,000 and SAR 300,000'), findsOneWidget);

    // Nothing typed: the error shows after trying.
    await press(t, find.text('Send request').last);
    expect(find.text('Enter an amount.'), findsOneWidget);
    expect(find.text('Send request?'), findsNothing);

    vm.sendAmount.text = '400,000';
    await t.pumpAndSettle();
    expect(find.text('The most you can send is SAR 300,000.'), findsOneWidget);

    vm.sendAmount.text = '200,000';
    await t.pumpAndSettle();
    await press(t, find.text('Send request').last);
    expect(find.text('Send request?'), findsOneWidget);
    expect(
      find.text('Rafeeq Health will see your request for SAR 200,000.'),
      findsOneWidget,
    );
    await press(t, find.text('Send request').last);
    expect(find.text('Request sent to Rafeeq Health'), findsOneWidget);
    expect(find.text('Request sent'), findsOneWidget);
    // It also shows under "Requests" of the ticket.
    expect(find.text('SAR 200,000 · just now'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    // Let the toast go away.
    await t.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Send request: Cancel closes at once, or asks after a change', (
    t,
  ) async {
    final vm = await open(
      t,
      tickets: [ticket(id: 'inv1-T1', name: 'Health bets')],
    );
    await press(t, find.text('Health bets'));
    await press(t, find.text('Send request'));
    expect(find.text('Between SAR 100,000 and SAR 300,000'), findsOneWidget);
    // Nothing typed: Cancel closes the form with no question.
    await press(t, find.text('Cancel'));
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Between SAR 100,000 and SAR 300,000'), findsNothing);
    // Something typed: Cancel asks first.
    await press(t, find.text('Send request'));
    vm.sendAmount.text = '150,000';
    await t.pumpAndSettle();
    await press(t, find.text('Cancel'));
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(
      find.text('If you go back now, your changes will be lost.'),
      findsOneWidget,
    );
    await press(t, find.text('Keep editing'));
    expect(find.text('Between SAR 100,000 and SAR 300,000'), findsOneWidget);
    await press(t, find.text('Cancel'));
    await press(t, find.text('Discard'));
    expect(find.text('Between SAR 100,000 and SAR 300,000'), findsNothing);
    expect(db.store[FirestoreCollections.requests], isNull);
  });

  testWidgets('the Requests tab: badge, filters, withdraw, cards do not open', (
    t,
  ) async {
    (db.store[FirestoreCollections.requests] ??= {}).addAll({
      'r1': {
        'startupId': 'mock-rafeeq',
        'founderId': 'f',
        'investorId': 'inv1',
        'message': '',
        'amount': 150000,
        'status': 'pending',
        'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
        TicketFields.ticketId: 'inv1-T1',
        TicketFields.startupName: 'Rafeeq Health',
      },
      'r2': {
        'startupId': 'mock-daftar',
        'founderId': 'f',
        'investorId': 'inv1',
        'message': '',
        'amount': 120000,
        'status': 'declined',
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
        TicketFields.ticketId: 'inv1-T1',
        TicketFields.startupName: 'Daftar',
      },
    });
    await open(
      t,
      tickets: [ticket(id: 'inv1-T1', name: 'Health bets')],
    );
    // The badge counts the pending requests.
    expect(find.text('1'), findsOneWidget);
    await press(t, find.text('Requests').first);
    for (final f in ['All', 'Pending', 'Accepted', 'Declined']) {
      expect(find.text(f), findsWidgets);
    }
    expect(find.text('Rafeeq Health'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Ticket: Health bets'), findsNWidgets(2));
    expect(find.text('SAR 150,000'), findsOneWidget);
    expect(find.text('3h ago'), findsOneWidget);

    // A card does not open anything.
    await press(t, find.text('Rafeeq Health'));
    expect(find.text('Rafeeq Health'), findsOneWidget);
    expect(find.text('Investment Wallet'), findsOneWidget);

    // Filter.
    await press(t, find.widgetWithText(AppFilterChip, 'Declined'));
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Rafeeq Health'), findsNothing);
    await press(t, find.widgetWithText(AppFilterChip, 'All'));

    // Only the pending one has Withdraw.
    expect(find.text('Withdraw'), findsOneWidget);
    await press(t, find.text('Withdraw'));
    expect(find.text('Withdraw request?'), findsOneWidget);
    expect(
      find.text('Rafeeq Health will no longer see this request.'),
      findsOneWidget,
    );
    await press(t, find.text('Withdraw').last);
    expect(find.text('Request withdrawn'), findsOneWidget);
    expect(find.text('Rafeeq Health'), findsNothing);
    // Let the toast go away.
    await t.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('no requests: the empty text', (t) async {
    await open(t);
    await press(t, find.text('Requests').first);
    expect(
      find.text('No requests yet. Send one from a matching ticket.'),
      findsOneWidget,
    );
  });
}
