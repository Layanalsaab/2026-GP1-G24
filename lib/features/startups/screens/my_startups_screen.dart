import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/startup_draft_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/list_entries.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/widgets/headers/list_screen_header.dart';
import '../../../shared_ui/widgets/lists/filter_sort_pills.dart';
import '../view_models/my_startups_view_model.dart';
import '../widgets/startup_filter_sheet.dart';
import '../widgets/draft_card.dart';
import '../widgets/founder_ui.dart';
import '../widgets/my_startup_card.dart';
import 'manage_startup_screen.dart';
import 'startup_steps_screen.dart';

/// My Startups (docs/05 D1): the shared list banner (back, "Add" pill, title
/// and logo, filter + sort pills; no count line) and the cards of the
/// founder's startups plus the ones they joined as a team member, or the
/// illustrated empty card.
class MyStartupsScreen extends StatefulWidget {
  const MyStartupsScreen({super.key, this.teamStartups});

  /// The startups the user joined as a team member. Null = the mockup list
  /// in `PrototypeSeed.sampleTeamStartups`; the backend passes the real ones.
  final List<MyStartupEntry>? teamStartups;

  /// Opens the screen with the forward transition.
  static void open(BuildContext context) =>
      AppNav.push(context, const MyStartupsScreen(), greenHeader: true);

  @override
  State<MyStartupsScreen> createState() => _MyStartupsScreenState();
}

class _MyStartupsScreenState extends State<MyStartupsScreen> {
  late final MyStartupsViewModel _vm = MyStartupsViewModel(
    teamStartups: widget.teamStartups,
  );

  final _drafts = StartupDraftRepository.instance;

  @override
  void initState() {
    super.initState();
    _vm.load();
    final uid = AppSession.instance.user?.uid;
    if (uid != null) _drafts.load(uid);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _add() => StartupStepsScreen.openAdd(context);

  void _continueDraft(Map<String, Object?> d) =>
      StartupStepsScreen.openAdd(context, draft: d);

  Future<void> _discardDraft() async {
    final ok = await showConfirmSheet(
      context,
      title: FounderToolsStrings.discardDraftTitle,
      message: FounderToolsStrings.discardDraftMessage,
      confirmLabel: FounderToolsStrings.discard,
      cancelLabel: FounderToolsStrings.keepEditing,
    );
    final uid = AppSession.instance.user?.uid;
    if (!ok || uid == null) return;
    await _drafts.clear(uid);
    if (mounted) AppToast.show(context, FounderToolsStrings.draftDiscarded);
  }

  Future<void> _manage(Startup s, StartupRole role) async {
    await ManageStartupScreen.push(
      context,
      s,
      role: role,
      onLeave: () => unawaited(_vm.leave(s.id)),
    );
    if (mounted) _vm.load();
  }

  Future<void> _pickSort() async {
    final r = await showPickerSheet(
      context,
      title: FounderToolsStrings.sortStartupsTitle,
      options: [for (final s in StartupSort.values) s.label],
      selected: _vm.sort.label,
    );
    if (r == null) return;
    _vm.setSort(StartupSort.values.firstWhere((s) => s.label == r.value));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _drafts.current]),
      builder: (context, _) {
        final hasList = _vm.entries.isNotEmpty;
        final draft = _drafts.current.value;
        final draftCard = draft == null
            ? null
            : DraftCard(
                draft: draft,
                onTap: () => _continueDraft(draft),
                onDiscard: _discardDraft,
              );
        final shown = _vm.visible;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListScreenHeader(
                  title: FounderToolsStrings.myStartupsTitle,
                  onBack: () => AppNav.back(context),
                  topTrailing: hasList || draft != null
                      ? GoldPillButton.add(onTap: _add)
                      : null,
                  pills: hasList
                      ? FilterSortPills(
                          filterLabel: _vm.filterLabel,
                          filterActive: _vm.filtered,
                          sortLabel: _vm.sort.label,
                          onFilter: () => showStartupFilterSheet(context, _vm),
                          onSort: _pickSort,
                        )
                      : null,
                ),
                // The list starts right under the banner, at the same y as
                // the Bookmarks list.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_vm.isEmpty) ...[
                        if (draftCard != null) ...[
                          draftCard,
                          const SizedBox(height: 14),
                        ],
                        IllustratedEmptyCard(
                          illustration: const _EmptyIllustration(),
                          title: FounderToolsStrings.emptyTitle,
                          message: FounderToolsStrings.emptyMessage,
                          actionLabel: FounderToolsStrings.emptyButton,
                          onAction: _add,
                        ),
                      ] else if (_vm.error != null && !hasList)
                        EmptyState(
                          title: FounderToolsStrings.loadFailed,
                          message: '',
                          actionLabel: FounderToolsStrings.retry,
                          onAction: _vm.load,
                        )
                      else if (_vm.isLoading && !hasList)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.moss600,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        if (draftCard != null) ...[
                          draftCard,
                          const SizedBox(height: 14),
                        ],
                        if (shown.isEmpty)
                          _NoMatches(onShowAll: _vm.resetFilters)
                        else
                          for (var i = 0; i < shown.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            Rise.card(
                              key: ObjectKey(shown[i]),
                              delay: Motion.stagger(context, i, stepMs: 50),
                              child: MyStartupCard(
                                startup: shown[i].startup,
                                role: shown[i].role,
                                // Founder, co-founder and team member all open
                                // Manage (a team member's is view-only).
                                onTap: () =>
                                    _manage(shown[i].startup, shown[i].role),
                              ),
                            ),
                          ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Filters with no results: a small card with "Show all startups".
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F2314),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            FounderToolsStrings.noMatchTitle,
            textAlign: TextAlign.center,
            style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: FounderToolsStrings.showAllStartups,
            variant: AppButtonVariant.ghost,
            expanded: false,
            onPressed: onShowAll,
          ),
        ],
      ),
    );
  }
}

/// The empty-state picture: a 140 circle with a floating white rocket tile,
/// a gold plus badge and a twinkling sparkle.
class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          stops: [0.55, 0.56],
          colors: [Color(0xFFE6EFE7), Color(0xFFF2F7F3)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 8,
            top: 18,
            child: Twinkle(
              child: AppIcon.filled(
                AppIcons.twinkle,
                size: 16,
                color: AppColors.gold,
              ),
            ),
          ),
          Float(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x401F3F27),
                    offset: Offset(0, 14),
                    blurRadius: 28,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: const Center(
                child: AppIcon.filled(
                  AppIcons.rocket,
                  size: 36,
                  color: AppColors.moss600,
                ),
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 26,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold,
                boxShadow: [BoxShadow(color: AppColors.white, spreadRadius: 3)],
              ),
              child: const Center(
                child: AppIcon.filled(
                  AppIcons.plus,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
