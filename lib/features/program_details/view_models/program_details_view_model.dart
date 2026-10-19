import 'package:flutter/foundation.dart';

import '../../../helpers/app_session.dart';
import '../../../models/program.dart';

/// What the program details page shows for one [Program] (docs/05 C3).
/// Guests never get a bookmark.
class ProgramDetailsViewModel extends ChangeNotifier {
  ProgramDetailsViewModel({required this.program, AppSession? session})
    : _session = session ?? AppSession.instance;

  final Program program;
  final AppSession _session;

  /// `p-<id>`: the bookmark key.
  String get key => 'p-${program.id}';

  bool get showBookmark => _session.canBookmark;

  /// The website as written ("taqadam.kaust.edu.sa"); empty when unknown.
  String get website => (program.websiteUrl ?? '').trim();

  bool get hasWebsite => website.isNotEmpty;

  String get about => program.about.trim();
}
