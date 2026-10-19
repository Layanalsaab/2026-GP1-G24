import 'package:flutter/foundation.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/discovery_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/investor_profile.dart';
import '../../../models/startup.dart';

/// What the investor profile shows for one [InvestorProfile] and who is
/// looking (docs/05 C2): founders get "Send investment request"; guests get
/// no bookmark and no CTA; investors get no CTA.
class InvestorProfileViewModel extends ChangeNotifier {
  InvestorProfileViewModel({
    required this.investor,
    AppSession? session,
    DiscoveryRepository? discovery,
  }) : _session = session ?? AppSession.instance,
       _discovery = discovery ?? DiscoveryRepository.instance;

  final InvestorProfile investor;
  final AppSession _session;
  final DiscoveryRepository _discovery;

  String get key => 'i-${investor.id}';

  bool get showBookmark => _session.canBookmark;
  bool get showCta => _session.isFounder;

  /// Startups this investor is associated with.
  List<Startup> get associations =>
      _discovery.associationsOfInvestor(investor.id);

  String get associationCount =>
      ProfileStrings.associationCount(associations.length);

  String get linkedin => (investor.linkedin ?? '').trim();
  String get bring => (investor.valueOffered ?? '').trim();
  String get gain => (investor.hopeToGain ?? '').trim();
  String get about => investor.profileBio.trim();
}
