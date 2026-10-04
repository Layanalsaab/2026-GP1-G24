import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/investor_strings.dart';

/// The choices shared by the investor onboarding and Edit criteria: one or
/// more sectors, one or more stages, and one ticket size.
mixin InvestmentCriteriaForm on ChangeNotifier {
  final Set<String> sectors = {};
  final Set<String> stages = {};
  String? ticketSize;

  bool isLoading = false;

  /// Shown above the button when the answers can't be saved.
  String? error;

  void toggleSector(String value) => change(() => _toggle(sectors, value));
  void toggleStage(String value) => change(() => _toggle(stages, value));
  void selectTicketSize(String value) => change(() => ticketSize = value);

  /// Applies a selection change (ignored while saving) and clears the error.
  @protected
  void change(VoidCallback update) {
    if (isLoading) return;
    update();
    error = null;
    notifyListeners();
  }

  void _toggle(Set<String> chosen, String value) {
    if (!chosen.remove(value)) chosen.add(value);
  }

  /// True when at least one sector and one stage and a ticket size are chosen.
  /// Only values from the option lists count, so an old or renamed value in a
  /// saved profile can't slip through as "chosen".
  bool get criteriaComplete =>
      orderedSectors.isNotEmpty &&
      orderedStages.isNotEmpty &&
      InvestorStrings.ticketSizes.contains(ticketSize);

  /// The chosen sectors in the same order as the option list, so what is saved
  /// doesn't depend on the order they were tapped.
  List<String> get orderedSectors =>
      [for (final s in AppStrings.sectors) if (sectors.contains(s)) s];

  List<String> get orderedStages =>
      [for (final s in AppStrings.stages) if (stages.contains(s)) s];
}
