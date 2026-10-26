import 'package:flutter/foundation.dart';

import '../data_access/repositories/invitation_repository.dart';
import '../models/app_user.dart';
import '../models/invitation.dart';

/// What happens to an account's pending invitations right after it is
/// verified or logs in. The e-mail address is the link: invitations for the
/// account's VERIFIED e-mail.
class InvitationClaimer {
  InvitationClaimer._();

  /// A person who just created and verified their account joins every team
  /// that invited that e-mail, at once. Returns the startup names.
  static Future<List<String>> acceptAll(
    AppUser user, {
    InvitationRepository? repository,
  }) async {
    final repo = repository ?? InvitationRepository.instance;
    final joined = <String>[];
    try {
      for (final invitation in await repo.pendingForMe()) {
        try {
          await repo.accept(invitation, fullName: user.fullName);
          joined.add(invitation.startupName);
        } catch (e) {
          debugPrint('Could not accept ${invitation.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Could not read the invitations: $e');
    }
    return joined;
  }

  /// An investor can't join a team: whatever invited their e-mail is marked
  /// "Declined" (the founder sees it on the card).
  static Future<void> declineAll({InvitationRepository? repository}) async {
    final repo = repository ?? InvitationRepository.instance;
    try {
      for (final invitation in await repo.pendingForMe()) {
        try {
          await repo.decline(invitation);
        } catch (e) {
          debugPrint('Could not decline ${invitation.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Could not read the invitations: $e');
    }
  }

  /// The invitations waiting for an existing account (null on a problem).
  static Future<List<Invitation>> pending({
    InvitationRepository? repository,
  }) async {
    try {
      return await (repository ?? InvitationRepository.instance).pendingForMe();
    } catch (e) {
      debugPrint('Could not read the invitations: $e');
      return const [];
    }
  }

  /// "You've been added to Rafeeq Health" / "...to 2 startups".
  static String addedMessage(List<String> startupNames) =>
      startupNames.length == 1
      ? 'You’ve been added to ${startupNames.first}'
      : 'You’ve been added to ${startupNames.length} startups';
}
