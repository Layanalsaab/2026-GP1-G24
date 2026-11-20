import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';

Future<Map<String, StartupFate>?> showStartupFatesSheet(
  BuildContext context, {
  required List<Startup> owned,
  int joinedCount = 0,
}) => showAppBottomSheet<Map<String, StartupFate>>(
  context,
  builder: (_) => StartupFatesSheet(owned: owned, joinedCount: joinedCount),
);

class StartupFatesSheet extends StatefulWidget {
  const StartupFatesSheet({
    super.key,
    required this.owned,
    this.joinedCount = 0,
  });

  final List<Startup> owned;
  final int joinedCount;

  @override
  State<StartupFatesSheet> createState() => _StartupFatesSheetState();
}

class _StartupFatesSheetState extends State<StartupFatesSheet> {
  /// Startup id -> true (delete) / false (close); missing = not chosen yet.
  final Map<String, bool> _delete = {};

  /// Startup id -> the next founder (startups with a team).
  late final Map<String, String> _next = {
    for (final s in widget.owned) s.id: ?defaultNextFounder(s),
  };

  /// Continue was tapped with something missing: the missing ones are red.
  bool _tried = false;

  int get _chosen =>
      widget.owned.where((s) => _delete.containsKey(s.id)).length;
  int get _total => widget.owned.length;

  void _choose(Startup s, bool delete) =>
      setState(() => _delete[s.id] = delete);

  Future<void> _pickNext(Startup s) async {
    final uids = s.memberRoles.keys.toList();
    final names = [for (final uid in uids) _nameOf(s, uid)];
    final r = await showPickerSheet(
      context,
      title: AccountStrings.nextFounderLabel,
      options: names,
      selected: _next[s.id] == null ? null : _nameOf(s, _next[s.id]!),
    );
    if (r == null || !mounted) return;
    final i = names.indexOf(r.value);
    if (i >= 0) setState(() => _next[s.id] = uids[i]);
  }

  void _continue() {
    if (_chosen < _total) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop({
      for (final s in widget.owned)
        s.id: _delete[s.id] == true
            ? const StartupFate.delete()
            : StartupFate.close(nextFounder: _next[s.id]),
    });
  }

  static String _nameOf(Startup s, String uid) => s.nameOf(
    uid,
    fallback: s.memberRoles[uid] == 'coFounder'
        ? FounderToolsStrings.roleCoFounder
        : FounderToolsStrings.roleMember,
  );

  @override
  Widget build(BuildContext context) {
    final left = _total - _chosen;
    final missing = _tried && left > 0;
    return AppSheetScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Pop(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.errorFill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon.filled(
                    AppIcons.trash,
                    size: 28,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                AccountStrings.fatesTitle,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 21, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AccountStrings.fatesText(widget.joinedCount),
              textAlign: TextAlign.center,
              style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
            ),
            const SizedBox(height: 16),
            _Counter(chosen: _chosen, total: _total, missing: missing),
            const SizedBox(height: 10),
            for (final s in widget.owned) ...[
              _FateCard(
                startup: s,
                delete: _delete[s.id],
                missing: _tried && !_delete.containsKey(s.id),
                nextName: _next[s.id] == null ? null : _nameOf(s, _next[s.id]!),
                onClose: () => _choose(s, false),
                onDelete: () => _choose(s, true),
                onPickNext: () => _pickNext(s),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            AppButton(
              label: AccountStrings.fatesContinue,
              variant: left == 0
                  ? AppButtonVariant.danger
                  : AppButtonVariant.outline,
              onPressed: _continue,
            ),
            const SizedBox(height: 10),
            SheetCancelButton(
              label: ProfileStrings.cancel,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

String? defaultNextFounder(Startup s) {
  final joined = s.memberRoles;
  if (joined.isEmpty) return null;
  String? firstOf(String role) {
    for (final m in s.team) {
      final uid = m.uid;
      if (uid != null && joined[uid] == role) return uid;
    }
    for (final e in joined.entries) {
      if (e.value == role) return e.key;
    }
    return null;
  }

  return firstOf('coFounder') ?? firstOf('member') ?? joined.keys.first;
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.chosen,
    required this.total,
    required this.missing,
  });

  final int chosen;
  final int total;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final left = total - chosen;
    final fill = missing ? AppColors.errorFill : AppColors.noticeFill;
    final line = missing ? AppColors.error : AppColors.noticeBorder;
    final ink = missing ? AppColors.error : AppColors.noticeTitle;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                missing
                    ? AccountStrings.fatesStillToChoose(left)
                    : AccountStrings.fatesChosen(chosen, total),
                style: AppText.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ),
            if (left > 0 && !missing)
              Text(
                AccountStrings.fatesLeft(left),
                style: AppText.sans(
                  size: 14,
                  weight: FontWeight.w600,
                  color: ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FateCard extends StatelessWidget {
  const _FateCard({
    required this.startup,
    required this.delete,
    required this.missing,
    required this.nextName,
    required this.onClose,
    required this.onDelete,
    required this.onPickNext,
  });

  final Startup startup;

  /// true = Delete, false = Close, null = not chosen yet.
  final bool? delete;
  final bool missing;
  final String? nextName;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onPickNext;

  @override
  Widget build(BuildContext context) {
    final s = startup;
    final team = s.memberRoles.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: missing ? AppColors.error : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TileAvatar(
                initials: appInitials(s.name),
                tone: TileTone.gold,
                imageData: s.logoData,
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
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 15,
                        height: 20,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      team == 0
                          ? AccountStrings.fateOnlyYou
                          : AccountStrings.fateWithTeam(team),
                      style: AppText.sans(size: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Choice(
                  label: s.isClosed
                      ? AccountStrings.fateKeepClosed
                      : AccountStrings.fateClose,
                  selected: delete == false,
                  color: AppColors.moss600,
                  onTap: onClose,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Choice(
                  label: AccountStrings.fateDelete,
                  selected: delete == true,
                  color: AppColors.dangerFill,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
          if (missing) ...[
            const SizedBox(height: 8),
            Text(
              AccountStrings.fateMissing,
              style: AppText.sans(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
          if (delete == false && nextName != null) ...[
            const SizedBox(height: 10),
            _NextFounderRow(name: nextName!, onTap: onPickNext),
          ],
        ],
      ),
    );
  }
}

/// Close or Delete: a white 40 px button, filled with color once chosen.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.button,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDur.fast,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : AppColors.border),
          ),
          child: Text(
            label,
            style: AppText.sans(
              size: 14,
              weight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Next founder: Sara Mouhamed ▾" and why it matters; tapping picks another person who joined.
class _NextFounderRow extends StatelessWidget {
  const _NextFounderRow({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${AccountStrings.nextFounderLabel}: $name',
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.button,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.moss50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AccountStrings.nextFounderLabel}: $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.mossText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AccountStrings.nextFounderHint,
                      style: AppText.sans(size: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              AppIcon.filled(
                AppIcons.chevDown,
                size: 20,
                color: AppColors.mossText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
