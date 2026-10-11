import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../data_access/mock_data/mock_investors.dart';
import '../../../data_access/mock_data/mock_startups.dart';
import '../../../helpers/formatters.dart';
import '../../../models/startup.dart';
import '../../../models/startup_association.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../../../shared_ui/common_widgets/confirm_dialog.dart';
import '../../../shared_ui/common_widgets/plain_top_bar.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/manage_startup_view_model.dart';
import '../widgets/startup_form_page.dart';
import '../widgets/startup_logo.dart';
import '../widgets/startup_tag.dart';
import '../widgets/startup_toast.dart';
import '../widgets/visibility_badge.dart';
import 'edit_startup_screen.dart';
import 'startup_profile_screen.dart';

/// Figma "V2 · 44c · Startup — Manage" and "V2 · 44e · Delete Startup —
/// Confirm": one startup's summary with Edit and Preview, then the activity,
/// investment associations and fundraising calculator areas, and Delete.
///
/// Activity tracking and adding investors are not built yet. A startup the
/// user created therefore shows honest zeros and no associations; only the
/// built-in sample startups show sample numbers and associations. Tapping an
/// association opens that investor's profile; the calculator is a
/// placeholder (not tappable).
///
/// Pops with a [StartupFormResult] only when the startup was deleted.
class ManageStartupScreen extends StatelessWidget {
  const ManageStartupScreen({super.key, required this.startup});

  final Startup startup;

  static Future<StartupFormResult?> open(
    BuildContext context,
    Startup startup,
  ) => Navigator.of(context).push<StartupFormResult>(
    MaterialPageRoute(builder: (_) => ManageStartupScreen(startup: startup)),
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageStartupViewModel(startup: startup),
      child: const _ManageView(),
    );
  }
}

// Sample numbers (Figma), shown only for the built-in sample startups.
typedef _Stat = ({
  String label,
  String value,
  String? change,
  List<double>? bars,
});

const _sampleActivity = [
  (
    label: StartupStrings.activityViews,
    value: '128',
    change: '+18%',
    bars: [8.0, 12.0, 9.0, 15.0, 13.0, 18.0, 22.0],
  ),
  (
    label: StartupStrings.activityBookmarks,
    value: '14',
    change: '+4',
    bars: [7.0, 15.0, 7.0, 22.0, 15.0, 15.0, 22.0],
  ),
  (
    label: StartupStrings.activityRequests,
    value: '3',
    change: '+1',
    bars: [3.0, 22.0, 3.0, 3.0, 22.0, 3.0, 22.0],
  ),
];

class _ManageView extends StatelessWidget {
  const _ManageView();

  Future<void> _edit(BuildContext context) async {
    final vm = context.read<ManageStartupViewModel>();
    final result = await EditStartupScreen.open(context, vm.startup);
    if (result == null || !context.mounted) return;
    if (result.outcome == StartupFormOutcome.deleted) {
      Navigator.of(context).pop<StartupFormResult>(result);
      return;
    }
    vm.update(result.startup);
    showStartupToast(context, StartupStrings.saved);
  }

  void _preview(BuildContext context) {
    StartupProfileScreen.openPreview(
      context,
      context.read<ManageStartupViewModel>().startup,
    );
  }

