import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startsa/data_access/repositories/app_settings_repository.dart';
import 'package:startsa/features/login_and_signup/widgets/auth_decor.dart';
import 'package:startsa/shared_ui/theme/app_colors.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/theme/theme_controller.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppColors.setDark(false);
  });
  tearDown(() => AppColors.setDark(false));

  group('palette', () {
    test('light keeps the original colors', () {
      expect(AppColors.cream, const Color(0xFFFAF8F4));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.ink, const Color(0xFF1C1F1D));
      expect(AppColors.greenText, const Color(0xFF1F3F27));
      expect(AppColors.mossText, const Color(0xFF2F5D3A));
      expect(AppColors.border, const Color(0xFFE4E1DA));
      expect(AppColors.scrim, const Color(0x661C1F1D));
    });

    test('dark uses the dark palette', () {
      AppColors.setDark(true);
      expect(AppColors.cream, const Color(0xFF101411));
      expect(AppColors.surface, const Color(0xFF1A201C));
      expect(AppColors.ink, const Color(0xFFE8ECE9));
      expect(AppColors.grey, const Color(0xFFA6AEA8));
      expect(AppColors.borderStrong, const Color(0xFF7B847D));
      expect(AppColors.hint, const Color(0xFF8A938C));
      expect(AppColors.border, const Color(0xFF2E3831));
      expect(AppColors.dividerSoft, const Color(0xFF28312B));
      expect(AppColors.mutedFill, const Color(0xFF232A25));
      expect(AppColors.moss50, const Color(0xFF18211B));
      expect(AppColors.moss100, const Color(0xFF223228));
      expect(AppColors.mossBorder, const Color(0xFF34493A));
      expect(AppColors.greenText, const Color(0xFFA9D4B3));
      expect(AppColors.mossText, const Color(0xFF86BB92));
      expect(AppColors.tagGoldFill, const Color(0xFF3A3219));
      expect(AppColors.tagGoldText, const Color(0xFFECD08A));
      expect(AppColors.error, const Color(0xFFF2A8A3));
      expect(AppColors.errorFill, const Color(0xFF3F2220));
      expect(AppColors.scrim, const Color(0xB3000000));
      expect(AppColors.toastFill, const Color(0xFFE8ECE9));
      expect(AppColors.toastText, const Color(0xFF101411));
    });

    test('the brand greens and the gold stay as backgrounds', () {
      for (final dark in [false, true]) {
        AppColors.setDark(dark);
        expect(AppColors.green, const Color(0xFF1F3F27));
        expect(AppColors.moss600, const Color(0xFF2F5D3A));
        expect(AppColors.gold, const Color(0xFFC9A24A));
        expect(AppColors.white, const Color(0xFFFFFFFF));
      }
    });

    test('text colors are readable on their surface (4.5:1) in dark', () {
      AppColors.setDark(true);
      double lum(Color c) => c.computeLuminance();
      double ratio(Color a, Color b) {
        final hi = lum(a) > lum(b) ? a : b;
        final lo = lum(a) > lum(b) ? b : a;
        return (lum(hi) + 0.05) / (lum(lo) + 0.05);
      }

      for (final bg in [AppColors.cream, AppColors.surface]) {
        for (final fg in [
          AppColors.ink,
          AppColors.grey,
          AppColors.greenText,
          AppColors.mossText,
          AppColors.error,
          AppColors.hint,
          AppColors.metaText,
          AppColors.placeholder,
        ]) {
          expect(
            ratio(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$fg on $bg',
          );
        }
      }
      expect(
        ratio(AppColors.tagGoldText, AppColors.tagGoldFill),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(AppColors.toastText, AppColors.toastFill),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('theme', () {
    testWidgets('the two ThemeDatas follow their palette', (t) async {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.light.scaffoldBackgroundColor, const Color(0xFFFAF8F4));
      expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF101411));
      // Building a theme leaves the app's own palette alone.
      expect(AppColors.isDark, isFalse);
    });
  });

  group('controller', () {
    test('off by default, saved when switched, restored on launch', () async {
      final c = ThemeController(settings: AppSettingsRepository());
      await c.load();
      expect(c.isDark, isFalse);
      await c.setDark(true);
      expect(c.isDark, isTrue);
      expect(AppColors.isDark, isTrue);

      // A new launch reads the saved choice before the first screen.
      AppColors.setDark(false);
      final again = ThemeController(settings: AppSettingsRepository());
      await again.load();
      expect(again.isDark, isTrue);
      expect(AppColors.isDark, isTrue);
    });

    testWidgets('every screen repaints at once, keeping its state', (t) async {
      final c = ThemeController(settings: AppSettingsRepository());
      var taps = 0;
      await t.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: c,
          builder: (context, mode, _) => MaterialApp(
            themeMode: mode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: StatefulBuilder(
              builder: (context, set) => GestureDetector(
                onTap: () => set(() => taps++),
                child: const _Probe(),
              ),
            ),
          ),
        ),
      );
      Color probe() => t.widget<ColoredBox>(find.byKey(_probeKey)).color;
      expect(probe(), const Color(0xFFFAF8F4));
      await t.tap(find.byType(_Probe));
      expect(taps, 1);

      await c.setDark(true);
      await t.pump();
      expect(probe(), const Color(0xFF101411));
      // The state of the screen is still there.
      expect(taps, 1);

      await c.setDark(false);
      await t.pump();
      expect(probe(), const Color(0xFFFAF8F4));
    });
  });

  group('logo', () {
    testWidgets('light page: the dark-green logo; dark page: the light one', (
      t,
    ) async {
      String asset() {
        final image = t.widget<Image>(find.byType(Image));
        return (image.image as AssetImage).assetName;
      }

      await t.pumpWidget(
        const MaterialApp(home: BrandLogo(width: 100, height: 95)),
      );
      expect(asset(), 'assets/images/logo_full.png');

      AppColors.setDark(true);
      await t.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: const BrandLogo(width: 100, height: 95),
        ),
      );
      expect(asset(), 'assets/images/logo_small.png');
    });
  });
}

const _probeKey = Key('probe');

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: ColoredBox(key: _probeKey, color: AppColors.cream),
  );
}
