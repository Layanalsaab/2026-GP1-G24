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
}
