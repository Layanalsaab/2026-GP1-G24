import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';
import '../view_models/my_startups_view_model.dart';

/// Opens the "Filter startups" sheet. Tapping an option applies it right away
/// (through the view model) and the sheet stays open; Done closes it.
Future<void> showStartupFilterSheet(
  BuildContext context,
  MyStartupsViewModel vm,
) => showAppBottomSheet<void>(
  context,
  builder: (_) => StartupFilterSheet(vm: vm),
);

/// Two groups, VISIBILITY (All / Public / Private) and MY ROLE (All /
/// Founder / Team member), small uppercase grey headings, and a Done button.
class StartupFilterSheet extends StatelessWidget {
  const StartupFilterSheet({super.key, required this.vm});

  final MyStartupsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: FounderToolsStrings.filterStartupsTitle,
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                children: [
                  const _GroupTitle(FounderToolsStrings.visibilityGroup),
                  for (final v in VisibilityFilter.values)
                    PickerOptionRow(
                      label: v.label,
                      selected: vm.visibility == v,
                      onTap: () => vm.setVisibility(v),
                    ),
                  const SizedBox(height: 8),
                  const _GroupTitle(FounderToolsStrings.roleGroup),
                  for (final r in RoleFilter.values)
                    PickerOptionRow(
                      label: r.label,
                      selected: vm.role == r,
                      onTap: () => vm.setRole(r),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: AppButton(
                label: FounderToolsStrings.done,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(
        text,
        style: AppText.sans(
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
