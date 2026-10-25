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

  testWidgets('the share icon on a card copies that card\'s link', (t) async {
    final copied = _watchClipboard(t);
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
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(copied.single, 'https://start.sa/startup/mock-rafeeq');
    expect(find.text('Link copied'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
  });
}
