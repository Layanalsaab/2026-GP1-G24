import 'package:flutter/foundation.dart';

import '../../../app_constants/program_strings.dart';
import '../../../data_access/mock_data/mock_programs.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/program.dart';

/// Logic for the Support Systems tab. For now the list comes from sample data
/// (design phase). The search box and the category chips (All, Accelerators,
/// Incubators, Venture studios, Angel networks) filter it.
class ProgramsViewModel extends ChangeNotifier with SafeNotifier {
  int filterIndex = 0;
  String query = '';

  /// The program type each chip stands for; null for "All".
  static const _types = <ProgramType?>[
    null,
    ProgramType.accelerator,
    ProgramType.incubator,
    ProgramType.studio,
    ProgramType.angelNetwork,
  ];

  List<Program> get programs {
    final type = _types[filterIndex.clamp(0, _types.length - 1)];
    final q = query.trim().toLowerCase();
    return [
      for (final p in MockPrograms.all)
        if ((type == null || p.type == type) &&
            (q.isEmpty ||
                '${p.name} ${p.about} ${p.city}'.toLowerCase().contains(q)))
          p,
    ];
  }

  List<String> get filters => ProgramStrings.filters;

  void selectFilter(int index) {
    if (index == filterIndex) return;
    filterIndex = index;
    notifyListeners();
  }

  void setQuery(String value) {
    if (value == query) return;
    query = value;
    notifyListeners();
  }
}
