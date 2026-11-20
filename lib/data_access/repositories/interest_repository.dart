import 'package:flutter/foundation.dart';

import '../../models/expressed_interest.dart';
import '../mock_data/prototype_seed.dart';

/// Guests' "Express interest" in startups.
class InterestRepository {
  InterestRepository({this.sample = false})
    : _inbox = sample ? List.of(PrototypeSeed.interests) : [];

  /// Tests: start with the sample interests of the sample startup.
  final bool sample;

  /// The app-wide instance.
  static InterestRepository instance = InterestRepository();

  List<ExpressedInterest> _inbox;
  final ValueNotifier<int> _inboxVersion = ValueNotifier<int>(0);
  final ValueNotifier<Set<String>> _sent = ValueNotifier<Set<String>>({});

  ValueListenable<int> get inboxChanges => _inboxVersion;

  /// Keys (s-{startupId}) the guest has expressed interest in.
  ValueListenable<Set<String>> get sent => _sent;

  /// Interests received by startupId.
  List<ExpressedInterest> inboxFor(String startupId) => [
    for (final i in _inbox)
      if (i.startupId == startupId) i,
  ];

  int newCount(String startupId) =>
      inboxFor(startupId).where((i) => i.isNew).length;

  /// Marks one as seen (the founder replied).
  void markSeen(String interestId) {
    _inbox = [
      for (final i in _inbox)
        if (i.id == interestId) i.markSeen() else i,
    ];
    _inboxVersion.value++;
  }

  /// Deleting a startup removes every interest message it received.
  void removeForStartup(String startupId) {
    _inbox = [
      for (final i in _inbox)
        if (i.startupId != startupId) i,
    ];
    _inboxVersion.value++;
  }

  bool hasSent(String key) => _sent.value.contains(key);

  void clear() {
    _inbox = sample ? List.of(PrototypeSeed.interests) : [];
    _sent.value = {};
    _inboxVersion.value++;
  }
}
