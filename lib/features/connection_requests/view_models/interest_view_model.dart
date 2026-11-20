import 'package:flutter/foundation.dart';

import '../../../data_access/repositories/interest_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/expressed_interest.dart';

/// State of Manage startup -> Interest (docs/05 D3): the New / All filter and
/// marking a person as replied to. Follows [InterestRepository] changes.
class InterestViewModel extends ChangeNotifier with SafeNotifier {
  InterestViewModel({required this.startupId, InterestRepository? interests})
    : _interests = interests ?? InterestRepository.instance {
    _interests.inboxChanges.addListener(notifyListeners);
  }

  final String startupId;
  final InterestRepository _interests;

  /// True: only new ones. False: everyone.
  bool onlyNew = true;

  void select({required bool onlyNew}) {
    if (this.onlyNew == onlyNew) return;
    this.onlyNew = onlyNew;
    notifyListeners();
  }

  int get newCount => _interests.newCount(startupId);
  int get allCount => _interests.inboxFor(startupId).length;

  List<ExpressedInterest> get visible => [
    for (final i in _interests.inboxFor(startupId))
      if (!onlyNew || i.isNew) i,
  ];

  @override
  void dispose() {
    _interests.inboxChanges.removeListener(notifyListeners);
    super.dispose();
  }
}
