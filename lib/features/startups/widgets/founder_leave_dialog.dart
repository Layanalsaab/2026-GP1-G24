import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../shared_ui/widgets/forms/checkbox_card.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import 'founder_ui.dart';

/// "Leave Nova?" for the person who created the startup: the same card as
/// [showDiscardDialog] plus the "Keep my name as Founder (former)" box (not
/// ticked: keeping the name is her choice). Completes with whether to keep
/// the name, or null when she cancels.
Future<bool?> showFounderLeaveDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  var keep = false;
  return showAppDialog<bool>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AppDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 21, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
            ),
            const SizedBox(height: 16),
            CheckboxCard(
              compact: true,
              title: FounderToolsStrings.keepFounderName,
              description: FounderToolsStrings.keepFounderNameText,
              checked: keep,
              onChanged: (v) => setState(() => keep = v),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: FounderToolsStrings.leaveStartup,
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.of(ctx).pop(keep),
            ),
            const SizedBox(height: 4),
            AppButton(
              label: FounderToolsStrings.cancel,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
