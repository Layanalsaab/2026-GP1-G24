import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../data_access/mock_data/prototype_seed.dart';
import '../../../models/app_user.dart';
import '../../../models/list_entries.dart';
import '../../../models/startup.dart';

class AccountViewModel extends ChangeNotifier with SafeNotifier {
  AccountViewModel({
    required this._user,
    UserRepository? userRepository,
    StartupRepository? startupRepository,
    DiscoveryRepository? discovery,
    AppSession? session,
  }) : _users = userRepository ?? UserRepository.instance,
       _startups = startupRepository ?? StartupRepository.instance,
       _discovery = discovery ?? DiscoveryRepository.instance,
       _session = session ?? AppSession.instance;

  final UserRepository _users;
  final StartupRepository _startups;
  final DiscoveryRepository _discovery;
  final AppSession _session;

  AppUser _user;

  /// The founder's startups (empty until loaded).
  List<Startup> startups = const [];

  /// The startups the founder belongs to as a co-founder or team member.
  List<MyStartupEntry> memberEntries = const [];

  /// Every startup of the founder's profile, each with their role in it.
  List<MyStartupEntry> get startupEntries => [
    for (final s in startups)
      MyStartupEntry(
        startup: s,
        role: StartupRole.founder,
        addedAt: s.createdAt ?? DateTime.now(),
      ),
    ...memberEntries,
  ];

  int _edits = 0;

  AppUser get user => _user;

  bool get isFounder => _user.isFounder;

  String get roleLabel => _user.isFounder
      ? AccountStrings.startupTitle(
          _user.uid,
          owned: startups,
          joined: [for (final e in memberEntries) e.role],
        )
      : AccountStrings.investorTitle;

  List<String> get sectors {
    final criteria = _user.investorCriteria;
    final raw = _user.isInvestor
        ? (criteria != null && criteria.sectors.isNotEmpty
              ? criteria.sectors
              : _user.preferredSectors)
        : _user.sectorsOfInterest;
    final other = _user.isInvestor
        ? criteria?.sectorsOther
        : _user.sectorsOther;
    return [
      for (final s in raw)
        if (s != AppStrings.otherSector)
          s
        else if ((other ?? '').trim().isNotEmpty)
          other!.trim(),
    ];
  }

  /// "Joined October 2026" (empty when the account date is unknown).
  String get joinedLabel =>
      _user.createdAt == null ? '' : AccountStrings.joined(_user.createdAt!);

  /// "+966 55 123 4567", or empty when no phone is saved.
  String get phoneLabel => (_user.phone ?? '').trim().isEmpty
      ? ''
      : AccountStrings.formatPhone(_user.phone!);

  String get linkedin => (_user.linkedin ?? '').trim();

  List<ContactRow> contactRows({bool isOwner = true}) {
    final rows = [
      ContactRow(ContactKind.email, _user.email, _user.emailPublic),
      if (phoneLabel.isNotEmpty)
        ContactRow(ContactKind.phone, phoneLabel, _user.phonePublic),
    ];
    return isOwner
        ? rows
        : [
            for (final r in rows)
              if (r.isPublic) r,
          ];
  }

  List<Startup> get associations => _user.isInvestor
      ? _discovery.associationsOfInvestor(_user.uid)
      : const [];

  Future<void> reload() async {
    final editsAtStart = _edits;
    if (_user.isFounder) await _loadStartups();
    try {
      final latest = await _users.getProfile(_user.uid);
      if (latest == null || _edits != editsAtStart) return;
      _user = latest;
      _session.updateUser(latest);
      notifyListeners();
    } catch (_) {
      // Keep the details we already have.
    }
  }

  Future<void> _loadStartups() async {
    try {
      startups = await _startups.fetchMyStartups();
      _session.setOwnStartupIds(startups.map((s) => s.id));
      memberEntries = await _loadMemberEntries();
      // The menu shows the same title as the profile.
      if (_user.isFounder) _session.setStartupTitle(roleLabel);
      notifyListeners();
    } catch (_) {
      // Keep the list as it is.
    }
  }

  Future<List<MyStartupEntry>> _loadMemberEntries() async {
    final entries = <MyStartupEntry>[];
    try {
      for (final s in await _startups.fetchMemberStartups()) {
        entries.add(
          MyStartupEntry(
            startup: s,
            role: StartupRole.of(s, _user.uid) ?? StartupRole.member,
            addedAt: s.updatedAt ?? s.createdAt ?? DateTime.now(),
          ),
        );
      }
    } catch (_) {
    }
    return entries;
  }

  Future<void> leave(String startupId, {bool alreadyLeft = false}) async {
    final entry = memberEntries
        .where((e) => e.startup.id == startupId)
        .firstOrNull;
    if (entry == null) return;
    memberEntries = [
      for (final e in memberEntries)
        if (e.startup.id != startupId) e,
    ];
    final session = _session;
    session.setMemberStartupIds({
      ...session.memberStartupIds.where((id) => id != startupId),
    });
    notifyListeners();
    // Manage already left it (alreadyLeft): only the list changes.
    if (!alreadyLeft && !PrototypeSeed.isSampleStartup(startupId)) {
      try {
        await _startups.leave(entry.startup);
      } catch (_) {
        memberEntries = [...memberEntries, entry];
        notifyListeners();
      }
    }
  }

  /// Re-reads the startups list (after Manage or Edit profile closed).
  Future<void> refreshStartups() async {
    if (_user.isFounder) await _loadStartups();
  }

  /// Shows the details saved on Edit profile.
  void updateUser(AppUser updated) {
    _edits++;
    _user = updated;
    _session.updateUser(updated);
    notifyListeners();
  }
}

enum ContactKind { email, phone }

/// One line of the Contact section: what it is, its value and whether the owner made it public.
class ContactRow {
  const ContactRow(this.kind, this.value, this.isPublic);

  final ContactKind kind;
  final String value;
  final bool isPublic;
}
