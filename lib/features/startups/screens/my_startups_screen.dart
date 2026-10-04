import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/startup.dart';
import '../../../navigation/placeholder_features.dart';
import '../../../shared_ui/common_widgets/error_retry_view.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/my_startups_view_model.dart';
import '../widgets/my_startup_card.dart';
import '../widgets/startup_form_page.dart';
import 'add_startup_screen.dart';
import 'edit_startup_screen.dart';

/// The founder's startups, most recently edited first. Pull to refresh,
/// FAB to add, tap a card to edit. Used as a tab of the founder home.
class MyStartupsScreen extends StatelessWidget {
  const MyStartupsScreen({super.key, required this.onOpenMenu});

  /// Opens the founder home's side menu.
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyStartupsViewModel()..load(),
      child: _MyStartupsView(onOpenMenu: onOpenMenu),
    );
  }
}

class _MyStartupsView extends StatelessWidget {
  const _MyStartupsView({required this.onOpenMenu});

  final VoidCallback onOpenMenu;

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

  Future<void> _edit(BuildContext context, Startup startup) async {
    final result = await EditStartupScreen.open(context, startup);
    if (context.mounted) _afterForm(context, result);
  }

  void _afterForm(BuildContext context, StartupFormResult? result) {
    if (result == null) return;
    final vm = context.read<MyStartupsViewModel>();
    final message = switch (result.outcome) {
      StartupFormOutcome.created => StartupStrings.created,
      StartupFormOutcome.saved => StartupStrings.saved,
      StartupFormOutcome.deleted => StartupStrings.deleted(result.startup.name),
    };
    if (result.outcome == StartupFormOutcome.deleted) {
      vm.removeLocally(result.startup.id);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    _refresh(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyStartupsViewModel>();
    final showFab = !vm.isLoading && !(vm.error != null && vm.startups.isEmpty);
    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => _add(context),
              backgroundColor: AppColors.moss600,
              foregroundColor: AppColors.onDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(StartupStrings.addStartupFab, style: AppText.button),
            )
          : null,
      body: Column(
        children: [
          GreenTopBar(
            title: StartupStrings.myStartupsTitle,
            leading: TopBarIconButton(
              icon: Icons.menu_rounded,
              tooltip: StartupStrings.menuTooltip,
              onPressed: onOpenMenu,
            ),
            actions: [
              TopBarIconButton(
                icon: Icons.search_rounded,
                tooltip: StartupStrings.searchTooltip,
                onPressed: () => PlaceholderFeature.search.open(context),
              ),
              TopBarIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: StartupStrings.notificationsTooltip,
                onPressed: () => PlaceholderFeature.notifications.open(context),
              ),
            ],
            below: _HeaderSummary(
              count: vm.isLoading ? null : vm.startups.length,
            ),
          ),
          Expanded(child: _body(context, vm)),
        ],
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
      return _FillRefreshable(
        onRefresh: () => _refresh(context),
        child: _EmptyState(onAdd: () => _add(context)),
      );
    }
    return RefreshIndicator(
      color: AppColors.moss600,
      onRefresh: () => _refresh(context),
      child: ListView.separated(
        // Always scrollable, so pull-to-refresh works with one card too.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          // Leave room so the FAB never covers the last card.
          AppSpacing.huge * 2,
        ),
        itemCount: vm.startups.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final startup = vm.startups[index];
          return MyStartupCard(
            startup: startup,
            onTap: () => _edit(context, startup),
          );
        },
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({required this.count});

  /// Null while loading.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            StartupStrings.myStartupsSubtitle,
            style: AppText.bodyMuted.copyWith(color: AppColors.onDarkMuted),
          ),
        ),
        if (count != null && count! > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + AppSpacing.xxs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              StartupStrings.startupCount(count!),
              style: AppText.badge.copyWith(color: AppColors.green),
            ),
          ),
      ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.gold100,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: AppSizes.emptyStateIcon,
              height: AppSizes.emptyStateIcon,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: const Icon(
                Icons.rocket_launch_outlined,
                size: AppSizes.iconLg,
                color: AppColors.moss600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            StartupStrings.emptyTitle,
            style: AppText.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            StartupStrings.emptyBody,
            style: AppText.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: StartupStrings.emptyButton,
            icon: Icons.add_rounded,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
