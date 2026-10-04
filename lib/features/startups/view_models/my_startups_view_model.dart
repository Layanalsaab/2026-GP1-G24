// State management: Provider.
//
// The rest of the app already keeps screen state in ChangeNotifier view
// models. Provider is the thinnest layer on top of that pattern: it creates a
// view model for a screen, disposes it with the screen, and lets small parts
// of the widget tree rebuild with `context.watch` / `context.select` instead
// of passing the view model down by hand. Riverpod would mean rewriting the
// existing view models for no gain at this size, so Provider is used for the
// whole startup feature.

import 'package:flutter/foundation.dart';

import '../../../data_access/repositories/startup_repository.dart';
import '../../../models/startup.dart';
import 'startup_error_message.dart';

/// The All / Public / Private chips above the list (Figma "V2 · 24").
enum StartupFilter { all, public, private }

/// State of the My Startups list.
class MyStartupsViewModel extends ChangeNotifier {
  MyStartupsViewModel({StartupRepository? repository})
    : _repository = repository ?? StartupRepository.instance;

  final StartupRepository _repository;

  List<Startup> startups = const [];

  /// True only for the first load, when there is nothing to show yet.
  bool isLoading = true;

  /// Set when the last load failed. Shown as a full-page error when the list
  /// is empty, or as a snackbar over an existing list.
  String? error;

  bool _disposed = false;

  bool get isEmpty => !isLoading && error == null && startups.isEmpty;

  StartupFilter filter = StartupFilter.all;

  /// The startups that match [filter], still most recently edited first.
  List<Startup> get visibleStartups => switch (filter) {
    StartupFilter.all => startups,
    StartupFilter.public => [
      for (final s in startups)
        if (s.isPublic) s,
    ],
    StartupFilter.private => [
      for (final s in startups)
        if (!s.isPublic) s,
    ],
  };

  void setFilter(StartupFilter value) {
    filter = value;
    _notify();
  }

  /// Loads the list. Used for the first load, Retry, pull-to-refresh, and
  /// after returning from Add/Edit. Never throws.
  Future<void> load() async {
    error = null;
    if (startups.isEmpty) isLoading = true;
    _notify();
    try {
      startups = await _repository.fetchMyStartups();
    } catch (e) {
      error = startupErrorMessage(e);
    } finally {
      isLoading = false;
      _notify();
    }
  }

  /// Removes a startup from the list right away after it was deleted on the
  /// Edit screen, so it doesn't flash back while the list reloads.
  void removeLocally(String startupId) {
    startups = [
      for (final s in startups)
        if (s.id != startupId) s,
    ];
    _notify();
  }

  // A load can finish after the screen is gone (e.g. the founder logs out).
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
