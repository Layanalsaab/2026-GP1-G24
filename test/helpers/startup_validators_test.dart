import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/validation_strings.dart';
import 'package:startsa/helpers/formatters.dart';
import 'package:startsa/helpers/startup_validators.dart';

void main() {
  final now = DateTime(2026, 10, 19);

  test('required text fields show the prototype copy', () {
    expect(StartupValidators.name(' '), ValidationStrings.startupName);
    expect(
      StartupValidators.description(''),
      ValidationStrings.startupDescription,
    );
    expect(StartupValidators.problem(''), ValidationStrings.problem);
    expect(StartupValidators.growth(''), ValidationStrings.growth);
    expect(StartupValidators.name('Rafeeq Health'), isNull);
  });

  group('founded year', () {
    test('required; 4 digits starting with 2; a future year is fine', () {
      expect(
        StartupValidators.foundedYear('', now: now),
        ValidationStrings.foundedRequired,
      );
      for (final ok in ['2000', '2024', '2026', '2027', '2999']) {
        expect(StartupValidators.foundedYear(ok, now: now), isNull, reason: ok);
      }
      for (final bad in ['1899', '1999', '0000', '0999', '20', '2', '12345']) {
        expect(
          StartupValidators.foundedYear(bad, now: now),
          'Enter a 4-digit year starting with 2, like 2024.',
          reason: bad,
        );
      }
    });
  });

  group('website', () {
    test('optional and accepts addresses without a scheme', () {
      expect(StartupValidators.websiteUrl(''), isNull);
      expect(StartupValidators.websiteUrl('rafeeqhealth.sa'), isNull);
      expect(
        StartupValidators.websiteUrl('example'),
        ValidationStrings.websiteInvalid,
      );
      expect(
        StartupValidators.websiteUrl('example.c'),
        ValidationStrings.websiteInvalid,
      );
      expect(
        StartupValidators.websiteUrl('exa..mple.com'),
        ValidationStrings.websiteInvalid,
      );
      expect(StartupValidators.websiteUrl('www.example.com/path'), isNull);
      expect(
        StartupValidators.websiteUrl('not a url'),
        ValidationStrings.websiteInvalid,
      );
    });
  });

  group('money', () {
    test('digits are read through the thousands separators', () {
      expect(StartupValidators.money('1,200,000'), 1200000);
      expect(StartupValidators.money(''), isNull);
      expect(StartupValidators.funding('0'), ValidationStrings.funding);
      expect(StartupValidators.funding('500,000'), isNull);
    });

    test('valuation is required but 0 is allowed', () {
      expect(StartupValidators.valuationOk('0'), isTrue);
      expect(StartupValidators.valuationOk(''), isFalse);
    });

    test('revenue needs all three years', () {
      expect(
        StartupValidators.revenue('1', '2', ''),
        ValidationStrings.revenue,
      );
      expect(StartupValidators.revenue('1', '2', '3'), isNull);
    });
  });

  test('short money matches the prototype', () {
    expect(Formatters.shortMoney(2400000000), '2.4B');
    expect(Formatters.shortMoney(600000000), '600M');
    expect(Formatters.shortMoney(24000000), '24M');
    expect(Formatters.shortMoney(1200000), '1.2M');
    expect(Formatters.shortMoney(500000), '500K');
    expect(Formatters.shortMoney(900), '900');
  });

  test('target market size: empty and zero have their own messages', () {
    expect(StartupValidators.marketSize(''), ValidationStrings.marketSize);
    expect(StartupValidators.marketSize('0'), ValidationStrings.marketSizeZero);
    expect(StartupValidators.marketSize('1,000'), isNull);
  });
}
