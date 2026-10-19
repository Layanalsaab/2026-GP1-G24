import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import 'founder_ui.dart';

/// What the founder chose when leaving a half-filled startup form.
enum LeaveChoice { saveDraft, discard, keepEditing }

/// The warning shown when a founder leaves the Add / Edit startup form with
/// changes: "Save as draft" (new startups only), "Discard" and "Keep
/// editing". Closing it any other way counts as "Keep editing".
Future<LeaveChoice> showLeaveFormSheet(
  BuildContext context, {
  required bool canSaveDraft,
}) async {
  final r = await showAppBottomSheet<LeaveChoice>(
    context,
    builder: (_) => _LeaveFormSheet(canSaveDraft: canSaveDraft),
  );
  return r ?? LeaveChoice.keepEditing;
}

class _LeaveFormSheet extends StatelessWidget {
  const _LeaveFormSheet({required this.canSaveDraft});

  final bool canSaveDraft;

  @override
  Widget build(BuildContext context) {
    void pick(LeaveChoice c) => Navigator.of(context).pop(c);
    return AppSheetScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Pop(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: canSaveDraft
                      ? AppColors.tagGoldFill
                      : AppColors.errorFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: canSaveDraft
                    ? const AppIcon.outline(
                        AppIcons.pencil,
                        size: 28,
                        color: AppColors.gold700,
                      )
                    : const AppIcon.filled(
                        AppIcons.trash,
                        size: 28,
                        color: AppColors.error,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                canSaveDraft
                    ? FounderToolsStrings.leaveDraftTitle
                    : FounderToolsStrings.leaveEditTitle,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 21, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              canSaveDraft
                  ? FounderToolsStrings.leaveDraftMessage
                  : FounderToolsStrings.leaveEditMessage,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
            ),
            const SizedBox(height: 22),
            if (canSaveDraft) ...[
              AppButton(
                label: FounderToolsStrings.saveDraft,
                onPressed: () => pick(LeaveChoice.saveDraft),
              ),
              const SizedBox(height: 10),
            ],
            AppButton(
              label: canSaveDraft
                  ? FounderToolsStrings.discard
                  : FounderToolsStrings.discardChanges,
              variant: canSaveDraft
                  ? AppButtonVariant.outline
                  : AppButtonVariant.danger,
              onPressed: () => pick(LeaveChoice.discard),
            ),
            const SizedBox(height: 4),
            AppButton(
              label: FounderToolsStrings.keepEditing,
              variant: AppButtonVariant.ghost,
              onPressed: () => pick(LeaveChoice.keepEditing),
            ),
          ],
        ),
      ),
    );
  }
}
