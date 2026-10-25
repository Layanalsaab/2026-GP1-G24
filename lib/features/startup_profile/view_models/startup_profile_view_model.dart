import 'package:flutter/foundation.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/funding_round_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/funding_round.dart';
import '../../../models/investor_profile.dart';
import '../../../models/startup.dart';

/// What the startup profile shows for one [Startup] and who is looking at it
/// (docs/05 section C1): the selected tab, the preview / CTA rules and the
/// display values of the Business, Team and Financials tabs.
///
/// Roles: a founder looking at their OWN startup sees the preview (no
/// bookmark, share or CTA); a founder looking at another startup sees no CTA;
/// an investor gets "Send investment request"; a guest gets "Express
/// interest" and never a bookmark.
class StartupProfileViewModel extends ChangeNotifier with SafeNotifier {
  StartupProfileViewModel({
    required this.startup,
    bool preview = false,
    AppSession? session,
    DiscoveryRepository? discovery,
    FundingRoundRepository? roundsRepository,
    List<FundingRound>? rounds,
  }) : rounds = rounds ?? const [],
       _session = session ?? AppSession.instance,
       _discovery = discovery ?? DiscoveryRepository.instance,
       _roundsOverride = roundsRepository,
       _forcedPreview = preview {
    if (rounds == null) loadRounds();
  }

  /// The funding rounds shown on the Funding tab and in the Raising tile,
  /// loaded from Firestore (or the ones passed in).
  List<FundingRound> rounds;

  final FundingRoundRepository? _roundsOverride;

  bool isLoadingRounds = false;
  bool roundsFailed = false;

  Future<void> loadRounds() async {
    isLoadingRounds = true;
    roundsFailed = false;
    notifyListeners();
    try {
      rounds = await (_roundsOverride ?? FundingRoundRepository.instance)
          .roundsOf(startup.id);
    } catch (e) {
      roundsFailed = true;
      debugPrint('Loading the funding rounds failed: $e');
    } finally {
      isLoadingRounds = false;
      notifyListeners();
    }
  }

  /// The text of the rounds table while it has no rows.
  String get roundsEmptyText => isLoadingRounds
      ? 'Loading funding rounds…'
      : roundsFailed
      ? 'Couldn’t load the funding rounds.'
      : 'No funding rounds yet.';

  /// The open round (newest first), or null.
  FundingRound? get openRound {
    final sorted = [...rounds]..sort((a, b) => b.number.compareTo(a.number));
    for (final r in sorted) {
      if (r.isOpen) return r;
    }
    return null;
  }

  /// Rounds, newest first.
  List<FundingRound> get roundsNewestFirst =>
      [...rounds]..sort((a, b) => b.number.compareTo(a.number));

  /// The "Current round" card: the open round, or (no round but the startup
  /// is raising) the Step 7 values with the startup's stage as the type.
  /// Raised is the larger of "already raised in this round" and the total of
  /// the accepted requests. Null when the startup is not raising.
  CurrentRound? get currentRound {
    final accepted = RequestRepository.instance
        .acceptedFor(startup.id)
        .fold<int>(0, (sum, r) => sum + r.amount);
    final open = openRound;
    if (open != null) {
      final base = startup.raisedInRound ?? open.raised;
      return CurrentRound(
        type: open.typeLabel,
        goal: open.amount,
        raised: base > accepted ? base : accepted,
        wantsLead: open.wantsLeadInvestor ?? startup.wantsLeadInvestor,
      );
    }
    final goal = startup.fundingRequirement ?? 0;
    if (startup.seeksFunding && goal > 0) {
      final base = startup.raisedInRound ?? 0;
      return CurrentRound(
        type: startup.stageLabel,
        goal: goal,
        raised: base > accepted ? base : accepted,
        wantsLead: startup.wantsLeadInvestor,
      );
    }
    return null;
  }

  /// Tab order: Overview, Business, Team, Funding.
  static const tabLabels = [
    ProfileStrings.tabOverview,
    ProfileStrings.tabBusiness,
    ProfileStrings.tabTeam,
    ProfileStrings.tabFinancials,
  ];

  final Startup startup;
  final AppSession _session;
  final DiscoveryRepository _discovery;
  final bool _forcedPreview;

  int tab = 0;

  void selectTab(int index) {
    if (index == tab) return;
    tab = index;
    notifyListeners();
  }

