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
      expect(Validators.password('Startup1!'), isNull);
      expect(Validators.password('Abcdef1!'), isNull); // exactly 8
      expect(Validators.password('Correct Horse 9 Battery!'), isNull);
    });

    test('requires a value', () {
      expect(Validators.password(null), AppStrings.passwordRequired);
      expect(Validators.password(''), AppStrings.passwordRequired);
    });

    test('rejects fewer than 8 characters', () {
      expect(Validators.password('Abcd1!'), AppStrings.passwordTooShort);
      expect(Validators.password('Abcde1!'), AppStrings.passwordTooShort); // 7
    });

    test('requires an uppercase letter', () {
      expect(Validators.password('startup1!'), AppStrings.passwordNeedsUppercase);
    });

    test('requires a lowercase letter', () {
      expect(Validators.password('STARTUP1!'), AppStrings.passwordNeedsLowercase);
    });

    test('requires a number', () {
      expect(Validators.password('StartupPlan!'), AppStrings.passwordNeedsNumber);
    });

    test('requires a special character', () {
      expect(Validators.password('Startup12'), AppStrings.passwordNeedsSpecial);
      expect(Validators.password('Startup 12'), AppStrings.passwordNeedsSpecial);
    });

    test('does not trim: spaces count as characters', () {
      expect(Validators.password('Ab1!   '), AppStrings.passwordTooShort); // 7
      expect(Validators.password('Ab1!    '), isNull); // 8, spaces included
    });
  });

  group('Validators.confirmPassword', () {
    test('accepts a matching confirmation', () {
      expect(Validators.confirmPassword('Startup1!', 'Startup1!'), isNull);
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

    test('rejects one-letter names and names with digits or symbols', () {
      expect(Validators.fullName('A'), AppStrings.fullNameTooShort);
      expect(Validators.fullName('Sara 2'), AppStrings.fullNameLettersOnly);
      expect(Validators.fullName('Sara@home'), AppStrings.fullNameLettersOnly);
    });

    test('accepts hyphens, apostrophes and Arabic names', () {
      expect(Validators.fullName("Mary-Jane O'Neil"), isNull);
      expect(Validators.fullName('سارة السويلم'), isNull);
    });
  });

  group('Validators.phone', () {
    test('accepts a 9-digit Saudi mobile number starting with 5', () {
      expect(Validators.phone('512345678'), isNull);
    });

    test('rejects empty, short, long and wrong-prefix numbers', () {
      expect(Validators.phone(''), AppStrings.phoneRequired);
      expect(Validators.phone('51234567'), AppStrings.phoneInvalid);
      expect(Validators.phone('5123456789'), AppStrings.phoneInvalid);
      expect(Validators.phone('412345678'), AppStrings.phoneInvalid);
      expect(Validators.phone('5123a5678'), AppStrings.phoneInvalid);
    });
  });

  group('live rule checklists', () {
    List<bool> met(List<FieldRule> rules) => [for (final r in rules) r.met];

    test('password rules go green one by one', () {
      expect(met(Validators.passwordRules('')), [false, false, false, false, false]);
      expect(met(Validators.passwordRules('abc')), [false, false, true, false, false]);
      expect(met(Validators.passwordRules('Abcdefg1!')), [true, true, true, true, true]);
    });

    test('email rules agree with the email validator', () {
      for (final good in ['name@example.com', 'a.b+c@sub.example.sa']) {
        expect(met(Validators.emailRules(good)), [true, true], reason: good);
        expect(Validators.email(good), isNull);
      }
      for (final bad in ['plain', 'a@b', 'a@@b.com', 'a b@c.com', '@c.com']) {
        expect(met(Validators.emailRules(bad)).every((m) => m), isFalse, reason: bad);
        expect(Validators.email(bad), isNotNull);
      }
    });

    test('phone rules', () {
      expect(met(Validators.phoneRules('')), [false, false]);
      expect(met(Validators.phoneRules('5')), [false, true]);
      expect(met(Validators.phoneRules('512345678')), [true, true]);
    });

    test('confirm rule needs a non-empty match', () {
      expect(met(Validators.confirmPasswordRules('Abc1!', '')), [false]);
      expect(met(Validators.confirmPasswordRules('Abc1!', 'Abc1')), [false]);
      expect(met(Validators.confirmPasswordRules('Abc1!', 'Abc1!')), [true]);
    });
  });
}
