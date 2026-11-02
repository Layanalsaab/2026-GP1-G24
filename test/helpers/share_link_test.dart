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
      'https://start.sa/startup/mock-rafeeq',
    );
    expect(ShareLink.forKey('i-ahmad'), 'https://start.sa/investor/ahmad');
    expect(ShareLink.forKey('p-taqadam'), 'https://start.sa/program/taqadam');
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
    expect(copied, ['https://start.sa/startup/abc']);
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

    Future<void> openSheet(WidgetTester t) async {
      await t.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: AppToast.navigatorKey,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => ShareLink.share(
                context,
                'https://start.sa/startup/abc',
                title: 'Rafeeq Health',
              ),
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
          expect(text, contains('Rafeeq Health on Start.sa'));
        }
        // The sheet closed.
        expect(find.text('Copy link'), findsNothing);
      }
    });

    testWidgets('More opens the phone\'s own share sheet', (t) async {
      await openSheet(t);
      await t.tap(find.text('More'));
      await t.pumpAndSettle();
      expect(system, hasLength(1));
      expect(system.single.$1, contains('https://start.sa/startup/abc'));
      expect(system.single.$2, 'Rafeeq Health on Start.sa');
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
