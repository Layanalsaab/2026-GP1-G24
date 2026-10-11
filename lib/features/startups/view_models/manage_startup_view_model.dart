import 'package:flutter/foundation.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../models/startup.dart';
import 'startup_error_message.dart';

/// State of the Manage page for one startup (Figma "V2 · 44c"): the startup
/// as last saved, and the delete request.
class ManageStartupViewModel extends ChangeNotifier {
  ManageStartupViewModel({required this.startup, StartupRepository? repository})
    : _repository = repository ?? StartupRepository.instance;

  final StartupRepository _repository;
  bool _disposed = false;

  /// The startup as last saved.
  Startup startup;

  bool isDeleting = false;

  /// Message from the last failed delete.
  String? deleteError;

  /// Shows the startup as saved on the Edit page.
  void update(Startup startup) {
    this.startup = startup;
    _notify();
  }

  /// Deletes the startup (and its logo). Returns true on success.
  Future<bool> delete() async {
    if (isDeleting) return false;
    isDeleting = true;
    deleteError = null;
    _notify();
    try {
      await _repository.delete(startup);
      return true;
    } catch (e) {
      deleteError = '${StartupStrings.deleteFailed} ${startupErrorMessage(e)}';
      return false;
    } finally {
      isDeleting = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
