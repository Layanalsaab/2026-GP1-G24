import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import 'app_overlay_route.dart';

/// One option group of the advanced search sheet. [single] groups (e.g.
/// "Sort by") allow one choice and show no "Choose any" hint.
class AdvancedSearchGroup {
  const AdvancedSearchGroup({
    required this.title,
    required this.options,
    this.single = false,
  });

  final String title;
  final List<String> options;
  final bool single;
}

/// Selected options per group title.
typedef AdvancedSelection = Map<String, Set<String>>;

/// Number of selected options across multi-choice groups (the filter badge
/// count; single-choice groups such as "Sort by" are not counted).
int advancedSelectionCount(
  List<AdvancedSearchGroup> groups,
  AdvancedSelection selection,
) {
  var n = 0;
  for (final g in groups) {
    if (!g.single) n += (selection[g.title] ?? const <String>{}).length;
  }
  return n;
}

/// Opens the advanced search panel (dim fades 300 ms, panel slides up 420 ms).
///
/// The sheet edits a draft copy of [initial]. "Show N results" pops with the
/// draft (apply); closing with the X, the dim or back pops null (discard).
/// [countFor] returns the live result count for a draft, used for the button
/// label ("Show N results" / "Show 1 result" / "Show all results" when nothing
/// is selected).
Future<AdvancedSelection?> showAdvancedSearchSheet(
  BuildContext context, {
  required List<AdvancedSearchGroup> groups,
  required AdvancedSelection initial,
  required int Function(AdvancedSelection draft) countFor,
}) {
  return showAppOverlay<AdvancedSelection>(
    context,
    builder: (_) => Align(
      alignment: Alignment.bottomCenter,
      child: AdvancedSearchSheet(
        groups: groups,
        initial: initial,
        countFor: countFor,
      ),
    ),
    dim: const Color(0x730F1912),
    dimDuration: const Duration(milliseconds: 300),
    duration: const Duration(milliseconds: 420),
    entry: AppOverlayEntry.slideUp,
    label: 'Close advanced search',
  );
}

/// The advanced search panel (prototype `.fpanel`): `#F6F4EF`, top radius 24,
/// max height 84 %, grabber, "Advanced search" header with a close button,
/// scrollable groups (title 15/700 + "Choose any" hint, 36 high option chips)
/// and a footer with "Clear all" and the apply button. Normally opened with
/// [showAdvancedSearchSheet].
class AdvancedSearchSheet extends StatefulWidget {
  const AdvancedSearchSheet({
    super.key,
    required this.groups,
    required this.initial,
    required this.countFor,
  });

  final List<AdvancedSearchGroup> groups;
  final AdvancedSelection initial;
  final int Function(AdvancedSelection draft) countFor;

  @override
  State<AdvancedSearchSheet> createState() => _AdvancedSearchSheetState();
}

class _AdvancedSearchSheetState extends State<AdvancedSearchSheet> {
  late AdvancedSelection _draft = {
    for (final e in widget.initial.entries) e.key: {...e.value},
  };

  void _toggle(AdvancedSearchGroup g, String o) {
    setState(() {
      final cur = _draft[g.title] ?? <String>{};
      if (g.single) {
        _draft[g.title] = {o};
      } else if (!cur.remove(o)) {
        cur.add(o);
        _draft[g.title] = cur;
      } else {
        _draft[g.title] = cur;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final cnt = advancedSelectionCount(widget.groups, _draft);
    final n = widget.countFor(_draft);
    final showLabel = cnt == 0
        ? 'Show all results'
        : 'Show $n ${n == 1 ? 'result' : 'results'}';
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.84),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.profileBg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x59000000),
              offset: Offset(0, -12),
              blurRadius: 30,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.sheetGrab,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Advanced search',
                        style: AppText.sans(
                          size: 20,
                          weight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
                    excludeSemantics: true,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Pressable(
                      onTap: () => Navigator.of(context).maybePop(),
                      scale: 0.92,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: AppIcon.filled(
                            AppIcons.close,
                            size: 22,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                children: [
                  for (var i = 0; i < widget.groups.length; i++)
                    _Group(
                      group: widget.groups[i],
                      selected: _draft[widget.groups[i].title] ?? const {},
                      last: i == widget.groups.length - 1,
                      onToggle: (o) => _toggle(widget.groups[i], o),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                math.max(18, mq.viewPadding.bottom),
              ),
              decoration: const BoxDecoration(
                color: AppColors.profileBg,
                border: Border(
                  top: BorderSide(color: AppColors.filterPanelBorder),
                ),
              ),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => setState(() => _draft = {}),
                    child: Semantics(
                      button: true,
                      label: 'Clear all',
                      excludeSemantics: true,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.sheetGrab),
                        ),
                        child: Text(
                          'Clear all',
                          style: AppText.sans(
                            size: 15,
                            color: AppColors.paragraph,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Pressable(
                      onTap: () => Navigator.of(context).pop(_draft),
                      child: Semantics(
                        button: true,
                        label: showLabel,
                        excludeSemantics: true,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.moss600,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            showLabel,
                            style: AppText.sans(
                              size: 15,
                              color: AppColors.white,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.group,
    required this.selected,
    required this.last,
    required this.onToggle,
  });

  final AdvancedSearchGroup group;
  final Set<String> selected;
  final bool last;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.filterPanelBorder),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                header: true,
                child: Text(
                  group.title,
                  style: AppText.sans(size: 15, weight: FontWeight.w700),
                ),
              ),
              if (!group.single)
                Text(
                  'Choose any',
                  style: AppText.sans(
                    size: 12,
                    color: AppColors.grey,
                    weight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final o in group.options)
                _OptionChip(
                  label: o,
                  on: selected.contains(o),
                  onTap: () => onToggle(o),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        scale: 0.96,
        child: AnimatedContainer(
          duration: Motion.dur(context, const Duration(milliseconds: 200)),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.green : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: on ? AppColors.green : AppColors.filterOptBorder,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: Motion.dur(context, const Duration(milliseconds: 200)),
            style: AppText.sans(
              size: 13.5,
              weight: FontWeight.w600,
              color: on ? AppColors.white : AppColors.paragraph,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
