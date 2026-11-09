import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/list_entries.dart';
import '../../../models/startup.dart';
import 'founder_ui.dart';
import 'role_tag.dart';

/// What the owner picked in "Choose the next owner": a joined person ([uid])
/// or "Invite someone new" ([invite]).
class NextOwnerPick {
  const NextOwnerPick.person(String this.uid);
  const NextOwnerPick.invite() : uid = null;

  final String? uid;
  bool get invite => uid == null;
}

/// "Choose the next owner" when the owner leaves (docs: Closing a Startup,
/// Leaving and Deleting an Account): a bottom sheet with a card for every
/// person who joined [startup] (their picture or initials, name and tag, like
/// the team list) and, under them, the dashed "Invite someone new" card.
/// Completes with the pick, or null when closed.
Future<NextOwnerPick?> showNextOwnerSheet(
  BuildContext context, {
  required Startup startup,
  required List<String> uids,
}) {
  return showAppBottomSheet<NextOwnerPick>(
    context,
    builder: (_) => _NextOwnerSheet(startup: startup, uids: uids),
  );
}

class _NextOwnerSheet extends StatelessWidget {
  const _NextOwnerSheet({required this.startup, required this.uids});

  final Startup startup;
  final List<String> uids;

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: FounderToolsStrings.nextOwnerTitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              FounderToolsStrings.nextOwnerText(startup.name),
              style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
            ),
            const SizedBox(height: 16),
            for (final uid in uids) ...[
              _PersonCard(
                startup: startup,
                uid: uid,
                onTap: () =>
                    Navigator.of(context).pop(NextOwnerPick.person(uid)),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            _InviteCard(
              onTap: () =>
                  Navigator.of(context).pop(const NextOwnerPick.invite()),
            ),
          ],
        ),
      ),
    );
  }
}

/// One person who can take over: a white card (1 px border, radius 14,
/// padding 12) with the 40 px picture or initials, the name, the
/// Co-founder / Team member tag and a chevron.
class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.startup,
    required this.uid,
    required this.onTap,
  });

  final Startup startup;
  final String uid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = startup.memberRoles[uid] == 'coFounder'
        ? StartupRole.coFounder
        : StartupRole.member;
    final name = startup.nameOf(uid, fallback: RoleTag.labelOf(role));
    String? photo;
    for (final m in startup.team) {
      if (m.uid == uid) photo = m.photoData;
    }
    return Semantics(
      button: true,
      label: '$name, ${RoleTag.labelOf(role)}',
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.button,
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              TileAvatar(
                initials: appInitials(name),
                imageData: photo,
                size: 40,
                radius: 12,
                fontSize: 13,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 15,
                        height: 20,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RoleTag(role),
                  ],
                ),
              ),
              const AppIcon.filled(
                AppIcons.chevRight,
                size: 20,
                color: AppColors.chevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Invite someone new": the dashed moss card of "Add team member", with an
/// envelope tile and "Send an invitation by email".
class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: FounderToolsStrings.inviteSomeoneNew,
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.button,
        hoverColor: AppColors.moss50,
        hoverDuration: AppDur.fast,
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: CustomPaint(
          painter: DashedBorderPainter(color: AppColors.moss600, radius: 14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.moss100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const AppIcon.filled(
                    AppIcons.mail,
                    size: 20,
                    color: AppColors.moss600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FounderToolsStrings.inviteSomeoneNew,
                        style: AppText.sans(
                          size: 15,
                          height: 20,
                          weight: FontWeight.w600,
                          color: AppColors.moss600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        FounderToolsStrings.inviteSomeoneNewText,
                        style: AppText.sans(size: 12, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                const AppIcon.filled(
                  AppIcons.chevRight,
                  size: 20,
                  color: AppColors.moss600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Invite a new owner" when the owner leaves (docs: Closing a Startup,
/// Leaving and Deleting an Account): a bottom sheet laid out like the other
/// leave sheets ([ConfirmSheet]): a round moss envelope, the title, what
/// happens next ([message]), the e-mail field, "Send invitation" and a white
/// "Cancel". [check] says what is wrong with an address (null when it can be
/// invited); it may look the address up, so it is awaited. Completes with the
/// e-mail (trimmed, lower-case), or null when cancelled.
Future<String?> showOwnerEmailSheet(
  BuildContext context, {
  required String message,
  required Future<String?> Function(String email) check,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showAppBottomSheet<String>(
    context,
    builder: (_) => _OwnerEmailSheet(message: message, check: check),
  );
}

class _OwnerEmailSheet extends StatefulWidget {
  const _OwnerEmailSheet({required this.message, required this.check});

  final String message;
  final Future<String?> Function(String email) check;

  @override
  State<_OwnerEmailSheet> createState() => _OwnerEmailSheetState();
}

class _OwnerEmailSheetState extends State<_OwnerEmailSheet> {
  final _email = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_checking) return;
    final email = _email.text.trim().toLowerCase();
    setState(() {
      _checking = true;
      _error = null;
    });
    final problem = await widget.check(email);
    if (!mounted) return;
    if (problem != null) {
      setState(() {
        _checking = false;
        _error = problem;
      });
      return;
    }
    Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Pop(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.moss100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const AppIcon.filled(
                    AppIcons.mail,
                    size: 28,
                    color: AppColors.moss600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                FounderToolsStrings.ownerEmailTitle,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 21, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
            ),
            const SizedBox(height: 18),
            AppField(
              label: FounderToolsStrings.ownerEmailLabel,
              error: _error,
              child: AppTextField(
                controller: _email,
                hint: FounderToolsStrings.ownerEmailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                hasError: _error != null,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: FounderToolsStrings.sendInvitation,
              loading: _checking,
              onPressed: _send,
            ),
            const SizedBox(height: 10),
            SheetCancelButton(
              label: FounderToolsStrings.cancel,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
