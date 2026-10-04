import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/helpers/formatters.dart';
import 'package:startsa/helpers/startup_validators.dart';
import 'package:startsa/models/startup_enums.dart';

void main() {
  group('name', () {
    test('required, 3 to 60 characters after trimming', () {
      expect(StartupValidators.name(''), isNotNull);
      expect(StartupValidators.name('  ab  '), isNotNull);
      expect(StartupValidators.name('abc'), isNull);
      expect(StartupValidators.name('a' * 60), isNull);
      expect(StartupValidators.name('a' * 61), isNotNull);
    });
  });

  group('tagline', () {
    test('optional, max 80, one line', () {
      expect(StartupValidators.tagline(''), isNull);
      expect(StartupValidators.tagline('a' * 80), isNull);
      expect(StartupValidators.tagline('a' * 81), isNotNull);
      expect(StartupValidators.tagline('one\ntwo'), isNotNull);
    });
  });

  group('description', () {
    test('required, 50 to 1000 characters', () {
      expect(StartupValidators.description(''), isNotNull);
      expect(StartupValidators.description('a' * 49), isNotNull);
      expect(StartupValidators.description('a' * 50), isNull);
      expect(StartupValidators.description('a' * 1000), isNull);
      expect(StartupValidators.description('a' * 1001), isNotNull);
    });
  });

  group('foundedYear', () {
    final now = DateTime(2026, 10, 4);
    test('optional, 2000 to the current year', () {
      expect(StartupValidators.foundedYear('', now: now), isNull);
      expect(StartupValidators.foundedYear('1999', now: now), isNotNull);
      expect(StartupValidators.foundedYear('2000', now: now), isNull);
      expect(StartupValidators.foundedYear('2026', now: now), isNull);
      expect(StartupValidators.foundedYear('2027', now: now), isNotNull);
      expect(StartupValidators.foundedYear('20x1', now: now), isNotNull);
    });
  });

  group('website', () {
    test('optional and must look like a real web address', () {
      expect(StartupValidators.websiteUrl(''), isNull);
      expect(StartupValidators.websiteUrl('example.com'), isNull);
      expect(
        StartupValidators.websiteUrl('https://sub.example.sa/path'),
        isNull,
      );
      expect(StartupValidators.websiteUrl('not a url'), isNotNull);
      expect(StartupValidators.websiteUrl('localhost'), isNotNull);
      expect(StartupValidators.websiteUrl('ftp://example.com'), isNotNull);
      expect(StartupValidators.websiteUrl('example.c0m'), isNotNull);
    });

    test('normalizeUrl adds https when the scheme is missing', () {
      expect(
        StartupValidators.normalizeUrl('example.com'),
        'https://example.com',
      );
      expect(
        StartupValidators.normalizeUrl('http://example.com'),
        'http://example.com',
      );
    });
  });

  group('lookingFor and funding', () {
    test('at least one choice is required', () {
      expect(StartupValidators.lookingFor({}), isNotNull);
      expect(StartupValidators.lookingFor({LookingFor.mentorship}), isNull);
    });

    test('funding must be a positive whole number', () {
      expect(StartupValidators.fundingRequirement(''), isNotNull);
      expect(StartupValidators.fundingRequirement('0'), isNotNull);
      expect(StartupValidators.fundingRequirement('abc'), isNotNull);
      expect(StartupValidators.fundingRequirement('500000'), isNull);
    });
  });

  group('Formatters', () {
    test('thousands and SAR', () {
      expect(Formatters.thousands(0), '0');
      expect(Formatters.thousands(999), '999');
      expect(Formatters.thousands(1000), '1,000');
      expect(Formatters.thousands(1500000), '1,500,000');
      expect(Formatters.sar(250000), 'SAR 250,000');
    });

    test('shortUrl strips scheme and www', () {
      expect(Formatters.shortUrl('https://www.example.com/'), 'example.com');
      expect(
        Formatters.shortUrl('https://example.com/about'),
        'example.com/about',
      );
    });
  });
}
