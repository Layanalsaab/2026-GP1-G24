import 'package:flutter/foundation.dart';

import '../../models/connection_request.dart';
import '../mock_data/prototype_seed.dart';

/// Requests between investors and startups.
class RequestRepository {
  RequestRepository({this.sample = false})
    : _inbox = sample ? List.of(PrototypeSeed.requests) : [];

  /// Tests: start with the sample requests of the sample startup.
  final bool sample;

  /// The app-wide instance.
  static RequestRepository instance = RequestRepository();

  List<ConnectionRequest> _inbox;
  final ValueNotifier<int> _inboxVersion = ValueNotifier<int>(0);
  final ValueNotifier<Set<String>> _outgoing = ValueNotifier<Set<String>>({});

  /// Bumps whenever the inbox changes (a status was set).
  ValueListenable<int> get inboxChanges => _inboxVersion;

  /// Keys (s-{startupId} / i-{investorId}) the user has sent a request to.
  ValueListenable<Set<String>> get outgoing => _outgoing;

  /// Requests received by startupId, newest first.
  List<ConnectionRequest> inboxFor(String startupId) => [
    for (final r in _inbox)
      if (r.startupId == startupId) r,
  ];

  int pendingCount(String startupId) =>
      inboxFor(startupId)
          .where((r) => r.status == RequestStatus.pending)
          .length;

  List<ConnectionRequest> acceptedFor(String startupId) => [
    for (final r in inboxFor(startupId))
      if (r.status == RequestStatus.accepted) r,
  ];

  /// Accepts or declines a request.
  void setStatus(String requestId, RequestStatus status) {
    _inbox = [
      for (final r in _inbox)
        if (r.id == requestId) r.copyWith(status: status) else r,
    ];
    _inboxVersion.value++;
  }

  /// Deleting a startup removes every request it received.
  void removeForStartup(String startupId) {
    _inbox = [
      for (final r in _inbox)
        if (r.startupId != startupId) r,
    ];
    _inboxVersion.value++;
  }

  bool hasSent(String key) => _outgoing.value.contains(key);

  /// Forgets everything of the session (log out).
  void clear() {
    _inbox = sample ? List.of(PrototypeSeed.requests) : [];
    _outgoing.value = {};
    _inboxVersion.value++;
  }
}
