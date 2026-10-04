import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/program_strings.dart';
import '../../../models/program.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Figma "V2 · 27 · Program Profile — All". Design phase: the website button
/// is for show and does nothing yet.
class ProgramProfileScreen extends StatelessWidget {
  const ProgramProfileScreen({super.key, required this.program});

  final Program program;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            const GreenTopBar(
              title: ProgramStrings.programTitle,
              leading: TopBarBackButton(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  _header(),
                  const SizedBox(height: AppSpacing.lg),
                  _stats(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(ProgramStrings.about, style: _heading),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    program.about,
                    style: AppText.sans(
                      size: 16,
                      color: AppColors.grey,
                      height: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(ProgramStrings.focusSectors, style: _heading),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final sector in program.focusSectors)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.moss100,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            sector,
                            style: AppText.sans(
                              size: 12,
                              color: AppColors.moss600,
                              weight: FontWeight.w500,
                              height: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Design only: opening the website isn't connected yet. The empty
                  // handler keeps the button looking active (null would grey it).
                  PrimaryButton(
                    label: ProgramStrings.visitWebsite,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _heading => AppText.sans(
        size: 16,
        color: AppColors.ink,
        weight: FontWeight.w600,
        height: 24,
      );

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.moss100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            program.initial,
            style: AppText.serif(size: 22, color: AppColors.moss600, height: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                program.name,
                style: AppText.serif(size: 22, color: AppColors.ink, height: 28),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${program.type.label} · ${program.city}',
                style: AppText.bodyMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stats() {
    Widget stat(String value, String label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(
                  value,
                  style: AppText.sans(
                    size: 16,
                    color: AppColors.ink,
                    weight: FontWeight.w600,
                    height: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(label, style: AppText.caption),
              ],
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          stat(program.type.label, ProgramStrings.type),
          stat(program.duration, ProgramStrings.duration),
          stat('${program.sinceYear}', ProgramStrings.since),
        ],
      ),
    );
  }
}
