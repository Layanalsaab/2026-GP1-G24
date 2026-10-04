import 'package:flutter/foundation.dart';

/// Makes a view model ignore updates after its screen has closed.
///
/// A request (saving, loading) can finish after the user pressed Back and the
/// view model was disposed. Calling [notifyListeners] then throws in debug
/// mode; with this mixin the late update is simply dropped.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
