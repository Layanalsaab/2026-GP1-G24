import 'package:flutter/foundation.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../data_access/repositories/funding_round_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/funding_round.dart';
import '../../../models/investor_profile.dart';
import '../../../models/startup.dart';

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

  /// Pull to refresh: the startup is replaced by the latest copy.
  void replaceStartup(Startup fresh) {
    startup = fresh;
    notifyListeners();
  }

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

  CurrentRound? get currentRound {
    final open = openRound;
    if (open != null) {
      return CurrentRound(
        type: open.typeLabel,
        goal: open.amount,
        raised: startup.raisedInRound ?? open.raised,
      );
    }
    final goal = startup.fundingRequirement ?? 0;
    if (startup.seeksFunding && goal > 0) {
      return CurrentRound(
        type: startup.stageLabel,
        goal: goal,
        raised: startup.raisedInRound ?? 0,
      );
    }
    return null;
  }

  static const tabLabels = FounderToolsStrings.stepTitles;

  Startup startup;
  final AppSession _session;
  final DiscoveryRepository _discovery;
  final bool _forcedPreview;

  int tab = 0;

  void selectTab(int index) {
    if (index == tab) return;
    tab = index;
    notifyListeners();
  }

  bool get isPreview =>
      _forcedPreview ||
      (_session.isFounder && _session.ownStartupIds.contains(startup.id));
  bool get isGuest => _session.isGuest || !_session.isSignedIn;
  bool get isInvestor => _session.isInvestor;
  bool get showBookmark => !isPreview && !isGuest;
  bool get showShare => !isPreview;

  /// A closed startup shows no button.
  bool get showCta =>
      !isPreview && (isGuest || isInvestor) && !startup.isClosed;

  /// s-{id} for the bookmarks.
  String get key => 's-${startup.id}';

  String get ctaLabel =>
      isGuest ? ProfileStrings.expressInterest : ProfileStrings.sendRequest;

  /// "HealthTech · Pre-seed · Riyadh": the one sub-line under the name.
  String get infoLine => [
    startup.sectorLabel,
    startup.stageLabel,
    startup.location.label,
  ].join(' · ');

  String get previewText => startup.isPublic
      ? ProfileStrings.previewBar
      : ProfileStrings.previewBarPrivate;

  String get website => (startup.websiteUrl ?? '').trim();

  String? get raising {
    final v = startup.fundingRequirement;
    return v == null || v <= 0 ? null : Formatters.sarShort(v);
  }

  List<String> get lookingFor => [
    for (final l in startup.lookingFor) startup.lookingForLabelOf(l),
  ];

  String? get marketSize => _money(startup.marketSize);

  String? get founderName {
    final sample = _discovery.founderNameOf(startup);
    if (sample != null) return sample;
    final user = _session.user;
    if (user != null && user.uid == startup.founderId) return user.fullName;
    return null;
  }

  List<InvestorProfile> get associated =>
      _discovery.associatedInvestors(startup.id);

  /// The non-empty cells of "Funding and financials", in prototype order.
  List<(String, String)> get financials {
    return [
      (ProfileStrings.kvRaising, _money(startup.fundingRequirement) ?? ''),
      (ProfileStrings.kvValuation, _money(startup.valuation) ?? ''),
      (ProfileStrings.kvCapital, _money(startup.capital) ?? ''),
      (ProfileStrings.kvModel, startup.commerceModelLabel),
    ].where((r) => r.$2.isNotEmpty).toList();
  }

  List<double> get revenueValues => [
    for (final v in startup.expectedRevenue) (v ?? 0).toDouble(),
  ];

  bool get hasRevenue => revenueValues.any((v) => v > 0);

  static String? _money(int? v) =>
      v == null || v <= 0 ? null : Formatters.sarShort(v);
}

/// What the "Current round" card shows.
class CurrentRound {
  const CurrentRound({
    required this.type,
    required this.goal,
    required this.raised,
  });

  /// "Pre-seed", "Seed"...
  final String type;
  final int goal;
  final int raised;

  /// 40 for 200,000 of 500,000 (can go past 100; the bar stops at 100).
  int get percent => goal <= 0 ? 0 : (raised * 100 / goal).round();
}
