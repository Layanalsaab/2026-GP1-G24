import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/helpers/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts normal addresses, ignoring surrounding spaces', () {
      expect(Validators.email('name@example.com'), isNull);
      expect(Validators.email('  name@example.com  '), isNull);
      expect(Validators.email('first.last+tag@sub.example.sa'), isNull);
    });

    test('rejects empty and whitespace-only input', () {
      expect(Validators.email(null), AppStrings.emailRequired);
      expect(Validators.email(''), AppStrings.emailRequired);
      expect(Validators.email('   '), AppStrings.emailRequired);
    });

    test('rejects malformed addresses', () {
      for (final bad in [
        'plainaddress',
        'missing-at.example.com',
        '@no-local.com',
        'no-domain@',
        'no-tld@example',
        'two@@example.com',
        'spa ce@example.com',
        'name@exa mple.com',
        'name@example.c',
      ]) {
        expect(Validators.email(bad), AppStrings.emailInvalid, reason: bad);
      }
    });
  });

  group('Validators.password', () {
    test('accepts a password meeting every rule', () {
      expect(Validators.password('Startup1'), isNull);
      expect(Validators.password('Abcdefg1'), isNull); // exactly 8
      expect(Validators.password('Correct Horse 9 Battery'), isNull);
    });

    test('requires a value', () {
      expect(Validators.password(null), AppStrings.passwordRequired);
      expect(Validators.password(''), AppStrings.passwordRequired);
    });

    test('rejects fewer than 8 characters', () {
      expect(Validators.password('Abcde1'), AppStrings.passwordTooShort);
      expect(Validators.password('Abcdef1'), AppStrings.passwordTooShort); // 7
    });

    test('requires an uppercase letter', () {
      expect(Validators.password('startup12'), AppStrings.passwordNeedsUppercase);
    });

    test('requires a lowercase letter', () {
      expect(Validators.password('STARTUP12'), AppStrings.passwordNeedsLowercase);
    });

    test('requires a number', () {
      expect(Validators.password('StartupPlan'), AppStrings.passwordNeedsNumber);
    });

    test('does not trim: spaces count as characters', () {
      expect(Validators.password('Ab1    '), AppStrings.passwordTooShort); // 7
      expect(Validators.password('Ab1     '), isNull); // 8, spaces included
    });
  });

  group('Validators.confirmPassword', () {
    test('accepts a matching confirmation', () {
      expect(Validators.confirmPassword('Startup1', 'Startup1'), isNull);
    });

    test('requires a confirmation', () {
      expect(Validators.confirmPassword('Startup1', ''), AppStrings.confirmPasswordRequired);
      expect(Validators.confirmPassword('Startup1', null), AppStrings.confirmPasswordRequired);
    });

    test('rejects a different confirmation, case-sensitively', () {
      expect(Validators.confirmPassword('Startup1', 'startup1'), AppStrings.passwordsDontMatch);
      expect(Validators.confirmPassword('Startup1', 'Startup2'), AppStrings.passwordsDontMatch);
    });
  });

  group('Validators.fullName', () {
    test('accepts a name', () {
      expect(Validators.fullName('Mohammed Ahmed'), isNull);
    });

    test('rejects empty or spaces-only names', () {
      expect(Validators.fullName(null), AppStrings.fullNameRequired);
      expect(Validators.fullName(''), AppStrings.fullNameRequired);
      expect(Validators.fullName('    '), AppStrings.fullNameRequired);
    });
  });
}
