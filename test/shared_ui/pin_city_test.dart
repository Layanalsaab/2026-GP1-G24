import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/shared_ui/icons/app_icons.dart';
import 'package:startsa/shared_ui/theme/app_colors.dart';
import 'package:startsa/shared_ui/widgets/cards/home_card.dart';
import 'package:startsa/shared_ui/widgets/cards/pin_city.dart';

Finder get _pin => find.byWidgetPredicate(
  (w) => w is AppIcon && w.path == AppIcons.pin,
  description: 'location pin',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a pin, a 4 px gap and the city, grey and 14 px', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: PinCity('Riyadh'))),
    );
    expect(find.text('Riyadh'), findsOneWidget);
    final icon = t.widget<AppIcon>(_pin);
    expect(icon.size, 14);
    expect(icon.color, AppColors.hint);
    expect(AppColors.hint, const Color(0xFF8C918D));
    // 4 px between the pin and the city.
    final gap = t.getTopLeft(find.text('Riyadh')).dx - t.getRect(_pin).right;
    expect(gap, closeTo(4, 0.01));
    // Centred on the text.
    expect(
      t.getCenter(_pin).dy,
      closeTo(t.getCenter(find.text('Riyadh')).dy, 1),
    );
  });

  testWidgets('no city: no pin at all', (t) async {
    for (final city in <String?>['', '   ', null]) {
      await t.pumpWidget(MaterialApp(home: Scaffold(body: PinCity(city))));
      expect(_pin, findsNothing, reason: '$city');
    }
  });

  testWidgets('a match card shows the pin before the city; none without', (
    t,
  ) async {
    Widget card(String city) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeCard(
            name: 'Rafeeq Health',
            tag: 'HealthTech',
            city: city,
            body: 'Home nursing visits.',
            matchPercent: 86,
            matchReason: 'Sector fit',
          ),
        ),
      ),
    );
    await t.pumpWidget(card('Riyadh'));
    expect(find.text('Riyadh'), findsOneWidget);
    expect(_pin, findsOneWidget);
    await t.pumpWidget(card(''));
    expect(_pin, findsNothing);
  });
}
