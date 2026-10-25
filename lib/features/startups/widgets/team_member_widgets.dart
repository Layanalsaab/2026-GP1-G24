import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/team_member.dart';
import '../../../shared_ui/widgets/forms/checkbox_card.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import 'founder_ui.dart';
import 'role_tag.dart';

/// One saved team member in the Startup Team step: a white card (1 px border,
/// radius 14, padding 12, items at the top, 10 px gap) with the initials tile,
/// the name followed by the tag capsules, the role, the contribution and the
/// pencil button that opens the editor in this card's place.
class TeamMemberRow extends StatelessWidget {
  const TeamMemberRow({
    super.key,
    required this.member,
    required this.onEdit,
    this.isYou = false,
    this.error,
  });

  final TeamMember member;
  final VoidCallback onEdit;
  final bool isYou;

  /// A red line under the card (the founder's missing role / contribution).
  final String? error;

  @override
  Widget build(BuildContext context) {
    final role = member.role.trim();
    final contribution = member.contribution.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error == null ? AppColors.border : AppColors.error,
            ),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          member.name,
                          style: AppText.sans(
                            size: 15,
                            height: 20,
                            weight: FontWeight.w600,
                          ),
                        ),
                        ...teamTagsOf(member, isYou: isYou),
                      ],
                    ),
                    if (role.isNotEmpty || member.isFounder) ...[
                      const SizedBox(height: 2),
                      Text(
                        role.isNotEmpty
                            ? role
                            : FounderToolsStrings.addYourRole,
                        style: AppText.sans(size: 12, color: AppColors.grey),
                      ),
                    ],
                    if (contribution.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contribution,
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
                icon: AppIcons.edit,
                iconSize: 18,
                size: 36,
                color: AppColors.moss600,
                semanticLabel: FounderToolsStrings.editMemberOf(member.name),
                onTap: onEdit,
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
            child: Text(error!, style: AppText.error),
          ),
      ],
    );
  }
}

/// The dashed "Add team member" button: full width, 48 high, radius 12, 1.5 px
/// dashed moss 600 border, transparent, "+" and the text in moss 600.
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: CustomPaint(
          painter: DashedBorderPainter(color: AppColors.moss600, radius: 12),
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

/// A locked field (my own name / e-mail, or the founder's): muted fill, no
/// border, grey text and a 16 px lock on the right; no counter, no hint.
class _LockedValue extends StatelessWidget {
  const _LockedValue(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      readOnly: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.mutedFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(size: 16, color: AppColors.paragraph),
              ),
            ),
            const SizedBox(width: 8),
            const AppIcon.filled(
              AppIcons.lock,
              size: 16,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the editor's two buttons: 44 high, radius 12, 14 px semibold.
/// [outlined] = Cancel (white, 1.5 px moss border); otherwise the green
/// primary, which is grey while [off].
class _EditorButton extends StatelessWidget {
  const _EditorButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.off = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final bool off;

  @override
  Widget build(BuildContext context) {
    final fill = outlined
        ? AppColors.white
        : off
        ? AppColors.offFill
        : AppColors.moss600;
    final text = outlined
        ? AppColors.moss600
        : off
        ? AppColors.offText
        : AppColors.white;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.button,
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: outlined
                ? Border.all(color: AppColors.moss600, width: 1.5)
                : null,
          ),
          child: Text(
            label,
            style: AppText.sans(size: 14, weight: FontWeight.w600, color: text),
          ),
        ),
      ),
    );
  }
}

/// The inline editor card: moss 50, 1 px moss 100 border, radius 16, padding
/// 14. It REPLACES the card being edited (or sits above the Add button for a
/// new member) and rises in over 320 ms.
///
/// [lockedIdentity]: my own card and the founder's: the name and e-mail are
/// locked, there is no Co-founder box and no "Remove this member".
class TeamMemberEditor extends StatelessWidget {
  const TeamMemberEditor({
    super.key,
    required this.title,
    required this.editing,
    required this.lockedIdentity,
    required this.name,
    required this.email,
    required this.role,
    required this.contribution,
    required this.coFounder,
    required this.onCoFounder,
    required this.complete,
    required this.errorOf,
    required this.onCancel,
    required this.onSave,
    required this.onRemove,
  });

