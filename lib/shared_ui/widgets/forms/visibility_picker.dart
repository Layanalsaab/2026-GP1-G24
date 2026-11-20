import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../overlays/app_bottom_sheet.dart';

class VisibilityPicker extends StatefulWidget {
  const VisibilityPicker({
    super.key,
    required this.isPublic,
    required this.onChanged,
    required this.fieldName,
  });

  final bool isPublic;
  final ValueChanged<bool> onChanged;

  final String fieldName;

  @override
  State<VisibilityPicker> createState() => _VisibilityPickerState();
}

class _VisibilityPickerState extends State<VisibilityPicker> {
  bool _pressed = false;

  String get _noun => widget.fieldName == 'phone' ? 'phone number' : 'email';

  Future<void> _open() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final choice = await showAppBottomSheet<bool>(
      context,
      builder: (_) => _VisibilitySheet(noun: _noun, isPublic: widget.isPublic),
    );
    if (choice != null && choice != widget.isPublic) widget.onChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final pub = widget.isPublic;
    return Semantics(
      button: true,
      label:
          'Who can see your $_noun: ${pub ? 'everyone' : 'only you'}. '
          'Tap to change.',
      excludeSemantics: true,
      onTap: _open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _open,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.moss50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppIcon.filled(
                pub ? AppIcons.globe : AppIcons.lock,
                size: 14,
                color: AppColors.mossText,
              ),
              const SizedBox(width: 4),
              Text(
                pub ? 'Public' : 'Only you',
                style: AppText.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.mossText,
                ),
              ),
              const SizedBox(width: 4),
              AppIcon.filled(
                AppIcons.chevDown,
                size: 16,
                color: AppColors.mossText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilitySheet extends StatelessWidget {
  const _VisibilitySheet({required this.noun, required this.isPublic});

  final String noun;
  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Who can see your $noun?',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChoiceRow(
              icon: AppIcons.globe,
              title: 'Public',
              line: 'Anyone on Start.sa can see your $noun on your profile.',
              selected: isPublic,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 4),
            _ChoiceRow(
              icon: AppIcons.lock,
              title: 'Only you',
              line:
                  'Your $noun stays private and is never shown on your profile.',
              selected: !isPublic,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatefulWidget {
  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.line,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String line;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ChoiceRow> createState() => _ChoiceRowState();
}

class _ChoiceRowState extends State<_ChoiceRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: sel,
      label: '${widget.title}. ${widget.line}',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.moss100
                  : (_hover ? AppColors.moss50 : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AppIcon.filled(
                  widget.icon,
                  size: 22,
                  color: sel ? AppColors.mossText : AppColors.grey,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppText.sans(
                          size: 16,
                          weight: FontWeight.w600,
                          color: sel ? AppColors.greenText : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.line,
                        style: AppText.sans(size: 13.5, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Radio(selected: sel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.mossText : AppColors.borderStrong,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.moss600,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
