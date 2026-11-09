import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/invitation_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../screens/manage_startup_screen.dart';
import 'founder_ui.dart';
import 'invitation_dialogs.dart';

/// The one-time pop-ups about my startups, shown the next time the app opens
/// (docs: Closing a Startup, Leaving and Deleting an Account):
///
/// * a team's startup was closed (by its owner, or because the owner deleted
///   her account): "Nova has been closed";
/// * a startup got a new owner: "Ownership of Nova has changed", or "You are
///   now the owner of Nova" for the new owner;
/// * the person I invited to take over declined.
///
/// Each one is shown once per account on this phone (remembered in
/// SharedPreferences), and only for what happened in the last 30 days.
class StartupNotices {
  StartupNotices._();

  static const _recent = Duration(days: 30);
  static bool _showing = false;

  static String _key(String uid) => 'startup_notices_$uid';

  /// Shows what the signed-in founder hasn't seen yet, one pop-up after the
  /// other. "View Nova" opens the startup (the rest wait for next time).
  static Future<void> showPending(BuildContext context) async {
    final user = AppSession.instance.user;
    if (_showing || user == null || !user.isFounder) return;
    _showing = true;
    try {
      final seen = await _seen(user.uid);
      final notices = await _collect(user.uid, seen);
      for (final n in notices) {
        if (!context.mounted) return;
        final view = await _show(context, n);
        await _remember(user.uid, n.key);
        if (view && n.startup != null && context.mounted) {
          ManageStartupScreen.open(context, n.startup!);
          return;
        }
      }
    } catch (e) {
      debugPrint('Could not show the startup notices: $e');
    } finally {
      _showing = false;
    }
  }

  static Future<List<_Notice>> _collect(String uid, Set<String> seen) async {
    final repo = StartupRepository.instance;
    final all = [
      ...await repo.fetchMyStartups(),
      ...await repo.fetchMemberStartups(),
    ];
    final now = DateTime.now();
    bool recent(DateTime? t) => t != null && now.difference(t) < _recent;
    final out = <_Notice>[];
    for (final s in all) {
      if (s.isClosed) {
        final key = 'closed:${s.id}';
        // The owner who closed it already knows.
        if (s.founderId != uid && recent(s.closedAt) && !seen.contains(key)) {
          out.add(
            _Notice(
              key,
              title: FounderToolsStrings.noticeClosedTitle(s.name),
              message: FounderToolsStrings.noticeClosedMessage,
              icon: AppIcons.lock,
              startup: s,
            ),
          );
        }
        continue;
      }
      final changed = s.ownerChangedAt;
      if (changed == null || !recent(changed)) continue;
      final key = 'owner:${s.id}:${changed.millisecondsSinceEpoch}';
      if (seen.contains(key)) continue;
      out.add(
        s.founderId == uid
            ? _Notice(
                key,
                title: FounderToolsStrings.noticeNewOwnerTitle(s.name),
                message: FounderToolsStrings.noticeNewOwnerMessage,
                startup: s,
              )
            : _Notice(
                key,
                title: FounderToolsStrings.noticeOwnershipTitle(s.name),
                message: FounderToolsStrings.noticeOwnershipMessage(
                  s.nameOf(s.founderId, fallback: FounderToolsStrings.roleOwner),
                  s.name,
                ),
                startup: s,
              ),
      );
    }
    try {
      final declined = await InvitationRepository.instance
          .declinedOwnerInvitesOfMine();
      for (final inv in declined) {
        final key =
            'declined:${inv.id}:${inv.lastSentAt?.millisecondsSinceEpoch ?? 0}';
        if (seen.contains(key)) continue;
        out.add(
          _Notice(
            key,
            icon: AppIcons.mail,
            title: FounderToolsStrings.noticeDeclinedTitle,
            message: FounderToolsStrings.noticeDeclinedMessage(
              inv.emailLower,
              inv.startupName,
            ),
          ),
        );
      }
    } catch (_) {
      // The other pop-ups still show.
    }
    return out;
  }

  /// True when "View …" was tapped.
  static Future<bool> _show(BuildContext context, _Notice n) async {
    final startup = n.startup;
    final result = await showAppDialog<bool>(
      context,
      builder: (ctx) => AppDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogIcon(icon: n.icon),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                n.title,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 21, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              n.message,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
            ),
            const SizedBox(height: 22),
            if (startup != null) ...[
              AppButton(
                label: FounderToolsStrings.viewStartup(startup.name),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 4),
            ],
            AppButton(
              label: FounderToolsStrings.noticeOk,
              variant: startup != null
                  ? AppButtonVariant.ghost
                  : AppButtonVariant.primary,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      ),
    );
    return result == true;
  }

  static Future<Set<String>> _seen(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_key(uid)) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> _remember(String uid, String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key(uid)) ?? <String>[];
      if (!list.contains(key)) {
        // The last 200 are enough to never repeat one.
        list.add(key);
        if (list.length > 200) list.removeRange(0, list.length - 200);
        await prefs.setStringList(_key(uid), list);
      }
    } catch (_) {
      // Shown again next time at worst.
    }
  }
}

class _Notice {
  const _Notice(
    this.key, {
    required this.title,
    required this.message,
    this.icon = AppIcons.people,
    this.startup,
  });

  final String key;
  final String title;
  final String message;

  /// The round icon on top: a padlock (closed), people (a new owner) or an
  /// envelope (an invitation declined).
  final String icon;
  final Startup? startup;
}
