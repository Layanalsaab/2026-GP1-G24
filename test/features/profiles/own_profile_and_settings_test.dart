import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/profiles/screens/account_screen.dart';
import 'package:startsa/features/profiles/screens/settings_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';

import '../../support/fakes.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
  city: 'Riyadh',
  phone: '551234567',
  // Only the phone was made public at sign-up; the email stays private.
  phonePublic: true,
  bio: 'Building Rafeeq Health.',
  sectorsOfInterest: ['HealthTech', 'Fintech'],
  linkedin: 'linkedin.com/in/shahad',
);

const _investor = AppUser(
  uid: 'u2',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
  city: 'Riyadh',
  phone: '509876543',
  sectorsOfInterest: ['HealthTech'],
  valueOffered: 'Connections.',
  gain: 'Early access.',
);

Future<void> _pump(
  WidgetTester t,
  Widget screen, {
  Size size = const Size(412, 892),
}) async {
  await t.binding.setSurfaceSize(size);
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
  await t.pump(const Duration(milliseconds: 800));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    AppSession.instance = AppSession();
    BookmarkRepository.instance = BookmarkRepository();
    RequestRepository.instance = RequestRepository(sample: true);
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    UserRepository.instance = FakeUserRepository()
      ..profiles['u1'] = _founder
      ..profiles['u2'] = _investor;
    StartupRepository.instance = FakeStartupRepository()
      ..startups.add(PrototypeSeed.rafeeq);
  });

  for (final size in const [Size(412, 892), Size(360, 740)]) {
    group('${size.width.toInt()} px wide', () {
      testWidgets('own profile and settings', (t) async {
        AppSession.instance.signIn(_founder);
        await _pump(t, const OwnProfileScreen(user: _founder), size: size);
        expect(find.text('Shahad Alabdulkarim'), findsOneWidget);
        expect(find.text('Edit profile'), findsOneWidget);
        expect(find.text('+966 55 123 4567'), findsOneWidget);
        // On my own profile both contact lines show, with who sees them.
        expect(find.text('shahad@gmail.com'), findsOneWidget);
        expect(find.text('Only you'), findsOneWidget);
        expect(find.text('Public'), findsOneWidget);
        expect(find.text('Startups'), findsOneWidget);

        await _pump(t, const SettingsScreen(), size: size);
        expect(find.text('Dark mode'), findsOneWidget);
        expect(find.text('Delete account'), findsOneWidget);
      });
    });
  }
}
