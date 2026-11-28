import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/validators.dart';
import '../../../models/team_member.dart';
import 'founder_ui.dart';

/// Asks the new founder of a handed-over startup for his role and
/// contribution. It can't be skipped.
Future<void> showFounderDetailsSheet(
  BuildContext context, {
  required String startupId,
  required TeamMember me,
}) => showAppBottomSheet<void>(
  context,
  dismissible: false,
  builder: (_) => _FounderDetailsSheet(startupId: startupId, me: me),
);

class _FounderDetailsSheet extends StatefulWidget {
  const _FounderDetailsSheet({required this.startupId, required this.me});

  final String startupId;
  final TeamMember me;

  @override
  State<_FounderDetailsSheet> createState() => _FounderDetailsSheetState();
}

class _FounderDetailsSheetState extends State<_FounderDetailsSheet> {
  late final _role = TextEditingController(text: widget.me.role);
  late final _contribution = TextEditingController(
    text: widget.me.contribution,
  );
  late final _roleFocus = _focus(_role);
  late final _contributionFocus = _focus(_contribution);

  /// The fields that were left, so their errors show (as in the team step).
  final _left = <TextEditingController>{};
  bool _tried = false;
  bool _busy = false;

  FocusNode _focus(TextEditingController c) {
    final node = FocusNode();
    node.addListener(() {
      if (!node.hasFocus && mounted) setState(() => _left.add(c));
    });
    return node;
  }

  @override
  void dispose() {
    _roleFocus.dispose();
    _contributionFocus.dispose();
    _role.dispose();
    _contribution.dispose();
    super.dispose();
  }

  bool _missing(TextEditingController c) =>
      (_tried || _left.contains(c)) && c.text.trim().isEmpty;

  String? get _roleError {
    if (Validators.hasDigit(_role.text)) {
      return ValidationStrings.memberRoleNoNumbers;
    }
    return _missing(_role) ? ValidationStrings.memberRoleRequired : null;
  }

  String? get _contributionError => _missing(_contribution)
      ? ValidationStrings.memberContributionRequired
      : null;

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_role.text.trim().isEmpty ||
        Validators.hasDigit(_role.text) ||
        _contribution.text.trim().isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = StartupRepository.instance;
      final startup = await repo.fetchById(widget.startupId);
      if (startup == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await repo.setTeam(widget.startupId, [
        for (final m in startup.team)
          if (m.isFounder)
            m.copyWith(
              role: _role.text.trim(),
              contribution: _contribution.text.trim(),
            )
          else
            m,
      ]);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppToast.error(context, AccountStrings.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = FieldHelperRow.gapAfter;
    return PopScope(
      canPop: false,
      child: AppSheetScaffold(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListenableBuilder(
            listenable: Listenable.merge([_role, _contribution]),
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    FounderToolsStrings.titleYourDetails,
                    style: AppText.sans(size: 20, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: FounderToolsStrings.memberRole,
                  required: true,
                  sentenceCase: true,
                  controller: _role,
                  focusNode: _roleFocus,
                  placeholder: FounderToolsStrings.memberRoleHint,
                  maxLength: TeamMember.roleMax,
                  error: _roleError,
                ),
                const SizedBox(height: gap),
                LabeledTextField(
                  label: FounderToolsStrings.memberContribution,
                  required: true,
                  sentenceCase: true,
                  controller: _contribution,
                  focusNode: _contributionFocus,
                  placeholder: FounderToolsStrings.memberContributionHint,
                  maxLength: TeamMember.contributionMax,
                  multiline: true,
                  rows: 3,
                  info: FounderToolsStrings.memberContributionInfo,
                  error: _contributionError,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: FounderToolsStrings.saveMemberButton,
                  loading: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
