import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/startup_activity.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../startups/widgets/manage_card.dart';
import '../view_models/activity_view_model.dart';

/// The Activity card of Manage -> Overview (docs/05 D3): range control, three
/// stats with delta pills and the area chart; or the empty text when the
/// startup has no analytics yet.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.vm});

  final ActivityViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final a = vm.activity;
        return ManageCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  FounderToolsStrings.activity,
                  style: AppText.sans(size: 17, weight: FontWeight.w700),
                ),
              ),
              if (a == null)
                const ManageEmptyText(FounderToolsStrings.activityEmpty)
              else ...[
                const SizedBox(height: 12),
                RangeControl(
                  labels: [for (final r in ActivityRange.values) r.label],
                  selectedIndex: ActivityRange.values.indexOf(vm.range),
                  onChanged: (i) => vm.select(ActivityRange.values[i]),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _Stat(FounderToolsStrings.views, a.views)),
                    Expanded(
                      child: _Stat(FounderToolsStrings.bookmarks, a.bookmarks),
                    ),
                    Expanded(
                      child: _Stat(FounderToolsStrings.requests, a.requests),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AreaChart(values: a.series, axisLabels: a.axis),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.figure);

  final String label;
  final ActivityFigure figure;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ${figure.value}, ${figure.delta}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            figure.value,
            style: AppText.sans(
              size: 22,
              height: 28,
              weight: FontWeight.w700,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          Text(label, style: AppText.sans(size: 12, color: AppColors.grey)),
          const SizedBox(height: 4),
          StatDelta(figure.delta),
        ],
      ),
    );
  }
}
