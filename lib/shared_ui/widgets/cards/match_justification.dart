import 'package:flutter/material.dart';

import '../../../models/match_summary.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';

/// The match section at the top of a profile opened from a match: the
/// headline ("86% match with your startup Daftar Pay"), an optional note,
/// then one row per criterion with a thin bar on its left: moss green when
/// it fits, gold when it differs ("Commerce model · B2C" then "they prefer
/// B2B").
class MatchJustification extends StatelessWidget {
  const MatchJustification({super.key, required this.summary});

  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    return Rise(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadow.homeCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${summary.percent}% match',
                      style: AppText.sans(
                        size: 16,
                        height: 22,
                        weight: FontWeight.w700,
                        color: AppColors.moss600,
                      ),
                    ),
                    TextSpan(
                      text: ' with ${summary.target}',
                      style: AppText.sans(
                        size: 16,
                        height: 22,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (summary.note != null) ...[
              const SizedBox(height: 2),
              Text(
                summary.note!,
                style: AppText.sans(
                  size: 13,
                  height: 18,
                  color: AppColors.metaText,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < summary.rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _Row(summary.rows[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.row);

  final MatchRow row;

  @override
  Widget build(BuildContext context) {
    final note = row.note;
    return Semantics(
      label:
          '${row.label}: ${row.value}${note == null ? '' : ', $note'}. '
          '${row.fits ? 'Fits' : 'Differs'}.',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: row.fits ? AppColors.moss600 : AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${row.label} · ',
                            style: AppText.sans(
                              size: 14,
                              height: 20,
                              color: AppColors.grey,
                            ),
                          ),
                          TextSpan(
                            text: row.value,
                            style: AppText.sans(
                              size: 14,
                              height: 20,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (note != null)
                      Text(
                        note,
                        style: AppText.sans(
                          size: 12.5,
                          height: 17,
                          color: row.fits
                              ? AppColors.metaText
                              : AppColors.gold700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
