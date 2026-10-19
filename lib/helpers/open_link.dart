import 'package:url_launcher/url_launcher.dart';

/// Opens [raw] (a web address, with or without "https://") in the browser or
/// the matching app. Does nothing for an empty or unusable address.
Future<void> openExternalLink(String raw) async {
  final text = raw.trim();
  if (text.isEmpty) return;
  final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // No app can open it: nothing to show.
  }
}
