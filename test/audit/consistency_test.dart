// Checks that the same pick-list is the same everywhere it is used, and that
// firestore.rules accepts every value the app can store.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
import 'package:startsa/features/profiles/view_models/edit_account_view_model.dart';
import 'package:startsa/features/search/view_models/home_filters.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/models/startup_enums.dart';

/// The text inside the quotes of the regular expression `matches('^(a|b)$')`
/// that follows [field] in firestore.rules.
Set<String> _ruleValues(String rules, String field) {
  final m = RegExp(
    'd\\.$field\\.matches\\(\'\\^\\(([^)]*)\\)\\\$\'\\)',
  ).firstMatch(rules);
  expect(m, isNotNull, reason: 'no matches() for $field in firestore.rules');
  return m!.group(1)!.split('|').toSet();
}

void main() {
  final sectors = [for (final s in Sector.values) s.label];

  test('every sector list in the app is the same list', () {
    expect(SignupViewModel.sectorOptions, sectors);
    expect(EditAccountViewModel.sectorOptions, sectors);
    expect(InvestorOnboardingViewModel.sectorOptions, sectors);
    expect(sectors.last, 'Other');
    expect(sectors.toSet().length, sectors.length, reason: 'no duplicates');
  });

  test('investor stages are the stages a startup can pick', () {
    expect(InvestorCriteria.stageOptions, [
      for (final s in StartupStage.picks) s.label,
    ]);
  });

  test('investor commerce models are the ones a startup can pick', () {
    expect(InvestorOnboardingViewModel.modelOptions, [
      for (final m in BusinessModel.picks) m.label,
    ]);
  });

  test('cities: the startup form, sign-up and Edit profile agree', () {
    expect([for (final c in StartupLocation.values) c.label], AppStrings.allCities);
    expect(AppStrings.allCities.toSet().length, AppStrings.allCities.length);
    for (final c in StartupLocation.values) {
      expect(StartupLocation.values.where((x) => x.value == c.value).length, 1);
    }
  });

  test('the Hub filters list the same values the forms store', () {
    List<String> options(HomeContext ctx, String title) => HomeFilters.groups(
      ctx,
    ).firstWhere((g) => g.title == title).options;
    expect(options(HomeContext.investors, 'Sector'), sectors);
    expect(options(HomeContext.investors, 'Stages they invest in'), [
      for (final s in StartupStage.picks) s.label,
    ]);
    expect(options(HomeContext.investors, 'City'), AppStrings.allCities);
    expect(
      options(HomeContext.investors, 'Ticket size'),
      InvestorCriteria.ticketOptions,
    );
  });

  group('firestore.rules accepts every value the app can store', () {
    final rules = File('firestore.rules').readAsStringSync();

    test('sector', () {
      final allowed = _ruleValues(rules, 'sector');
      for (final s in Sector.values) {
        expect(allowed, contains(s.value), reason: 'sector ${s.value}');
      }
    });

    test('stage', () {
      final allowed = _ruleValues(rules, 'stage');
      for (final s in StartupStage.values) {
        expect(allowed, contains(s.value), reason: 'stage ${s.value}');
      }
    });

    test('commerce model', () {
      final allowed = _ruleValues(rules, 'businessModel');
      for (final m in BusinessModel.values) {
        expect(allowed, contains(m.value), reason: 'model ${m.value}');
      }
    });

    test('city', () {
      final allowed = _ruleValues(rules, 'location');
      for (final c in StartupLocation.values) {
        expect(allowed, contains(c.value), reason: 'city ${c.value}');
      }
      expect(allowed, contains(StartupLocation.other.value));
    });

    test('looking for', () {
      final m = RegExp(
        r"d\.lookingFor\.hasOnly\(\[([^\]]*)\]",
      ).firstMatch(rules)!;
      final allowed = RegExp(
        r"'([a-z_]+)'",
      ).allMatches(m.group(1)!).map((x) => x.group(1)!).toSet();
      for (final l in LookingFor.values) {
        expect(allowed, contains(l.value), reason: 'looking for ${l.value}');
      }
    });

    test('funding round stages', () {
      final m = RegExp(
        r"d\.stage\.matches\('\^\((pre_seed[^)]*)\)\$'\)",
      ).firstMatch(rules)!;
      final allowed = m.group(1)!.split('|').toSet();
      for (final s in StartupStage.values) {
        expect(allowed, contains(s.value));
      }
    });
  });

  test('every stored value is unique within its list', () {
    for (final values in [
      [for (final s in Sector.values) s.value],
      [for (final s in StartupStage.values) s.value],
      [for (final m in BusinessModel.values) m.value],
      [for (final l in LookingFor.values) l.value],
    ]) {
      expect(values.toSet().length, values.length);
    }
  });
}
