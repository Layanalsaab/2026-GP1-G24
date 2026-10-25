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

/// Logic of the own profile (docs/05 C4): the profile on screen, kept fresh
/// from the repository, plus the founder's startups and the investor's
/// associations.
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
  /// The real ones are read from Firestore; the sample ones (interface only)
  /// are added until the invites exist.
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

  /// Counts edits shown with [updateUser], so a reload that started earlier
  /// can't replace them with older data.
  int _edits = 0;

  AppUser get user => _user;

  bool get isFounder => _user.isFounder;

  /// "Founder" / "Investor".
  String get roleLabel => AppStrings.roleName(_user.role);

  /// The chips under the name: a founder's sectors of interest, an
  /// investor's sectors (the typed "Other" replaces the label "Other").
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

  /// The Contact section: the email and the phone, each with whether it is
  /// public. On the user's OWN profile both are listed (a phone only when one
  /// is saved) with their pills; anybody else sees only the ones set to
  /// Public, and no Contact section at all when both are private.
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

  /// The sample startups an investor is associated with (none for real
  /// accounts until associations are stored in Firestore).
  List<Startup> get associations => _user.isInvestor
      ? _discovery.associationsOfInvestor(_user.uid)
      : const [];

  /// The user passed in may be older than what's saved, so fetch the latest
  /// profile (and the founder's startups). Failures keep what is shown.
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
      // Memberships are an extra: the founder's own startups still show.
    }
    // INTERFACE ONLY: the sample memberships, until the invites exist.
    entries.addAll(PrototypeSeed.sampleTeamStartups);
    return entries;
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

/// One line of the Contact section: what it is, its value and whether the
/// owner made it public.
class ContactRow {
  const ContactRow(this.kind, this.value, this.isPublic);

  final ContactKind kind;
  final String value;
  final bool isPublic;
}
