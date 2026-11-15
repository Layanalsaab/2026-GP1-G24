import 'package:flutter/material.dart';

import '../../../models/connection_request.dart';
import '../../startups/widgets/founder_ui.dart';

/// The one pill that says where a request stands, for the investor's wallet
/// and the founder's requests alike: Pending (gold), Accepted (green, with a
/// check) and Declined (grey).
class RequestStatusPill extends StatelessWidget {
  const RequestStatusPill({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) => AppPill(
    label: switch (status) {
      RequestStatus.pending => 'Pending',
      RequestStatus.accepted => 'Accepted',
      RequestStatus.declined => 'Declined',
    },
    icon: status == RequestStatus.accepted ? AppIcons.check : null,
    tone: switch (status) {
      RequestStatus.pending => AppPillTone.gold,
      RequestStatus.accepted => AppPillTone.moss,
      RequestStatus.declined => AppPillTone.grey,
    },
    height: 26,
    fontSize: 12.5,
    weight: FontWeight.w600,
  );
}
