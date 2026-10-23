import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/auth_strings.dart';
import 'package:startsa/app_constants/validation_strings.dart';
import 'package:startsa/helpers/validators.dart';

void main() {
  group('full name', () {
    test('needs two words of at least two letters', () {
      expect(Validators.fullName('Mohammed Ahmed'), isNull);
      expect(Validators.fullName('Sara Al-Mohsen'), isNull);
      expect(Validators.fullName("Layla O'Brien"), isNull);
      expect(Validators.fullName('محمد أحمد'), isNull);
      expect(Validators.fullName('Mohammed'), ValidationStrings.fullName);
      expect(Validators.fullName('A B'), ValidationStrings.fullName);
      expect(Validators.fullName('Sara 2'), ValidationStrings.fullName);
      expect(Validators.fullName(''), ValidationStrings.fullName);
    });
  });

  group('live messages', () {
    test('show as soon as something is typed and it is not valid yet', () {
      expect(Validators.fullNameLive(''), isNull);
      expect(Validators.fullNameLive('Sara'), ValidationStrings.fullName);
      expect(Validators.fullNameLive('Sara Ali'), isNull);
      expect(Validators.phoneLive(''), isNull);
      expect(Validators.phoneLive('55 12'), ValidationStrings.phoneInvalid);
      expect(Validators.phoneLive('55 123 4567'), isNull);
      expect(
        Validators.linkedinLive('linkedin.com/x'),
        ValidationStrings.linkedin,
      );
    });
  });

  group('email', () {
    test('required and valid messages', () {
      expect(Validators.email(''), ValidationStrings.emailRequired);
      expect(Validators.email('nope'), ValidationStrings.emailInvalid);
      expect(Validators.email('a@b.co'), isNull);
    });

    test('live message only once something is typed', () {
      expect(Validators.emailLive(''), isNull);
      expect(Validators.emailLive('a@b'), ValidationStrings.emailLive);
      expect(Validators.emailLive('a@b.co'), isNull);
    });
  });

  group('phone', () {
    test(
      'counts digits only, spaces are ignored, 9 digits starting with 5',
      () {
        expect(Validators.phoneDigits('55 123 4567'), '551234567');
        expect(Validators.phone('55 123 4567'), isNull);
        expect(Validators.phone(''), ValidationStrings.phoneRequired);
        expect(Validators.phone('12345'), ValidationStrings.phoneInvalid);
        expect(Validators.phone('451234567'), ValidationStrings.phoneInvalid);
        expect(Validators.phoneEdit('12'), ValidationStrings.phoneEdit);
      },
    );
  });

  group('linkedin', () {
    test('optional, but must look like a profile link', () {
      expect(Validators.linkedin(''), isNull);
      expect(Validators.linkedin('linkedin.com/in/your-name'), isNull);
      expect(Validators.linkedin('https://www.linkedin.com/in/a-b/'), isNull);
      expect(Validators.linkedin('example.com'), ValidationStrings.linkedin);
    });
  });

  group('linkedin formats', () {
    test('accepts every profile format, English or Arabic', () {
      for (final link in [
        'linkedin.com/in/name',
        'www.linkedin.com/in/name',
        'https://www.linkedin.com/in/name/',
        'http://linkedin.com/in/name',
        'sa.linkedin.com/in/name',
        'https://ar.linkedin.com/in/name',
        'linkedin.com/in/محمد-أحمد',
        'https://www.linkedin.com/in/%D9%85%D8%AD%D9%85%D8%AF-%D8%A3%D8%AD%D9%85%D8%AF/',
        'linkedin.com/in/name?originalSubdomain=sa',
        'https://sa.linkedin.com/in/name/?originalSubdomain=sa',
        'linkedin.com/mwlite/in/name',
        'https://lnkd.in/abc123',
        'lnkd.in/abc',
      ]) {
        expect(Validators.isLinkedin(link), isTrue, reason: link);
      }
    });

    test('rejects anything that is not LinkedIn', () {
      for (final link in [
        'google.com/in/name',
        'https://example.com',
        'notlinkedin.com/in/name',
        'linkedin.com.evil.com/in/name',
        'linkedin.com',
        'linkedin.com/in',
        'just words',
      ]) {
        expect(Validators.isLinkedin(link), isFalse, reason: link);
      }
    });
  });

  group('email domains', () {
    test('a malformed email is invalid', () {
      expect(Validators.isEmail('name@gmail'), isFalse);
      expect(Validators.email('name@gmail'), ValidationStrings.emailInvalid);
      expect(
        ValidationStrings.emailInvalid,
        'Enter a valid email, like name@example.com',
      );
    });

    test('sign-up accepts common providers and university addresses', () {
      for (final mail in [
        'a@gmail.com',
        'a@hotmail.com',
        'a@outlook.com',
        'a@live.com',
        'a@yahoo.com',
        'a@icloud.com',
        'a@msn.com',
        'a@ksu.edu.sa',
        'a@student.ksu.edu.sa',
        'a@mit.edu',
        'a@ox.ac.uk',
      ]) {
        expect(Validators.isSignupEmail(mail), isTrue, reason: mail);
      }
    });

    test('sign-up rejects anything else, misspellings included', () {
      for (final mail in [
        'a@gmial.com',
        'a@gmail.co',
        'a@gmail.net',
        'a@gmail',
        'a@hotmial.com',
        'a@yahooo.com',
        'a@mycompany.sa',
        'a@example.com',
        'a@edu.sa',
        'a@fake.edu.com',
        'not an email',
      ]) {
        expect(Validators.isSignupEmail(mail), isFalse, reason: mail);
      }
    });
  });

  group('password', () {
    test('five rules: length, upper, lower, number, special', () {
      final ok = Validators.passwordRules('Sara@1234');
      expect(ok.every((r) => r.met), isTrue);
      expect(
        Validators.passwordRules('SARA@1234').every((r) => r.met),
        isFalse,
      );
      expect(Validators.passwordRules('SHORT').where((r) => r.met).length, 1);
      expect(Validators.isPassword('Sara@1234'), isTrue);
      expect(Validators.isPassword('sara@1234'), isFalse);
      expect(Validators.isPassword('SARA@1234'), isFalse);
      expect(Validators.passwordRules('x').map((r) => r.label), [
        'At least 8 characters',
        'One uppercase letter',
        'One lowercase letter',
        'One number',
        'One special character (! @ # \$)',
      ]);
    });

    test('the example shown in the password field follows every rule', () {
      final example = AuthStrings.passwordPlaceholder.replaceFirst('e.g. ', '');
      expect(Validators.isPassword(example), isTrue, reason: example);
    });

    test('confirm mismatch only shows once typed', () {
      expect(Validators.confirmPassword('a', ''), isNull);
      expect(
        Validators.confirmPassword('a', 'b'),
        ValidationStrings.confirmMismatch,
      );
      expect(Validators.confirmPassword('a', 'a'), isNull);
    });
  });

  test('other write-in is required and at most 40 characters', () {
    expect(Validators.isOtherText(''), isFalse);
    expect(Validators.isOtherText('SportsTech'), isTrue);
    expect(Validators.isOtherText('x' * 41), isFalse);
  });
}
