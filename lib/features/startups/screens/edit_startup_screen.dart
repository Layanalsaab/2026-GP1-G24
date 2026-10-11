import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/startup.dart';
import '../view_models/startup_form_view_model.dart';
import '../widgets/startup_form_page.dart';

/// Edit an existing startup (Figma "V2 · 44d"): the Add form pre-filled, with
/// Save in the top bar. Preview and Delete live on the Manage page. Closes
/// with a [StartupFormResult] after a save.
class EditStartupScreen extends StatelessWidget {
  const EditStartupScreen({super.key, required this.startup});

  final Startup startup;

  static Future<StartupFormResult?> open(
    BuildContext context,
    Startup startup,
  ) => Navigator.of(context).push<StartupFormResult>(
    MaterialPageRoute(builder: (_) => EditStartupScreen(startup: startup)),
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StartupFormViewModel(initial: startup),
      child: const StartupFormPage(
        title: StartupStrings.editTitle,
        saveLabel: StartupStrings.saveChanges,
      ),
    );
  }
}
