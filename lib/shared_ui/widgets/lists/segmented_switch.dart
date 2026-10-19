import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';

/// The segmented "Startups | Investors" switch (prototype `.fytop`, docs/02
/// §8.11): track 42 high, padding 3, radius 13, fill `#E9E6DF`, equal
/// segments and a white thumb (radius 10, segment-thumb shadow) that slides
/// 300 ms easeOut. Labels 14.5/600 (`#6B726C`, selected green) change colour
/// in 200 ms. No press scale. Works for any number of labels >= 2.
class SegmentedSwitch extends StatefulWidget {
  const SegmentedSwitch({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  /// The segment labels, e.g. `['Startups', 'Investors']`.
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  State<SegmentedSwitch> createState() => _SegmentedSwitchState();
}

class _SegmentedSwitchState extends State<SegmentedSwitch> {
  int? _hover;

  List<String> get labels => widget.labels;
  int get selectedIndex => widget.selectedIndex;
  ValueChanged<int> get onChanged => widget.onChanged;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    final slide = Motion.dur(context, const Duration(milliseconds: 300));
    final colorDur = Motion.dur(context, const Duration(milliseconds: 200));
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.segTrack,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: slide,
              curve: Motion.easeOut,
              alignment: Alignment(
                n < 2 ? -1 : -1 + 2 * selectedIndex / (n - 1),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppShadow.segThumb,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == selectedIndex,
                      label: labels[i],
                      excludeSemantics: true,
                      onTap: () => onChanged(i),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _hover = i),
                        onExit: (_) {
                          if (_hover == i) setState(() => _hover = null);
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i != selectedIndex) onChanged(i);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: colorDur,
                              curve: Curves.ease,
                              style: AppText.sans(
                                size: 14.5,
                                weight: FontWeight.w600,
                                color: i == selectedIndex
                                    ? AppColors.green
                                    : (_hover == i
                                          ? AppColors.moss600
                                          : AppColors.metaText),
                              ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
