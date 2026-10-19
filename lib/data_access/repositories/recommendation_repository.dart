import '../../models/app_user.dart';
import '../../models/home_item.dart';
import '../../models/investor_criteria.dart';
import '../../models/investor_profile.dart';
import '../../models/startup.dart';
import '../mock_data/prototype_seed.dart';

/// A match between an investor and a startup: "92% match",
/// "Same sector and stage".
class MatchResult {
  const MatchResult(this.percent, this.reason);

  final int percent;
  final String reason;
}

/// The matching rules (docs/08 section 4), pure so they are easy to test.
///
/// Weights: sectors 0.41, stages 0.29, commerce models 0.18, region 0.12
/// (a small boost: the "regions" question was removed, so the city is used).
/// A pair needs a sector or a stage in common to match at all.
class Recommender {
  Recommender._();

  static const sectorWeight = 0.41;
  static const stageWeight = 0.29;
  static const modelWeight = 0.18;
  static const regionWeight = 0.12;

  /// An investor's [criteria] against a [startup]. Null when they share
  /// neither a sector nor a stage.
  static MatchResult? investorToStartup(
    InvestorCriteria criteria,
    Startup startup, {
    String? investorCity,
  }) {
    final sector =
        criteria.sectors.contains(startup.sectorLabel) ||
        criteria.sectors.contains(startup.sector.label);
    final stage =
        criteria.stages.contains(startup.stageLabel) ||
        criteria.stages.contains(startup.stage.label);
    final model = criteria.commerceModels.contains(startup.businessModel.label);
    final region =
        investorCity != null && investorCity == startup.location.label;
    return _result(sector: sector, stage: stage, model: model, region: region);
  }

  /// A [startup] looking for investors against an [investor] profile. Null
  /// when they share neither a sector nor a stage.
  static MatchResult? startupToInvestor(
    Startup startup,
    InvestorProfile investor,
  ) {
    final sector = investor.sectors.contains(startup.sectorLabel);
    final stage = investor.stages.contains(startup.stageLabel);
    final region = investor.city == startup.location.label;
    return _result(sector: sector, stage: stage, model: false, region: region);
  }

  static MatchResult? _result({
    required bool sector,
    required bool stage,
    required bool model,
    required bool region,
  }) {
    if (!sector && !stage) return null;
    final score =
        (sector ? sectorWeight : 0) +
        (stage ? stageWeight : 0) +
        (model ? modelWeight : 0) +
        (region ? regionWeight : 0);
    // Spread 0..1 over 50..99 so a weak match never reads as "12%".
    final percent = (50 + score * 49).round().clamp(50, 99);
    final parts = [
      if (sector) 'sector',
      if (stage) 'stage',
      if (region) 'region',
    ];
    return MatchResult(percent, 'Same ${_join(parts)}');
  }

  /// ["sector", "stage", "region"] -> "sector, stage and region".
  static String _join(List<String> parts) {
    if (parts.length == 1) return parts.first;
    return '${parts.take(parts.length - 1).join(', ')} and ${parts.last}';
  }
}

/// The Explore -> Matches lists.
///
/// The sample startups and investors carry the prototype's fixed match
/// percentages (so the demo reads like the design); anything else is scored
/// by [Recommender].
class RecommendationRepository {
  RecommendationRepository();

  /// The app-wide instance. Tests replace it with a fake.
  static RecommendationRepository instance = RecommendationRepository();

  /// Startups matched to the signed-in [investor], best first. An investor
  /// who has not answered the sign-up questions sees the sample matches.
  List<HomeItem> startupsForInvestor(AppUser investor) {
    final criteria = investor.investorCriteria;
    final scored = <HomeItem>[];
    for (final s in PrototypeSeed.startups) {
      final fixed = PrototypeSeed.startupMatches[s.id];
      if (criteria == null) {
        if (fixed != null) {
          scored.add(HomeItem.fromStartup(s).withMatch(fixed.$1, fixed.$2));
        }
        continue;
      }
      final m = Recommender.investorToStartup(
        criteria,
        s,
        investorCity: investor.city,
      );
      if (m != null) {
        scored.add(HomeItem.fromStartup(s).withMatch(m.percent, m.reason));
      }
    }
    scored.sort((a, b) => b.matchPercent!.compareTo(a.matchPercent!));
    return scored;
  }

  /// Investors matched to the founder's [startup], best first. The sample
  /// startup "Rafeeq Health" shows the sample matches.
  List<HomeItem> investorsForStartup(Startup startup) {
    final scored = <HomeItem>[];
    for (final i in PrototypeSeed.investors) {
      if (startup.id == 'mock-rafeeq') {
        if (i.matchPercent != null) {
          scored.add(HomeItem.fromInvestor(i));
        }
        continue;
      }
      final m = Recommender.startupToInvestor(startup, i);
      if (m != null) {
        scored.add(HomeItem.fromInvestor(i).withMatch(m.percent, m.reason));
      }
    }
    scored.sort((a, b) => b.matchPercent!.compareTo(a.matchPercent!));
    return scored;
  }
}
