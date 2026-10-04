import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/investor_strings.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import 'investment_criteria_form.dart';

/// Logic for the investor onboarding (PBI 21): the investor must choose their
/// investment criteria and city before using the app, so matching has
/// something to work with from day one.
class InvestorOnboardingViewModel extends ChangeNotifier
    with SafeNotifier, InvestmentCriteriaForm {
  InvestorOnboardingViewModel({
    required this.userId,
    this.city,
    UserRepository? userRepository,
  }) : _users = userRepository ?? UserRepository.instance;

  final String userId;
  final UserRepository _users;

  /// Where the investor is based (one city). Starts as their saved city, if
  /// they already chose one on Edit account.
  String? city;

  void selectCity(String value) => change(() => city = value);

  /// Saves the answers. Returns true when saved; otherwise [error] says why.
  Future<bool> submit() async {
    if (isLoading) return false;

    final ticketSize = this.ticketSize;
    final city = this.city;
    if (!criteriaComplete || ticketSize == null || city == null) {
      error = InvestorStrings.onboardingIncomplete;
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _users.saveInvestorOnboarding(
        uid: userId,
        sectors: orderedSectors,
        stages: orderedStages,
        ticketSize: ticketSize,
        city: city,
      );
      return true;
    } on AuthException catch (e) {
      error = e.failure == AuthFailure.network
          ? AppStrings.networkError
          : AppStrings.onboardingSaveFailed;
    } catch (_) {
      error = AppStrings.onboardingSaveFailed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// [user] with the saved answers, for the screens that open next.
  AppUser savedUser(AppUser user) => user.copyWith(
        onboardingCompleted: true,
        city: city,
        preferredSectors: orderedSectors,
        preferredStages: orderedStages,
        ticketSize: ticketSize,
      );
}
