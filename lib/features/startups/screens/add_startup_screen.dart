import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../view_models/startup_form_view_model.dart';
import '../widgets/startup_form_page.dart';

/// Create a new startup. Visibility starts as Private.
/// Closes with a [StartupFormResult] once the startup is saved.
class AddStartupScreen extends StatelessWidget {
  const AddStartupScreen({super.key});

  static Future<StartupFormResult?> open(BuildContext context) =>
      Navigator.of(context).push<StartupFormResult>(
        MaterialPageRoute(builder: (_) => const AddStartupScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StartupFormViewModel(),
      child: const StartupFormPage(
        title: StartupStrings.addTitle,
        saveLabel: StartupStrings.saveNew,
      ),
    );
  }
}
