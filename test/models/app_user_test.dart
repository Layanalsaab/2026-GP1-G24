import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/models/app_user.dart';

void main() {
  test('reads the profile fields shown on Profile', () {
    final user = AppUser.fromMap('u1', {
      'role': 'investor',
      'fullName': 'Layan Alsaab',
      'email': 'layan@gmail.com',
      'phone': '509876543',
      'city': 'Riyadh',
      'bio': 'Angel investor.',
      'sectorsOfInterest': ['HealthTech', 'Fintech'],
      'createdAt': DateTime(2026, 10, 1),
    })!;

    expect(user.phone, '509876543');
    expect(user.sectorsOfInterest, ['HealthTech', 'Fintech']);
    expect(user.createdAt, DateTime(2026, 10, 1));
  });

  test('older profiles without the new fields still load', () {
    final user = AppUser.fromMap('u1', {
      'role': 'founder',
      'fullName': 'Shahad',
      'email': 's@b.co',
    })!;

    expect(user.phone, isNull);
    expect(user.sectorsOfInterest, isEmpty);
    expect(user.createdAt, isNull);
  });

  test('copyWith keeps the joined date', () {
    final user = AppUser(
      uid: 'u1',
      role: AccountRole.founder,
      fullName: 'Shahad',
      email: 's@b.co',
      createdAt: DateTime(2026, 10, 1),
    );

    expect(user.copyWith(phone: '551234567').createdAt, DateTime(2026, 10, 1));
  });

  test('an investor document reads the flat database field names', () {
    final user = AppUser.fromMap('i1', {
      'role': 'investor',
      'fullName': 'Ahmad Hassan',
      'email': 'a@b.co',
      'city': 'Riyadh',
      'preferredSectors': ['HealthTech', 'Fintech'],
      'preferredStages': ['Seed'],
      'ticketSize': 'SAR 100K – 500K',
      'investmentsCount': '6–15',
      'hasLedRound': true,
      'roundsLed': '1–2',
      'coInvest': 'Preferably',
      'roundSizeMin': 100000,
      'roundSizeMax': 500000,
      'preferredCommerceModels': ['Business-to-Business (B2B)'],
      'linkedinUrl': 'linkedin.com/in/ahmad',
      'offer': 'Introductions',
      'lookingFor': 'Strong teams',
    })!;
    final c = user.investorCriteria!;
    expect(c.dealsCount, '6–15');
    expect(c.ticketBand, 'SAR 100K – 500K');
    expect(c.roundMin, 100000);
    expect(c.commerceModels, ['Business-to-Business (B2B)']);
    expect(c.lookFor, 'Strong teams');
    expect(user.linkedin, 'linkedin.com/in/ahmad');
    expect(user.valueOffered, 'Introductions');
    expect(c.toFields()['investmentsCount'], '6–15');
    expect(c.toFields()['preferredCommerceModels'], c.commerceModels);
  });
}
