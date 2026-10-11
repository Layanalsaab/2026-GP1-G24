import 'package:flutter/material.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../data_access/mock_data/mock_startups.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../models/startup.dart';
import '../widgets/startup_profile_view.dart';

/// A startup profile for a signed-in user (Figma "V2 · 45 · Preview
/// (Founder)" and "V2 · 45b · Investor view").
///
/// Founders reach it from Manage and Edit ("Preview"); [isPreview] then adds
/// the preview banner (and whether the startup is private or has unsaved
/// changes) and hides the request button. Investors open it from Explore and
/// the Hub with `isPreview: false` and get "Send request".
///
/// [founderName] is shown as "Founded by ...". It is not loaded for real
/// startups; only the founder's own preview looks up their name. When it is
/// unknown the row is simply left out.
class StartupProfileScreen extends StatefulWidget {
  const StartupProfileScreen({
    super.key,
    required this.startup,
    this.isPreview = false,
    this.hasUnsavedChanges = false,
    this.founderName,
    this.associations = const [],
  });

  final Startup startup;
  final bool isPreview;
  final bool hasUnsavedChanges;
  final String? founderName;
  final List<ProfileAssociation> associations;

  static Future<void> openPreview(
    BuildContext context,
    Startup startup, {
    bool hasUnsavedChanges = false,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StartupProfileScreen(
        startup: startup,
        isPreview: true,
        hasUnsavedChanges: hasUnsavedChanges,
        // Only sample startups have associations so far; a real startup
        // shows none. The profile itself lists just the public ones.
        associations: MockStartups.associationsOf(startup),
      ),
    ),
  );

  @override
  State<StartupProfileScreen> createState() => _StartupProfileScreenState();
}

class _StartupProfileScreenState extends State<StartupProfileScreen> {
  String? _founderName;

  @override
  void initState() {
    super.initState();
    _founderName = widget.founderName;
    // The founder previewing their own startup: show their name too.
    if (_founderName == null && widget.isPreview) _loadFounderName();
  }

  Future<void> _loadFounderName() async {
    try {
      final user = await UserRepository.instance.getProfile(
        widget.startup.founderId,
      );
      final name = user?.fullName.trim();
      if (!mounted || name == null || name.isEmpty) return;
      setState(() => _founderName = name);
    } catch (_) {
      // The row is optional; leave it out.
    }
  }

  @override
  Widget build(BuildContext context) {
    final startup = widget.startup;
    return StartupProfileView(
      startup: startup,
      mode: widget.isPreview
          ? StartupProfileMode.preview
          : StartupProfileMode.investor,
      founderName: _founderName,
      associations: widget.associations,
      notices: [
        if (widget.isPreview && !startup.isPublic)
          StartupStrings.previewPrivateBanner,
        if (widget.isPreview && widget.hasUnsavedChanges)
          StartupStrings.previewUnsavedBanner,
      ],
    );
  }
}
