import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/notice_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/startup_notice.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../screens/manage_startup_screen.dart';
import 'founder_ui.dart';
import 'invitation_dialogs.dart';

class StartupNotices {
  StartupNotices._();

  static bool _showing = false;

  /// Shows what the signed-in founder hasn't seen yet.
  static Future<void> showPending(BuildContext context) async {
    final user = AppSession.instance.user;
    if (_showing || user == null || !user.isFounder) return;
    _showing = true;
    try {
      final inbox = NoticeRepository.instance;
      final notices = await inbox.mine();
      for (final n in notices) {
        if (!context.mounted) return;
        final view = await _show(context, n, closed: await _isClosed(n));
        await inbox.dismiss(n);
        if (view && context.mounted) {
          final startup = await StartupRepository.instance.fetchById(
            n.startupId,
          );
          if (startup != null && context.mounted) {
            ManageStartupScreen.open(context, startup);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Could not show the startup notices: $e');
    } finally {
      _showing = false;
    }
  }

  static Future<bool> _isClosed(StartupNotice n) async {
    if (n.type != StartupNotice.newFounder) return false;
    try {
      final s = await StartupRepository.instance.fetchById(n.startupId);
      return s?.isClosed ?? false;
    } catch (_) {
      return false;
    }
  }

  static String _icon(StartupNotice n) => switch (n.type) {
    StartupNotice.closed => AppIcons.lock,
    StartupNotice.deleted => AppIcons.trash,
    StartupNotice.declined => AppIcons.mail,
    StartupNotice.removed || StartupNotice.left => AppIcons.logout,
    _ => AppIcons.people,
  };

  static String _title(StartupNotice n) {
    final name = n.startupName;
    return switch (n.type) {
      StartupNotice.closed => FounderToolsStrings.noticeClosedTitle(name),
      StartupNotice.deleted => FounderToolsStrings.noticeDeletedTitle(name),
      StartupNotice.newFounder => FounderToolsStrings.noticeNewFounderTitle(
        name,
      ),
      StartupNotice.founderChanged =>
        FounderToolsStrings.noticeFounderChangedTitle(name),
      StartupNotice.handedOver => FounderToolsStrings.noticeHandedOverTitle(
        name,
      ),
      StartupNotice.declined => FounderToolsStrings.noticeDeclinedTitle,
      StartupNotice.removed => FounderToolsStrings.noticeRemovedTitle(name),
      _ => FounderToolsStrings.noticeLeftTitle(n.person, name),
    };
  }

  static String _message(StartupNotice n, {required bool closed}) {
    final name = n.startupName;
    return switch (n.type) {
      StartupNotice.closed => FounderToolsStrings.noticeClosedMessage,
      StartupNotice.deleted => FounderToolsStrings.noticeDeletedMessage,
      StartupNotice.newFounder =>
        closed
            ? FounderToolsStrings.noticeNewFounderClosedMessage
            : FounderToolsStrings.noticeNewFounderMessage,
      StartupNotice.founderChanged =>
        FounderToolsStrings.noticeFounderChangedMessage(n.person, name),
      StartupNotice.handedOver => FounderToolsStrings.noticeHandedOverMessage(
        n.person,
        name,
        n.stay,
      ),
      StartupNotice.declined => FounderToolsStrings.noticeDeclinedMessage(
        n.person,
        name,
      ),
      StartupNotice.removed => FounderToolsStrings.noticeRemovedMessage,
      _ => FounderToolsStrings.noticeLeftMessage(n.person, name),
    };
  }

  /// True when "View …" was tapped.
  static Future<bool> _show(
    BuildContext context,
    StartupNotice n, {
    required bool closed,
  }) async {
    // A startup I left for good is not mine to open any more.
    final canView =
        n.canView &&
        !(n.type == StartupNotice.handedOver && n.stay == null);
    final result = await showAppDialog<bool>(
      context,
      builder: (ctx) => AppDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogIcon(icon: _icon(n)),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                _title(n),
                textAlign: TextAlign.center,
                style: AppText.sans(size: 21, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _message(n, closed: closed),
              textAlign: TextAlign.center,
              style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
            ),
            const SizedBox(height: 22),
            if (canView) ...[
              AppButton(
                label: FounderToolsStrings.viewStartup(n.startupName),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 4),
            ],
            AppButton(
              label: FounderToolsStrings.noticeOk,
              variant: canView
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
}
