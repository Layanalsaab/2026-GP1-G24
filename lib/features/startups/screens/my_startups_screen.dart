import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/common_widgets/error_retry_view.dart';
import '../../../shared_ui/common_widgets/plain_top_bar.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/my_startups_view_model.dart';
import '../widgets/my_startup_card.dart';
import '../widgets/startup_form_page.dart';
import '../widgets/startup_toast.dart';
import 'add_startup_screen.dart';
import 'edit_startup_screen.dart';
import 'manage_startup_screen.dart';

/// Figma "V2 · 44 · My Startups — Empty" and "V2 · 44b · My Startups — List",
/// opened from the Services tab and the side menu.
/// The founder's startups, most recently edited first, with an "Add" action,
/// pull to refresh, and a Manage page per startup.
class MyStartupsScreen extends StatelessWidget {
  const MyStartupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyStartupsViewModel()..load(),
      child: const _MyStartupsView(),
    );
  }
}

class _MyStartupsView extends StatelessWidget {
  const _MyStartupsView();

  /// Reloads; if that fails while a list is already shown, says so in a
  /// snackbar with Retry (the full-page error is only for an empty list).
  Future<void> _refresh(BuildContext context) async {
    final vm = context.read<MyStartupsViewModel>();
    await vm.load();
    if (!context.mounted || vm.error == null || vm.startups.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(vm.error!),
          action: SnackBarAction(
            label: StartupStrings.retry,
            onPressed: () => _refresh(context),
          ),
        ),
      );
  }

  Future<void> _add(BuildContext context) async {
    final result = await AddStartupScreen.open(context);
    if (context.mounted) _afterForm(context, result);
  }

  Future<void> _manage(BuildContext context, Startup startup) async {
    final result = await ManageStartupScreen.open(context, startup);
    if (!context.mounted) return;
    if (result == null) {
      // Edited, or just looked at: pick up any changes.
      _refresh(context);
      return;
    }
    _afterForm(context, result);
  }

  Future<void> _edit(BuildContext context, Startup startup) async {
    final result = await EditStartupScreen.open(context, startup);
    if (context.mounted) _afterForm(context, result);
  }

  void _afterForm(BuildContext context, StartupFormResult? result) {
    if (result == null) return;
    final vm = context.read<MyStartupsViewModel>();
    final message = switch (result.outcome) {
      StartupFormOutcome.created => StartupStrings.added(result.startup.name),
      StartupFormOutcome.saved => StartupStrings.saved,
      StartupFormOutcome.deleted => StartupStrings.deleted(result.startup.name),
    };
    if (result.outcome == StartupFormOutcome.deleted) {
      vm.removeLocally(result.startup.id);
    }
    showStartupToast(context, message);
    _refresh(context);
  }

  Future<void> _showMore(BuildContext context, Startup startup) async {
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
              leading: svgIcon('st_chev16.svg', size: 16),
              title: const Text(StartupStrings.manage),
              onTap: () => Navigator.of(sheetContext).pop('manage'),
            ),
            ListTile(
              leading: svgIcon('st_pencil.svg', size: 18, color: AppColors.ink),
              title: const Text(StartupStrings.editStartup),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'manage':
        await _manage(context, startup);
      case 'edit':
        await _edit(context, startup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyStartupsViewModel>();
    final hasList = !vm.isLoading && vm.startups.isNotEmpty;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            PlainTopBar(
              title: StartupStrings.myStartupsTitle,
              leading: PlainTopBarIcon.back(context),
              showDivider: !hasList,
              trailing: [
                if (hasList) ...[
                  _AddPill(onTap: () => _add(context)),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
            Expanded(child: _body(context, vm)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MyStartupsViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.moss600),
      );
    }
    if (vm.error != null && vm.startups.isEmpty) {
      return _FillRefreshable(
        onRefresh: () => _refresh(context),
        child: ErrorRetryView(
          title: StartupStrings.loadFailed,
          message: vm.error!,
          retryLabel: StartupStrings.retry,
          onRetry: () => _refresh(context),
        ),
      );
    }
    if (vm.isEmpty) {
      // No startups at all (e.g. a new founder, or the last one was
      // deleted): invite them to create their first one.
      return _FillRefreshable(
        onRefresh: () => _refresh(context),
        child: _EmptyState(onAdd: () => _add(context)),
      );
    }

    final startups = vm.startups;
    return RefreshIndicator(
      color: AppColors.moss600,
      onRefresh: () => _refresh(context),
      child: ListView(
        // Always scrollable, so pull-to-refresh works with one card too.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            StartupStrings.startupCount(startups.length),
            style: AppText.sans(
              size: 13,
              color: AppColors.grey,
              weight: FontWeight.w500,
            ),
          ),
          for (final startup in startups) ...[
            const SizedBox(height: AppSpacing.md),
            MyStartupCard(
              startup: startup,
              onTap: () => _manage(context, startup),
              onMore: () => _showMore(context, startup),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "+ Add" pill in the header (Figma "Add").
class _AddPill extends StatelessWidget {
  const _AddPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.moss600,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 10,
            right: 12,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              svgIcon('st_plus_white.svg', size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                StartupStrings.addAction,
                style: AppText.sans(
                  size: 14,
                  color: AppColors.onDark,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Makes a non-list state (empty, error) fill the space and still support
/// pull-to-refresh.
class _FillRefreshable extends StatelessWidget {
  const _FillRefreshable({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.moss600,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

/// Figma "V2 · 44": rocket illustration, title and "Add startup".
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Figma leaves 60 px under the content, so it sits a little high.
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.moss100,
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 24,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F1A331A),
                          offset: Offset(0, 8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(child: svgIcon('st_rocket.svg', size: 44)),
                  ),
                ),
                Positioned(
                  left: 92,
                  top: 88,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cream, width: 3),
                    ),
                    child: Center(child: svgIcon('st_plus_gold.svg', size: 18)),
                  ),
                ),
                Positioned(
                  left: 4,
                  top: 10,
                  child: svgIcon('st_spark.svg', size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            StartupStrings.emptyTitle,
            textAlign: TextAlign.center,
            style: AppText.sans(
              size: 22,
              color: AppColors.ink,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.moss600,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: onAdd,
              child: SizedBox(
                width: 200,
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    svgIcon('st_plus_white.svg', size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        StartupStrings.emptyButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.button,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
