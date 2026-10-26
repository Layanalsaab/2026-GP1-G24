/// Settings that belong to the deployment, not to the code.
class AppConfig {
  AppConfig._();

  /// The Google Apps Script web app that sends the invitation e-mails (see
  /// tools/invite_relay/README.md). If it is ever empty, sending fails with a
  /// clear message and the invitation stays "not sent".
  static const inviteRelayUrl =
      'https://script.google.com/macros/s/AKfycby587ehh_cOJZuv3jalbS-2VpxlxQLAn1pq_LSQ5AvKtCAYADY4QcGzrmpei0uIiYzdmg/exec';

  /// Someone who ALREADY has an account and is invited to a team: true joins
  /// them at once, false asks "Join X? Accept / Decline" the next time they
  /// open the app. (A brand-new account always joins automatically.)
  ///
  /// True for now: Accept / Decline comes back with the notifications.
  static const autoJoinExistingAccounts = true;

  /// The web address the "Open Start.sa" button of the invitation e-mail
  /// points to (the page on Firebase Hosting; Android opens the app instead
  /// of the page when it is installed).
  static const inviteLinkBase = 'https://startsa-ea49e.web.app/invite';

  /// The link of one invitation.
  static String inviteLink(String invitationId) =>
      '$inviteLinkBase?i=${Uri.encodeQueryComponent(invitationId)}';
}