  /// "Your details" / "Edit team member" / "New team member" / "Edit founder".
  final String title;

  /// True when editing an existing member (the button reads "Save").
  final bool editing;
  final bool lockedIdentity;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController role;
  final TextEditingController contribution;
  final bool coFounder;
  final ValueChanged<bool> onCoFounder;

  /// Every field is valid (the right button turns from grey to green).
  final bool complete;

  /// The message under a field (empty ones after a save attempt).
  final String? Function(TextEditingController) errorOf;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onRemove;

  Widget _field(
    String label,
    TextEditingController c,
    String hint,
    int max, {
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.none,
  }) => LabeledTextField(
    label: label,
    required: true,
    sentenceCase: true,
    controller: c,
    placeholder: hint,
    maxLength: max,
    error: errorOf(c),
    keyboardType: keyboard,
    textCapitalization: caps,
  );

  Widget _locked(String label, TextEditingController c) => AppField(
    label: label,
    required: true,
    sentenceCase: true,
    child: ListenableBuilder(
      listenable: c,
      builder: (context, _) => _LockedValue(c.text),
    ),
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
    const gap = FieldHelperRow.gapAfter;
    return Container(
      padding: const EdgeInsets.all(14),
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
              title,
              style: AppText.sans(
                size: 15,
                weight: FontWeight.w700,
                color: AppColors.green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (lockedIdentity)
            _locked(FounderToolsStrings.memberName, name)
          else
            _field(
              FounderToolsStrings.memberName,
              name,
              FounderToolsStrings.memberNameHint,
              TeamMember.nameMax,
              caps: TextCapitalization.words,
            ),
          const SizedBox(height: gap),
          if (lockedIdentity)
            _locked(FounderToolsStrings.memberEmail, email)
          else
            _field(
              FounderToolsStrings.memberEmail,
              email,
              FounderToolsStrings.memberEmailHint,
              TeamMember.emailMax,
              keyboard: TextInputType.emailAddress,
            ),
          const SizedBox(height: gap),
          _field(
            FounderToolsStrings.memberRole,
            role,
            FounderToolsStrings.memberRoleHint,
            TeamMember.roleMax,
          ),
          const SizedBox(height: gap),
          LabeledTextField(
            label: FounderToolsStrings.memberContribution,
            required: true,
            sentenceCase: true,
            controller: contribution,
            placeholder: FounderToolsStrings.memberContributionHint,
            maxLength: TeamMember.contributionMax,
            multiline: true,
            rows: 3,
            info: FounderToolsStrings.memberContributionInfo,
            error: errorOf(contribution),
          ),
          if (!lockedIdentity) ...[
            const SizedBox(height: gap),
            CheckboxCard(
              compact: true,
              title: FounderToolsStrings.coFounderTitle,
              description: FounderToolsStrings.coFounderText,
              checked: coFounder,
              onChanged: onCoFounder,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _EditorButton(
                  label: FounderToolsStrings.cancel,
                  outlined: true,
                  onTap: onCancel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EditorButton(
                  label: editing
                      ? FounderToolsStrings.saveMemberButton
                      : FounderToolsStrings.addMemberButton,
                  off: !complete,
                  onTap: onSave,
                ),
              ),
            ],
          ),
          if (editing && !lockedIdentity) ...[
            const SizedBox(height: 12),
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

/// "This person isn't on Start.sa yet": a centred white card like the Verify
/// email dialog, with a popping paper-plane in a 64 px green circle, the
/// title, the explanation with the bold e-mail, a green "Send invite" button
/// and a ghost "Cancel". Completes with true only for "Send invite".
Future<bool> showInviteDialog(BuildContext context, String email) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final base = AppText.sans(size: 15, color: AppColors.grey, height: 22);
  final result = await showAppDialog<bool>(
    context,
    builder: (ctx) => AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Pop(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.moss100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const AppIcon.filled(
                  AppIcons.send,
                  size: 28,
                  color: AppColors.moss600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              FounderToolsStrings.inviteTitle,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 21, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: base,
              children: [
                const TextSpan(text: 'We’ll email '),
                TextSpan(
                  text: email,
                  style: base.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' an invitation to join and see this startup. Do you want to continue?',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          AppButton(
            label: FounderToolsStrings.sendInvite,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: FounderToolsStrings.cancel,
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
