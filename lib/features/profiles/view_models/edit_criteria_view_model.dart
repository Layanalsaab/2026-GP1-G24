import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/investor_strings.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import 'investment_criteria_form.dart';

/// Logic for Edit criteria (PBI 22): starts from the investor's saved
/// criteria and saves the changes.
class EditCriteriaViewModel extends ChangeNotifier
    with SafeNotifier, InvestmentCriteriaForm {
  EditCriteriaViewModel({required this.user, UserRepository? userRepository})
      : _users = userRepository ?? UserRepository.instance {
    sectors.addAll(user.preferredSectors);
    stages.addAll(user.preferredStages);
    ticketSize = user.ticketSize;
  }

  /// The profile as it was when the screen opened.
  final AppUser user;
  final UserRepository _users;

  /// Saves the criteria. Returns the updated user, or null when something is
  /// missing or saving failed (see [error]).
  Future<AppUser?> submit() async {
    if (isLoading) return null;

    final ticketSize = this.ticketSize;
    if (!criteriaComplete || ticketSize == null) {
      error = InvestorStrings.criteriaIncomplete;
      notifyListeners();
      return null;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _users.updateInvestmentCriteria(
        uid: user.uid,
        sectors: orderedSectors,
        stages: orderedStages,
        ticketSize: ticketSize,
      );
      return user.copyWith(
        preferredSectors: orderedSectors,
        preferredStages: orderedStages,
        ticketSize: ticketSize,
      );
    } on AuthException catch (e) {
      error = e.failure == AuthFailure.network
          ? AppStrings.networkError
          : AccountStrings.saveFailed;
    } catch (_) {
      error = AccountStrings.saveFailed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
