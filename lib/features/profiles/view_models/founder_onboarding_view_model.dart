import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../models/auth_failure.dart';

class FounderOnboardingViewModel extends ChangeNotifier {
  FounderOnboardingViewModel({
    required this.userId,
    UserRepository? userRepository,
  }) : _users = userRepository ?? UserRepository.instance;

  final String userId;
  final UserRepository _users;

  String? sector;
  String? stage;
  String? city;

  bool isLoading = false;
  String? error;

  void selectSector(String value) => _select(() => sector = value);
  void selectStage(String value) => _select(() => stage = value);
  void selectCity(String value) => _select(() => city = value);

  void _select(VoidCallback change) {
    if (isLoading) return;
    change();
    error = null;
    notifyListeners();
  }

  /// Saves the answers. Returns true when saved; otherwise [error] says why.
  Future<bool> submit() async {
    if (isLoading) return false;

    final sector = this.sector;
    final stage = this.stage;
    final city = this.city;
    if (sector == null || stage == null || city == null) {
      error = AppStrings.onboardingIncomplete;
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _users.saveFounderOnboarding(
        uid: userId,
        sector: sector,
        stage: stage,
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
}
