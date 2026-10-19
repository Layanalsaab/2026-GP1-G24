import 'package:flutter/foundation.dart';

import '../../models/expressed_interest.dart';
import '../mock_data/prototype_seed.dart';

/// Guests' "Express interest" in startups.
///
/// - the **inbox** of a founder's startup: who expressed interest, with a
///   "new" dot until the founder replies (Manage startup -> Interest);
/// - the signed-out guest's **sent** interests, toggled on and off
///   ("Interest sent", tap again to withdraw).
///
/// TODO(backend): guests have no account. Use anonymous Auth or a callable
/// Cloud Function to write `interests` (docs/08 §3); today it lives in memory
/// for the session, seeded with sample interests of "Rafeeq Health".
class InterestRepository {
  InterestRepository() : _inbox = List.of(PrototypeSeed.interests);

  /// The app-wide instance. Tests replace it with a fake.
  static InterestRepository instance = InterestRepository();

  List<ExpressedInterest> _inbox;
  final ValueNotifier<int> _inboxVersion = ValueNotifier<int>(0);
  final ValueNotifier<Set<String>> _sent = ValueNotifier<Set<String>>({});

  ValueListenable<int> get inboxChanges => _inboxVersion;

  /// Keys (`s-<startupId>`) the guest has expressed interest in.
  ValueListenable<Set<String>> get sent => _sent;

  /// Interests received by [startupId].
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

  bool hasSent(String key) => _sent.value.contains(key);

  /// Sends the interest, or withdraws it. Returns true when it is now sent.
  bool toggleSent(String key) {
    final next = {..._sent.value};
    final added = next.add(key);
    if (!added) next.remove(key);
    _sent.value = next;
    return added;
  }

  void clear() {
    _inbox = List.of(PrototypeSeed.interests);
    _sent.value = {};
    _inboxVersion.value++;
  }
}
