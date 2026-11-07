import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/bookmarks/screens/bookmarks_screen.dart';
import 'package:startsa/helpers/share_link.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../support/fakes.dart';

/// Records what is copied to the clipboard.
List<String> _watchClipboard(WidgetTester t) {
  final copied = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => StartupRepository.instance = FakeStartupRepository());

  test('the link of a bookmark key', () {
    expect(
      ShareLink.forKey('s-mock-rafeeq'),
      'https://startsa-ea49e.web.app/startup/mock-rafeeq',
    );
    expect(ShareLink.forKey('i-ahmad'), 'https://startsa-ea49e.web.app/investor/ahmad');
    expect(ShareLink.forKey('p-taqadam'), 'https://startsa-ea49e.web.app/program/taqadam');
  });

  testWidgets('copy puts the link on the clipboard and says Link copied', (
    t,
  ) async {
    final copied = _watchClipboard(t);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorKey: AppToast.navigatorKey,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => ShareLink.copyKey(context, 's-abc'),
            child: const Text('share'),
          ),
        ),
      ),
    );
    await t.tap(find.text('share'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(copied, ['https://startsa-ea49e.web.app/startup/abc']);
    expect(find.text('Link copied'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('the share icon on a card opens the share sheet', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorKey: AppToast.navigatorKey,
        home: BookmarksScreen(
          items: [
            SavedBookmark(
              item: HomeItem.fromStartup(PrototypeSeed.rafeeq),
              savedAt: DateTime(2026, 10, 20),
            ),
          ],
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 800));
    await t.tap(find.bySemanticsLabel('Share').first);
    await t.pumpAndSettle();
    for (final label in [
      'Share',
      'Copy link',
      'WhatsApp',
      'X',
      'Telegram',
      'LinkedIn',
      'Facebook',
      'Email',
      'More',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('Link copied'), findsNothing);
  });

  group('the share sheet options', () {
    final realLauncher = ShareLink.launcher;
    final realSystemShare = ShareLink.systemShare;
    late List<Uri> opened;
    late List<(String, String)> system;

    setUp(() {
      opened = [];
      system = [];
      ShareLink.launcher = (uri) async {
        opened.add(uri);
        return true;
      };
      ShareLink.systemShare = (text, subject) async =>
          system.add((text, subject));
    });

    tearDown(() {
      // Back to the real ones for the other tests.
      ShareLink.launcher = realLauncher;
      ShareLink.systemShare = realSystemShare;
    });

    Future<void> openSheet(
      WidgetTester t, {
      String url = 'https://start.sa/startup/abc',
      String? title = 'Rafeeq Health',
    }) async {
      await t.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: AppToast.navigatorKey,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => ShareLink.share(context, url, title: title),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    testWidgets('WhatsApp, X, Telegram, LinkedIn, Facebook and Email', (
      t,
    ) async {
      final expected = <String, String>{
        'WhatsApp': 'https://wa.me/?text=',
        'X': 'https://twitter.com/intent/tweet?',
        'Telegram': 'https://t.me/share/url?',
        'LinkedIn': 'https://www.linkedin.com/sharing/share-offsite/?',
        'Facebook': 'https://www.facebook.com/sharer/sharer.php?',
        'Email': 'mailto:?',
      };
      for (final entry in expected.entries) {
        opened.clear();
        await openSheet(t);
        await t.tap(find.bySemanticsLabel(entry.key));
        await t.pumpAndSettle();
        expect(opened, hasLength(1), reason: entry.key);
        final text = Uri.decodeFull(opened.single.toString());
        expect(text, startsWith(entry.value), reason: entry.key);
        expect(text, contains('https://start.sa/startup/abc'));
        // LinkedIn and Facebook only take the link; the others carry the text.
        if (entry.key != 'LinkedIn' && entry.key != 'Facebook') {
          expect(text, contains('Look, I found Rafeeq Health on Start.sa.'));
          expect(text, contains('A startup I think you will like.'));
        }
        // The sheet closed.
        expect(find.text('Copy link'), findsNothing);
      }
    });

    testWidgets('a startup is shared with its ready message and the link', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: AppToast.navigatorKey,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => ShareLink.shareStartup(
                context,
                id: 'abc',
                name: 'Rafeeq Health',
                sector: 'HealthTech',
                city: 'Riyadh',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      expect(
        system.single.$1,
        'Check out Rafeeq Health on Start.sa, a HealthTech startup from '
        'Riyadh! https://startsa-ea49e.web.app/startup/abc',
      );
      // The mail subject is the share sheet's own ("Look what I found ...").
      expect(system.single.$2, 'Look what I found on Start.sa: Rafeeq Health');
    });

    testWidgets('an investor is shared with its ready message and the link', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => t.binding.setSurfaceSize(null));
      Future<void> open(String city) async {
        system.clear();
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            navigatorKey: AppToast.navigatorKey,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => ShareLink.shareInvestor(
                  context,
                  id: 'ahmad',
                  name: 'Ahmad Alharbi',
                  city: city,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        await t.tap(find.text('More'));
        await t.pumpAndSettle();
      }

      await open('Riyadh');
      expect(
        system.single.$1,
        'Check out Ahmad Alharbi on Start.sa, an investor from Riyadh! '
        'https://startsa-ea49e.web.app/investor/ahmad',
      );
      // No city: the " from ..." part is left out.
      await open('');
      expect(
        system.single.$1,
        'Check out Ahmad Alharbi on Start.sa, an investor! '
        'https://startsa-ea49e.web.app/investor/ahmad',
      );
    });

    testWidgets('More opens the phone\'s own share sheet', (t) async {
      await openSheet(t);
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      expect(system, hasLength(1));
      expect(system.single.$1, contains('https://start.sa/startup/abc'));
      expect(system.single.$1, startsWith('Look, I found Rafeeq Health'));
      expect(
        system.single.$1,
        contains('Take a look: https://start.sa/startup/abc'),
      );
      expect(system.single.$2, 'Look what I found on Start.sa: Rafeeq Health');
    });

    /// The text of the mail the Email button opens.
    ({String subject, String body}) mail() {
      final q = Uri.splitQueryString(
        opened.single.query.replaceAll('+', '%2B'),
      );
      return (subject: q['subject']!, body: q['body']!);
    }

    testWidgets('Email: a subject, a greeting, the message and the link', (
      t,
    ) async {
      await openSheet(t);
      await t.tap(find.bySemanticsLabel('Email'));
      await t.pumpAndSettle();
      final m = mail();
      expect(m.subject, 'Look what I found on Start.sa: Rafeeq Health');
      expect(
        m.body,
        'Hi,\n\n'
        'Look, I found Rafeeq Health on Start.sa. A startup I think you will like.\n'
        'Take a look: https://start.sa/startup/abc',
      );
    });

    testWidgets('WhatsApp: the whole message and the link, no plus signs', (
      t,
    ) async {
      await openSheet(t);
      await t.tap(find.bySemanticsLabel('WhatsApp'));
      await t.pumpAndSettle();
      expect(opened.single.toString(), isNot(contains('+')));
      final text = Uri.decodeComponent(opened.single.queryParameters['text']!);
      expect(
        text,
        'Look, I found Rafeeq Health on Start.sa. A startup I think you will like.\n'
        'Take a look: https://start.sa/startup/abc',
      );
    });

    testWidgets('an investor and a support channel get their own wording', (
      t,
    ) async {
      await openSheet(
        t,
        url: 'https://start.sa/investor/i1',
        title: 'Ahmad Hassan',
      );
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      expect(
        system.last.$1,
        startsWith(
          'Look, I found Ahmad Hassan on Start.sa. An investor I think you should meet.',
        ),
      );
      await openSheet(t, url: 'https://start.sa/program/p1', title: 'Taqadam');
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      expect(
        system.last.$1,
        startsWith(
          'Look, I found Taqadam on Start.sa. A support channel that might help you.',
        ),
      );
    });

    testWidgets('without a name it is still a friendly line', (t) async {
      await openSheet(t, title: null);
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      expect(
        system.single.$1,
        'Look what I found on Start.sa.\nTake a look: https://start.sa/startup/abc',
      );
      expect(system.single.$2, 'Look what I found on Start.sa');
    });

    testWidgets('an app that cannot open says so', (t) async {
      ShareLink.launcher = (uri) async => false;
      await openSheet(t);
      await t.tap(find.text('WhatsApp'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Couldn’t open that app.'), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
    });
  });
}
