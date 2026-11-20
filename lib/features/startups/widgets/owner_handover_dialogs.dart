import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/list_entries.dart';
import '../../../models/startup.dart';
import 'founder_ui.dart';
import 'role_tag.dart';

class NextOwnerPick {
  const NextOwnerPick.person(String this.uid);
  const NextOwnerPick.invite() : uid = null;

  final String? uid;
  bool get invite => uid == null;
}

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
      title: FounderToolsStrings.nextFounderTitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              FounderToolsStrings.nextFounderText(startup.name),
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
            color: AppColors.surface,
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
              AppIcon.filled(
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
          painter: DashedBorderPainter(color: AppColors.mossText, radius: 14),
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
                  child: AppIcon.filled(
                    AppIcons.mail,
                    size: 20,
                    color: AppColors.mossText,
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
                          color: AppColors.mossText,
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
                AppIcon.filled(
                  AppIcons.chevRight,
                  size: 20,
                  color: AppColors.mossText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StayPick {
  const StayPick(this.stay);

  final String? stay;
  bool get leaves => stay == null;
}

Future<StayPick?> showStayChoiceSheet(
  BuildContext context, {
  required String startupName,
}) {
  return showAppBottomSheet<StayPick>(
    context,
    builder: (ctx) => AppSheetScaffold(
      title: FounderToolsStrings.yourRoleTitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              FounderToolsStrings.yourRoleText(startupName),
              style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
            ),
            const SizedBox(height: 16),
            _StayCard(
              icon: AppIcons.people,
              title: FounderToolsStrings.stayCoFounder,
              text: FounderToolsStrings.stayCoFounderText,
              onTap: () => Navigator.of(ctx).pop(const StayPick('coFounder')),
            ),
            const SizedBox(height: 10),
            _StayCard(
              icon: AppIcons.people,
              title: FounderToolsStrings.stayMember,
              text: FounderToolsStrings.stayMemberText,
              onTap: () => Navigator.of(ctx).pop(const StayPick('member')),
            ),
            const SizedBox(height: 10),
            _StayCard(
              icon: AppIcons.logout,
              title: FounderToolsStrings.leaveForGood,
              text: FounderToolsStrings.leaveForGoodText(startupName),
              danger: true,
              onTap: () => Navigator.of(ctx).pop(const StayPick(null)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
    this.danger = false,
  });

  final String icon;
  final String title;
  final String text;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.mossText;
    return Semantics(
      button: true,
      label: '$title, $text',
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.button,
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: danger ? AppColors.errorFill : AppColors.moss50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AppIcon.filled(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.sans(
                        size: 15,
                        height: 20,
                        weight: FontWeight.w600,
                        color: danger ? AppColors.error : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      style: AppText.sans(size: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              AppIcon.filled(
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
                  decoration: BoxDecoration(
                    color: AppColors.moss100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppIcon.filled(
                    AppIcons.mail,
                    size: 28,
                    color: AppColors.mossText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                FounderToolsStrings.founderEmailTitle,
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
