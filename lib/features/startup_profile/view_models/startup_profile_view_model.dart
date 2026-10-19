import 'package:flutter/foundation.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/safe_notifier.dart';
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
  }) : _session = session ?? AppSession.instance,
       _discovery = discovery ?? DiscoveryRepository.instance,
       _forcedPreview = preview;

  /// Tab order: Overview, Business, Team, Financials.
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
  /// "HealthTech · Pre-seed · Riyadh · Founded 2024": the founded year is a key
  /// fact, so it sits in the header and not in the financials.
  String get infoLine => [
    startup.sectorLabel,
    startup.stageLabel,
    startup.location.label,
    if (startup.foundedYear != null)
      '${ProfileStrings.kvFounded} ${startup.foundedYear}',
  ].join(' · ');

  String get pitch => startup.summary;

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
  bool get hasMarket => tam != null || sam != null || som != null;
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
      (ProfileStrings.kvCity, startup.location.label),
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