  // ---- Who is looking ----
  bool get isPreview =>
      _forcedPreview ||
      (_session.isFounder && _session.ownStartupIds.contains(startup.id));
  bool get isGuest => _session.isGuest || !_session.isSignedIn;
  bool get isInvestor => _session.isInvestor;
  bool get showBookmark => !isPreview && !isGuest;
  bool get showShare => !isPreview;
  bool get showCta => !isPreview && (isGuest || isInvestor);

  /// `s-<id>` for the bookmark, request and interest repositories.
  String get key => 's-${startup.id}';

  String get ctaLabel => isGuest
      ? (ctaDone ? ProfileStrings.interestSent : ProfileStrings.expressInterest)
      : (ctaDone ? ProfileStrings.requestSent : ProfileStrings.sendRequest);

  /// Whether the request / interest was already sent (set by the screen from
  /// the repositories).
  bool ctaDone = false;

  // ---- Header ----
  /// "HealthTech · Pre-seed · Riyadh": the one sub-line under the name.
  String get infoLine => [
    startup.sectorLabel,
    startup.stageLabel,
    startup.location.label,
  ].join(' · ');

  /// The preview bar sentence (a private startup says only the team sees it).
  String get previewText => startup.isPublic
      ? ProfileStrings.previewBar
      : ProfileStrings.previewBarPrivate;

  String get website => (startup.websiteUrl ?? '').trim();

  String? get raising {
    final v = startup.fundingRequirement;
    return v == null || v <= 0 ? null : Formatters.sarShort(v);
  }

  // ---- Overview ----
  List<String> get lookingFor => [
    for (final l in startup.lookingFor) startup.lookingForLabelOf(l),
  ];

  // ---- Business ----
  String? get tam => _money(startup.tam);
  String? get sam => _money(startup.sam);
  String? get som => _money(startup.som);
  bool get hasMarket => tam != null;

  /// The target market size in short form: "SAR 2.4B".
  String get targetMarketShort => Formatters.sarShort(startup.tam ?? 0);
  bool get hasBusiness => startup.hasBusinessDetails;

  // ---- Team ----
  /// The founder's name: sample data, or the signed-in owner.
  String? get founderName {
    final sample = _discovery.founderNameOf(startup);
    if (sample != null) return sample;
    final user = _session.user;
    if (user != null && user.uid == startup.founderId) return user.fullName;
    return null;
  }

  List<InvestorProfile> get associated =>
      _discovery.associatedInvestors(startup.id);

  bool get hasTeamContent => founderName != null || startup.team.isNotEmpty;

  // ---- Financials ----
  /// The non-empty cells of "Funding and financials", in prototype order.
  List<(String, String)> get financials {
    final lead = startup.wantsLeadInvestor;
    return [
      (ProfileStrings.kvRaising, _money(startup.fundingRequirement) ?? ''),
      (
        ProfileStrings.kvLead,
        lead == null
            ? ''
            : (lead ? ProfileStrings.kvLeadYes : ProfileStrings.kvLeadNo),
      ),
      (ProfileStrings.kvValuation, _money(startup.valuation) ?? ''),
      (ProfileStrings.kvCapital, _money(startup.capital) ?? ''),
      (ProfileStrings.kvModel, startup.businessModelLabel),
    ].where((r) => r.$2.isNotEmpty).toList();
  }

  List<double> get revenueValues => [
    for (final v in startup.expectedRevenue) (v ?? 0).toDouble(),
  ];

  bool get hasRevenue => revenueValues.any((v) => v > 0);

  List<String> get revenueLabels => ['Year 1', 'Year 2', 'Year 3'];

  List<String> get revenueValueLabels => [
    for (final v in startup.expectedRevenue)
      (v ?? 0) > 0 ? Formatters.shortMoney(v!) : '—',
  ];

  static String? _money(int? v) =>
      v == null || v <= 0 ? null : Formatters.sarShort(v);
}

/// What the "Current round" card shows.
class CurrentRound {
  const CurrentRound({
    required this.type,
    required this.goal,
    required this.raised,
    required this.wantsLead,
  });

  /// "Pre-seed", "Seed"...
  final String type;
  final int goal;
  final int raised;
  final bool? wantsLead;

  /// 40 for 200,000 of 500,000 (can go past 100; the bar stops at 100).
  int get percent => goal <= 0 ? 0 : (raised * 100 / goal).round();
}
