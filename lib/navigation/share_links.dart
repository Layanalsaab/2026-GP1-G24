import '../app_constants/app_config.dart';
import '../data_access/repositories/discovery_repository.dart';
import '../data_access/repositories/startup_repository.dart';
import '../features/profiles/screens/investor_profile_screen.dart';
import '../helpers/app_session.dart';
import '../models/investor_profile.dart';
import '../models/list_entries.dart';
import '../models/startup.dart';
import '../shared_ui/widgets/overlays/app_toast.dart';
import 'app_router.dart';
import 'open_item.dart';

/// What a shared link points to.
enum ShareTarget { startup, investor }

/// A parsed share link: `https://<site>/startup/<id>` or
/// `https://<site>/investor/<id>`.
class ShareLinkTarget {
  const ShareLinkTarget(this.kind, this.id);

  final ShareTarget kind;
  final String id;
}

/// The links people share (the share icon of a startup or an investor) open
/// that page in the app:
///
/// * signed in: the page as usual for their role (their own startup opens
///   Manage / the preview, exactly like tapping it in a list);
/// * no account / signed out: Home as a guest, then the page (guest rules);
/// * a private, closed or deleted startup, or a missing investor: "This
///   startup is no longer available." and nothing else is shown.
///
/// Received by [InviteLinks] (the same App Links handling as the invitation
/// link); the web page on Firebase Hosting (hosting/open) covers people
/// whose phone does not hand the link to the app.
class ShareLinks {
  ShareLinks._();

  /// The page a share link points to, or null for any other link.
  static ShareLinkTarget? parse(Uri uri) {
    final base = Uri.parse(AppConfig.shareLinkBase);
    if (uri.host != base.host) return null;
    final parts = [
      for (final p in uri.pathSegments)
        if (p.isNotEmpty) p,
    ];
    if (parts.length != 2) return null;
    final kind = switch (parts[0]) {
      'startup' => ShareTarget.startup,
      'investor' => ShareTarget.investor,
      _ => null,
    };
    return kind == null ? null : ShareLinkTarget(kind, parts[1]);
  }

  static const startupGone = 'This startup is no longer available.';
  static const investorGone = 'This investor is no longer available.';

  /// Opens [target] on top of whatever is showing (Home as a guest first when
  /// nobody is signed in).
  static Future<void> open(ShareLinkTarget target) async {
    final key = AppToast.navigatorKey;
    var context = key.currentContext;
    if (context == null) return;
    final session = AppSession.instance;
    if (!session.isSignedIn && !session.isGuest) {
      AppRouter.openGuest(context);
    }
    switch (target.kind) {
      case ShareTarget.startup:
        Startup? startup;
        try {
          startup = await StartupRepository.instance.fetchById(target.id);
        } catch (_) {
          // Private (the rules refuse the read), deleted or unreachable.
          startup = null;
        }
        context = key.currentContext;
        if (context == null || !context.mounted) return;
        final uid = session.user?.uid;
        final belongs =
            startup != null &&
            (session.ownStartupIds.contains(startup.id) ||
                startup.founderId == uid ||
                StartupRole.of(startup, uid) != null);
        if (startup == null || (!startup.isListed && !belongs)) {
          AppToast.errorGlobal(startupGone);
          return;
        }
        openStartup(context, startup);
      case ShareTarget.investor:
        InvestorProfile? investor;
        try {
          investor = await DiscoveryRepository.instance.loadInvestor(target.id);
        } catch (_) {
          investor = null;
        }
        context = key.currentContext;
        if (context == null || !context.mounted) return;
        if (investor == null) {
          AppToast.errorGlobal(investorGone);
          return;
        }
        InvestorProfileScreen.open(context, investor);
    }
  }
}
