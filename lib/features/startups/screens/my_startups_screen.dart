import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/common_widgets/error_retry_view.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/common_widgets/selection_chip.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/my_startups_view_model.dart';
import '../widgets/my_startup_card.dart';
import '../widgets/startup_form_page.dart';
import 'add_startup_screen.dart';
import 'edit_startup_screen.dart';

/// Figma "V2 · 24 · My Startups", opened from the Services tab.
/// The founder's startups, most recently edited first, with All / Public /
/// Private chips, pull to refresh, and "Create new startup" under the list.
/// Tapping a card opens Edit.
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const GreenTopBar(
              title: StartupStrings.myStartupsTitle,
              leading: TopBarBackButton(),
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

    final visible = vm.visibleStartups;
    return RefreshIndicator(
      color: AppColors.moss600,
      onRefresh: () => _refresh(context),
      child: ListView(
        // Always scrollable, so pull-to-refresh works with one card too.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _FilterChips(current: vm.filter, onSelect: vm.setFilter),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                vm.filter == StartupFilter.public
                    ? StartupStrings.noPublic
                    : StartupStrings.noPrivate,
                style: AppText.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ),
          for (final startup in visible) ...[
            MyStartupCard(
              startup: startup,
              onTap: () => _edit(context, startup),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.xs),
          PrimaryButton(
            label: StartupStrings.createNewStartup,
            icon: Icons.add_rounded,
            onPressed: () => _add(context),
          ),
        ],
      ),
    );
  }
}

/// All / Public / Private, single choice (Figma "V2 · 24").
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onSelect});

  final StartupFilter current;
  final ValueChanged<StartupFilter> onSelect;

  static String _label(StartupFilter filter) => switch (filter) {
    StartupFilter.all => StartupStrings.filterAll,
    StartupFilter.public => StartupStrings.publicBadge,
    StartupFilter.private => StartupStrings.privateBadge,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final filter in StartupFilter.values)
          SelectionChip(
            label: _label(filter),
            selected: filter == current,
            onTap: () => onSelect(filter),
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
            width: AppSizes.emptyStateIcon,
            height: AppSizes.emptyStateIcon,
            decoration: BoxDecoration(
              color: AppColors.moss100,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.business_center_outlined,
              size: AppSizes.iconLg,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
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
