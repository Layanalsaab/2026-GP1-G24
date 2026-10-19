import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/startup.dart';
import '../view_models/my_startups_view_model.dart';
import '../widgets/founder_ui.dart';
import '../widgets/my_startup_card.dart';
import 'manage_startup_screen.dart';
import 'startup_steps_screen.dart';

/// My Startups (docs/05 D1): green header with an "Add" pill and the count,
/// an overlapping list of startup cards, or the illustrated empty card.
class MyStartupsScreen extends StatefulWidget {
  const MyStartupsScreen({super.key});

  /// Opens the screen with the forward transition.
  static void open(BuildContext context) =>
      AppNav.push(context, const MyStartupsScreen(), greenHeader: true);

  @override
  State<MyStartupsScreen> createState() => _MyStartupsScreenState();
}

class _MyStartupsScreenState extends State<MyStartupsScreen> {
  late final MyStartupsViewModel _vm = MyStartupsViewModel();

  @override
  void initState() {
    super.initState();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _add() => StartupStepsScreen.openAdd(context);

  Future<void> _manage(Startup s) async {
    await ManageStartupScreen.push(context, s);
    if (mounted) _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final hasList = _vm.startups.isNotEmpty;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  title: FounderToolsStrings.myStartupsTitle,
                  overlap: OverlapList.overlap,
                  onBack: () => AppNav.back(context),
                  trailing: hasList ? GoldPillButton.add(onTap: _add) : null,
                  subtitle: hasList
                      ? FounderToolsStrings.startupCount(_vm.startups.length)
                      : null,
                ),
                if (_vm.isEmpty)
                  OverlapList(
                    children: [
                      IllustratedEmptyCard(
                        illustration: const _EmptyIllustration(),
                        title: FounderToolsStrings.emptyTitle,
                        message: FounderToolsStrings.emptyMessage,
                        actionLabel: FounderToolsStrings.emptyButton,
                        onAction: _add,
                      ),
                    ],
                  )
                else if (_vm.error != null && !hasList)
                  OverlapList(
                    children: [
                      EmptyState(
                        title: FounderToolsStrings.loadFailed,
                        message: '',
                        actionLabel: FounderToolsStrings.retry,
                        onAction: _vm.load,
                      ),
                    ],
                  )
                else if (_vm.isLoading && !hasList)
                  const Padding(
                    padding: EdgeInsets.only(top: 56),
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
                else
                  OverlapList(
                    animate: false,
                    children: [
                      for (var i = 0; i < _vm.startups.length; i++)
                        Rise.card(
                          delay: Motion.stagger(context, i, stepMs: 50),
                          child: MyStartupCard(
                            startup: _vm.startups[i],
                            onTap: () => _manage(_vm.startups[i]),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
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
