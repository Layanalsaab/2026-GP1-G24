import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/team_member.dart';
import 'founder_ui.dart';

/// One saved team member in step 3 (prototype `.tmem`): moss tile 40, name,
/// "CTO · 10 yrs · Mobile and cloud", bio, and a pencil button that opens the
/// editor. White card, radius 14, soft border.
class TeamMemberRow extends StatelessWidget {
  const TeamMemberRow({super.key, required this.member, required this.onEdit});

  final TeamMember member;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TileAvatar(
            initials: member.initials,
            size: 40,
            radius: 12,
            fontSize: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppText.sans(size: 15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 1),
                Text(
                  member.meta,
                  style: AppText.sans(size: 12, color: AppColors.grey),
                ),
                if (member.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    member.bio,
                    style: AppText.sans(
                      size: 13,
                      height: 18,
                      color: AppColors.paragraph,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppIconButton(
            icon: AppIcons.pencil,
            stroke: 1.8,
            iconSize: 20,
            size: 36,
            color: AppColors.moss600,
            semanticLabel: FounderToolsStrings.editMemberLabel,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

/// The dashed "Add team member" button (48 high, 1.5 dashed moss600).
class AddMemberButton extends StatelessWidget {
  const AddMemberButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FounderToolsStrings.addMember,
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.button,
        hoverColor: AppColors.moss50,
        hoverDuration: AppDur.fast,
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: CustomPaint(
          painter: DashedBorderPainter(color: AppColors.moss600, radius: 14),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIcon.filled(
                  AppIcons.plus,
                  size: 20,
                  color: AppColors.moss600,
                ),
                const SizedBox(width: 6),
                Text(
                  FounderToolsStrings.addMember,
                  style: AppText.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.moss600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The inline editor card (moss50, radius 16): title, five required inputs,
/// Cancel + "Add member" / "Save member", and "Remove this member" when
/// editing. Fed by the view model's controllers.
class TeamMemberEditor extends StatelessWidget {
  const TeamMemberEditor({
    super.key,
    required this.editing,
    required this.name,
    required this.role,
    required this.specialization,
    required this.years,
    required this.bio,
    required this.complete,
    required this.errorOf,
    required this.onCancel,
    required this.onSave,
    required this.onRemove,
  });

  /// True when editing an existing member (changes title and buttons).
  final bool editing;
  final TextEditingController name;
  final TextEditingController role;
  final TextEditingController specialization;
  final TextEditingController years;
  final TextEditingController bio;

  /// All five fields filled (the save button turns from grey to green).
  final bool complete;

  /// "Required" for an empty field after a save attempt.
  final String? Function(TextEditingController) errorOf;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onRemove;

  Widget _field(
    String label,
    TextEditingController c,
    String hint,
    int max, {
    bool multiline = false,
    bool digits = false,
  }) => LabeledTextField(
    label: label,
    required: true,
    controller: c,
    placeholder: hint,
    maxLength: max,
    multiline: multiline,
    showCounter: multiline,
    error: errorOf(c),
    keyboardType: digits ? TextInputType.number : null,
    inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
  );

  @override
  Widget build(BuildContext context) {
    // The editor card rises in (320 ms) when it opens.
    return Rise(
      duration: const Duration(milliseconds: 320),
      child: _card(context),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.moss50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.moss100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              editing
                  ? FounderToolsStrings.editMember
                  : FounderToolsStrings.newMember,
              style: AppText.sans(
                size: 16,
                weight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _field(
            FounderToolsStrings.memberName,
            name,
            FounderToolsStrings.memberNameHint,
            TeamMember.nameMax,
          ),
          const SizedBox(height: 16),
          _field(
            FounderToolsStrings.memberRole,
            role,
            FounderToolsStrings.memberRoleHint,
            TeamMember.roleMax,
          ),
          const SizedBox(height: 16),
          _field(
            FounderToolsStrings.memberSpec,
            specialization,
            FounderToolsStrings.memberSpecHint,
            TeamMember.specializationMax,
          ),
          const SizedBox(height: 16),
          _field(
            FounderToolsStrings.memberYears,
            years,
            FounderToolsStrings.memberYearsHint,
            TeamMember.yearsMaxDigits,
            digits: true,
          ),
          const SizedBox(height: 16),
          _field(
            FounderToolsStrings.memberBio,
            bio,
            FounderToolsStrings.memberBioHint,
            TeamMember.bioMax,
            multiline: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: FounderToolsStrings.cancel,
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: editing
                      ? FounderToolsStrings.saveMemberButton
                      : FounderToolsStrings.addMemberButton,
                  variant: complete
                      ? AppButtonVariant.primary
                      : AppButtonVariant.off,
                  size: AppButtonSize.small,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
          if (editing) ...[
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: FounderToolsStrings.removeMember,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      FounderToolsStrings.removeMember,
                      style: AppText.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
