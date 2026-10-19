import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';

/// The home search bar (prototype `.below3 .sp`): white, 46 high, radius 15,
/// search-bar shadow; search icon (20, `#8C918D`), a "Search" text field
/// (15 px), a 1 x 22 divider and a 40 x 40 tune button (moss600 icon; fill
/// `#EEF4EF` while filters are active, 200 ms; press scale 0.94) with a gold
/// count badge ([activeCount] > 0).
///
/// By default it overlaps the green header above it by 24 px ([overlap]): put
/// it directly after the header in a Column; its layout height is 46 - overlap
/// and the overlapped part still receives taps. Side padding 16.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.onFilterTap,
    this.onChanged,
    this.onSubmitted,
    this.activeCount = 0,
    this.hint = 'Search',
    this.overlap = 24,
  });

  final TextEditingController controller;
  final VoidCallback onFilterTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Number of active filters (badge + active fill).
  final int activeCount;
  final String hint;

  /// How far the bar overlaps the widget above it.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final bar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 46,
        padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: AppShadow.searchBar,
        ),
        child: Row(
          children: [
            const AppIcon.filled(
              AppIcons.search,
              size: 20,
              color: AppColors.hint,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                cursorColor: AppColors.moss600,
                style: AppText.sans(size: 15),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppText.sans(size: 15, color: AppColors.hint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
            Container(width: 1, height: 22, color: AppColors.searchDivider),
            const SizedBox(width: 2),
            _FilterButton(count: activeCount, onTap: onFilterTap),
          ],
        ),
      ),
    );
    if (overlap <= 0) return bar;
    return _Overlap(overlap: overlap, child: bar);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Semantics(
      button: true,
      label: active ? 'Advanced search, $count active' : 'Advanced search',
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        scale: 0.94,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: Motion.dur(
                  context,
                  const Duration(milliseconds: 200),
                ),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.mossChip : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const AppIcon.filled(
                  AppIcons.tune,
                  size: 20,
                  color: AppColors.moss600,
                ),
              ),
              if (active)
                Positioned(
                  top: -2,
                  right: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: AppColors.white, spreadRadius: 2),
                      ],
                    ),
                    child: Text(
                      '$count',
                      style: AppText.sans(
                        size: 9.5,
                        color: AppColors.green,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays its child out normally but reports a height smaller by [overlap] and
/// paints the child [overlap] px higher, so it overlaps the previous sibling.
/// Hit testing covers the overlapped region too (a plain negative margin or a
/// Transform would leave it dead).
class _Overlap extends SingleChildRenderObjectWidget {
  const _Overlap({required this.overlap, required super.child});

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverlap(overlap);

  @override
  void updateRenderObject(BuildContext context, _RenderOverlap renderObject) {
    renderObject.overlap = overlap;
  }
}

class _RenderOverlap extends RenderShiftedBox {
  _RenderOverlap(this._overlap) : super(null);

  double _overlap;
  set overlap(double v) {
    if (v == _overlap) return;
    _overlap = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, (child.size.height - _overlap).clamp(0, 10000)),
    );
    (child.parentData! as BoxParentData).offset = Offset(0, -_overlap);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip the size check so taps in the overlapped strip reach the child.
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
