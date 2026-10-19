/// Text of the Explore -> Matches states (the cards themselves come from
/// MatchingRepository).
class MatchingStrings {
  MatchingStrings._();

  static const loadFailed = "Couldn't load your matches";
  static const loadFailedMessage = 'Check your connection and try again.';
  static const retry = 'Try again';

  static const noneTitle = 'No matches yet';
  static const noneInvestor =
      'Choose the sectors and stages you invest in to see startups that fit.';
  static const noneInvestorNoFit =
      'No startup fits your criteria yet. Check back as more startups join.';
  static const noneFounderNoStartup =
      'Add a startup to see the investors that fit it.';
  static const noneFounder =
      'No investor fits this startup yet. Check back as more investors join.';
}