  Future<void> _delete(BuildContext context, {bool confirmed = false}) async {
    if (!context.mounted) return;
    final vm = context.read<ManageStartupViewModel>();
    if (vm.isDeleting) return;
    final startup = vm.startup;
    if (!confirmed) {
      final ok = await showConfirmSheet(
        context,
        title: StartupStrings.deleteTitle(startup.name),
        message: StartupStrings.deleteBody,
        confirmLabel: StartupStrings.deleteConfirm,
        cancelLabel: StartupStrings.cancel,
        icon: svgIcon('st_trash.svg', size: 20),
      );
      if (!ok || !context.mounted) return;
    }
    final deleted = await vm.delete();
    if (!context.mounted) return;
    if (deleted) {
      Navigator.of(context).pop<StartupFormResult>((
        outcome: StartupFormOutcome.deleted,
        startup: startup,
      ));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(vm.deleteError ?? StartupStrings.deleteFailed),
          action: SnackBarAction(
            label: StartupStrings.retry,
            // Already confirmed once; don't ask again on retry.
            onPressed: () => _delete(context, confirmed: true),
          ),
        ),
      );
  }

  Future<void> _showMenu(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: svgIcon('st_pencil.svg', size: 18, color: AppColors.ink),
              title: const Text(StartupStrings.editStartup),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: svgIcon('st_eye_green.svg', size: 18),
              title: const Text(StartupStrings.preview),
              onTap: () => Navigator.of(sheetContext).pop('preview'),
            ),
            ListTile(
              leading: svgIcon('st_trash.svg', size: 18),
              title: Text(
                StartupStrings.deleteButton,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'edit':
        await _edit(context);
      case 'preview':
        _preview(context);
      case 'delete':
        await _delete(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ManageStartupViewModel>();
    final startup = vm.startup;
    final sample = MockStartups.isSample(startup);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: PopScope(
        canPop: !vm.isDeleting,
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              PlainTopBar(
                title: startup.name,
                leading: PlainTopBarIcon.back(context),
                trailing: [
                  PlainTopBarIcon(
                    asset: 'st_more.svg',
                    tooltip: StartupStrings.moreOptions,
                    onPressed: () => _showMenu(context),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    bottom:
                        AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    _Hero(startup: startup),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: StartupStrings.editStartup,
                              asset: 'st_pencil.svg',
                              filled: true,
                              onTap: () => _edit(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: StartupStrings.preview,
                              asset: 'st_eye_green.svg',
                              filled: false,
                              onTap: () => _preview(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ActivityCard(sample: sample),
                    _AssociationsCard(
                      associations: MockStartups.associationsOf(startup),
                    ),
                    const _CalculatorCard(),
                    _DeleteRow(
                      isDeleting: vm.isDeleting,
                      onTap: () => _delete(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo, name, tags, website and visibility.
class _Hero extends StatelessWidget {
  const _Hero({required this.startup});

  final Startup startup;

  @override
  Widget build(BuildContext context) {
    final website = startup.websiteUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      child: Column(
        children: [
          StartupLogo(
            initials: startup.initials,
            url: startup.logoUrl,
            size: 80,
            cornerFactor: 0.27,
            background: AppColors.tagGoldFill,
            foreground: AppColors.tagGoldText,
            fontSize: 26,
          ),
          const SizedBox(height: 10),
          Text(
            startup.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 22,
              color: AppColors.ink,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              StartupTag(startup.sectorLabel),
              StartupTag(startup.stageLabel),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  svgIcon('st_pin.svg', size: 14),
                  const SizedBox(width: 3),
                  Text(
                    startup.location.label,
                    style: AppText.sans(size: 13, color: AppColors.grey),
                  ),
                ],
              ),
            ],
          ),
          if (website != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                svgIcon('st_link.svg', size: 15),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    Formatters.shortUrl(website),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 14,
                      color: AppColors.moss600,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          VisibilityBadge(isPublic: startup.isPublic),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.asset,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.md);
    final color = filled ? AppColors.onDark : AppColors.moss600;
    return Material(
      color: filled ? AppColors.moss600 : AppColors.surface,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: shape,
            border: filled
                ? null
                : Border.all(color: AppColors.moss600, width: 1.25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              svgIcon(asset, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 14,
                    color: color,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded card with the Figma outline, 16 px from the page edges.
/// Everything in it is a placeholder, so it is not tappable.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

/// The Activity card. [sample] true: the Figma sample numbers, trend and
/// period. Otherwise (a startup the user created) there is no activity
/// tracking yet, so it shows honest zeros with no trend and no period.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.sample});

  final bool sample;

  @override
  Widget build(BuildContext context) {
    final List<_Stat> stats = sample
        ? _sampleActivity
        : const [
            (
              label: StartupStrings.activityViews,
              value: '0',
              change: null,
              bars: null,
            ),
            (
              label: StartupStrings.activityBookmarks,
              value: '0',
              change: null,
              bars: null,
            ),
            (
              label: StartupStrings.activityRequests,
              value: '0',
              change: null,
              bars: null,
            ),
          ];
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  StartupStrings.activityTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 15,
                    color: AppColors.ink,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (sample)
                Text(StartupStrings.activityPeriod, style: AppText.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: _StatTile(stat: stats[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 12,
              color: AppColors.grey,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            maxLines: 1,
            style: AppText.sans(
              size: 20,
              color: AppColors.ink,
              weight: FontWeight.w700,
            ),
          ),
          if (stat.change != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                svgIcon('st_up.svg', size: 11),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    stat.change!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 11,
                      color: AppColors.moss600,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (stat.bars != null) ...[
            const SizedBox(height: 6),
            _MiniBars(heights: stat.bars!),
          ],
        ],
      ),
    );
  }
}

/// Seven small bars, the last one dark (Figma "Mini bars", 22 px tall).
class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.heights});

  final List<double> heights;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < heights.length; i++)
            Container(
              width: 7,
              height: heights[i],
              decoration: BoxDecoration(
                color: i == heights.length - 1
                    ? AppColors.moss600
                    : AppColors.barMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

/// The founder's associations, with their status. Empty for a startup that
/// has none yet (every startup the user creates).
class _AssociationsCard extends StatelessWidget {
  const _AssociationsCard({required this.associations});

  final List<StartupAssociation> associations;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            StartupStrings.associationsTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 15,
              color: AppColors.ink,
              weight: FontWeight.w700,
            ),
          ),
          if (associations.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(StartupStrings.noAssociations, style: AppText.caption),
          ],
          for (final item in associations) ...[
            const SizedBox(height: AppSpacing.sm),
            _AssociationRow(item: item),
          ],
          const SizedBox(height: AppSpacing.md),
          const _DashedButton(label: StartupStrings.addInvestor),
        ],
      ),
    );
  }
}

/// One association: avatar, name and status. Opens the investor's profile.
class _AssociationRow extends StatelessWidget {
  const _AssociationRow({required this.item});

  final StartupAssociation item;

  String get _status => !item.isApproved
      ? StartupStrings.associationWaiting
      : item.isPublic
      ? StartupStrings.associationApproved
      : StartupStrings.associationApprovedPrivate;

  @override
  Widget build(BuildContext context) {
    final investor = MockInvestors.byName(item.name);
    final shape = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: investor != null,
      child: InkWell(
        borderRadius: shape,
        onTap: investor == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvestorProfileScreen(investor: investor),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _Avatar(
                initials: Startup.initialsOf(item.name),
                size: 36,
                fontSize: 13,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 14,
                        color: AppColors.ink,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 12,
                        color: item.isApproved
                            ? AppColors.moss600
                            : AppColors.tagGoldText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.size,
    required this.fontSize,
  });

  final String initials;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.moss100,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppText.sans(
          size: fontSize,
          color: AppColors.moss600,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // Placeholder: adding investors isn't built yet, so it is inert.
    return CustomPaint(
      painter: const _DashedBorderPainter(color: AppColors.moss600, radius: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            svgIcon('st_plus_green.svg', size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  size: 14,
                  color: AppColors.moss600,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.5),
      );
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _CalculatorCard extends StatelessWidget {
  const _CalculatorCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.tagGoldFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: svgIcon('st_calc.svg', size: 20)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StartupStrings.calculatorTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 15,
                    color: AppColors.ink,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  StartupStrings.calculatorSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          svgIcon('st_chev18.svg', size: 18),
        ],
      ),
    );
  }
}

class _DeleteRow extends StatelessWidget {
  const _DeleteRow({required this.isDeleting, required this.onTap});

  final bool isDeleting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDeleting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              else
                svgIcon('st_trash.svg', size: 18),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  StartupStrings.deleteButton,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 14,
                    color: AppColors.error,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
