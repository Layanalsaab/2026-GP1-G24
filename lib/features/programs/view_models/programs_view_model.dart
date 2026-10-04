import 'package:flutter/foundation.dart';

import '../../../data_access/mock_data/mock_programs.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/program.dart';

/// Logic for the Programs tab. For now the list comes from sample data
/// (design phase); the category chips only change which chip is highlighted.
class ProgramsViewModel extends ChangeNotifier with SafeNotifier {
  int filterIndex = 0;

  List<Program> get programs => MockPrograms.all;

  void selectFilter(int index) {
    if (index == filterIndex) return;
    filterIndex = index;
    notifyListeners();
  }
}
