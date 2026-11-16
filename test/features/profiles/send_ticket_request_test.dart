import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/ticket_request_repository.dart';
import 'package:startsa/features/profiles/widgets/send_ticket_request_sheet.dart';
import 'package:startsa/features/profiles/widgets/ticket_info_sheet.dart';
import 'package:startsa/models/investment_ticket.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

/// Writes kept in a map: collection -> id -> data.
class _Db extends FirestoreService {
  final Map<String, Map<String, Map<String, Object?>>> store = {};

  @override
  Object serverTimestamp() => DateTime(2026, 11, 16, 12);

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data, {
    bool merge = false,
  }) async => (store[collection] ??= {})[id] = {...data};

  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => [
    for (final e in (store[collection] ?? {}).entries)
      if (e.value[field] == value)
        (id: e.key, data: Map<String, dynamic>.from(e.value)),
  ];
}

final _ticket = InvestmentTicket(
  id: 'i1-T1',
  investorId: 'i1',
  name: 'Health bets',
  sectors: const ['HealthTech', 'Fintech'],
  stages: const ['Pre-seed'],
  amountMin: 100000,
  amountMax: 300000,
  createdAt: DateTime(2026, 11, 1),
);

final _raising = PrototypeSeed.rafeeq.copyWith(
  fundingRequirement: 500000,
  raisedInRound: 100000,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _Db db;
  setUp(() => db = _Db());

  Future<void> pumpSheet(
    WidgetTester t, {
    required List<dynamic> startups,
  }) async {
    t.view.physicalSize = const Size(1236, 2676);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorKey: AppToast.navigatorKey,
        home: Scaffold(
          body: SendTicketRequestSheet(
            ticket: _ticket,
            investorName: 'Faisal',
            startups: [for (final s in startups) s],
            repository: TicketRequestRepository(firestore: db),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  group('the ticket a founder opens', () {
    testWidgets('says everything and ends with Send request', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TicketInfoSheet(ticket: _ticket, canSendRequest: true),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Health bets'), findsOneWidget);
      for (final label in [
        'Status',
        'Sectors',
        'Stages',
        'Minimum',
        'Maximum',
        'Created',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('SAR 100,000'), findsOneWidget);
      expect(find.text('SAR 300,000'), findsOneWidget);
      expect(find.text('1 Nov 2026'), findsOneWidget);
      expect(find.text('Send request'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('anybody else just has Done', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: TicketInfoSheet(ticket: _ticket)),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Send request'), findsNothing);
    });

    testWidgets('a closed ticket takes no request', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TicketInfoSheet(
              ticket: InvestmentTicket(
                id: 'i1-T2',
                investorId: 'i1',
                name: 'Old',
                sectors: const ['Fintech'],
                stages: const ['Seed'],
                amountMin: 1000,
                amountMax: 2000,
                status: TicketStatus.closed,
              ),
              canSendRequest: true,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Send request'), findsNothing);
    });
  });

  group('Send request', () {
    testWidgets('asks for an amount in range, then sends it', (t) async {
      await pumpSheet(t, startups: [_raising]);
      // Round needs 400,000, the ticket stops at 300,000.
      expect(find.text('Between SAR 100,000 and SAR 300,000'), findsOneWidget);
      await t.enterText(find.byType(TextField), '50000');
      await t.pumpAndSettle();
      await t.tap(find.text('Send request').last);
      await t.pumpAndSettle();
      expect(
        find.text('The minimum for this ticket is SAR 100,000.'),
        findsOneWidget,
      );
      expect(db.store[FirestoreCollections.ticketRequests], isNull);

      await t.enterText(find.byType(TextField), '250000');
      await t.pumpAndSettle();
      await t.tap(find.text('Send request').last);
      await t.pumpAndSettle();
      final sent = db.store[FirestoreCollections.ticketRequests]!;
      expect(sent.keys, ['${_raising.id}~i1-T1']);
      final doc = sent.values.single;
      expect(doc['investorId'], 'i1');
      expect(doc['founderId'], _raising.founderId);
      expect(doc['startupName'], _raising.name);
      expect(doc['amount'], 250000);
      expect(doc['status'], 'pending');
      await t.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a startup that is not raising cannot send', (t) async {
      await pumpSheet(
        t,
        startups: [PrototypeSeed.rafeeq.copyWith(clearFunding: true)],
      );
      expect(
        find.text('You need a startup that is raising to send a request.'),
        findsOneWidget,
      );
    });

    testWidgets('one request per startup per ticket', (t) async {
      await db.setDocument(
        FirestoreCollections.ticketRequests,
        '${_raising.id}~i1-T1',
        {'founderId': 'someone'},
      );
      // The repository reads what the signed-in founder already sent.
      expect(await TicketRequestRepository(firestore: db).sentBy('someone'), {
        '${_raising.id}~i1-T1',
      });
    });
  });
}
