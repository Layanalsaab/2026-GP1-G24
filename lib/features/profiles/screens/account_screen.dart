import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/investor_strings.dart';
import '../../../helpers/current_user.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/user_avatar.dart';
import '../../../shared_ui/common_widgets/profile_banner.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/account_view_model.dart';
import 'edit_account_screen.dart';
import 'edit_criteria_screen.dart';

/// Figma: "V2 · 43 · Profile — Founder" and "V2 · 43b · Profile — Investor"
/// (PBIs 9 and 11). Shows the user's saved information; Edit profile opens
/// the edit form. Settings and Log out live in the side menu.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountViewModel _viewModel = AccountViewModel(user: widget.user);

  @override
  void initState() {
    super.initState();
    _viewModel.reload();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  AppUser get _user => _viewModel.user;

  Future<void> _editAccount() async {
    final updated = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(builder: (_) => EditAccountScreen(user: _user)),
    );
    if (updated == null || !mounted) return;
    _viewModel.updateUser(updated);
    CurrentUser.publish(updated);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AccountStrings.changesSaved)));
  }

  Future<void> _editCriteria() async {
    final updated = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(builder: (_) => EditCriteriaScreen(user: _user)),
    );
    if (updated == null || !mounted) return;
    _viewModel.updateUser(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(InvestorStrings.criteriaSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Scaffold(
          backgroundColor: AppColors.cream,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _top(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: _details(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _bannerHeight = 120.0;
  static const _avatarSize = 96.0;

  /// Banner, back button, avatar (overlapping the banner) and Edit profile.
  Widget _top(BuildContext context) {
    final canGoBack = ModalRoute.of(context)?.canPop ?? false;
    final topInset = MediaQuery.of(context).padding.top;
    final bannerHeight = _bannerHeight + topInset;
    return SizedBox(
      height: bannerHeight + _avatarSize / 2 + 8,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ProfileBanner(height: bannerHeight),
          ),
          if (canGoBack)
            Positioned(
              top: topInset + 8,
              left: 12,
              child: Semantics(
                button: true,
                label: 'Back',
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.arrow_back,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: bannerHeight - _avatarSize / 2,
            left: 12,
            child: UserAvatar(
              name: _user.fullName,
              photoUrl: _user.photoUrl,
              size: _avatarSize,
              ring: true,
              fontWeight: FontWeight.w500,
            ),
          ),
          Positioned(
            top: bannerHeight + 8,
            right: 16,
            child: _EditProfileButton(onPressed: _editAccount),
          ),
        ],
      ),
    );
  }

  Widget _details() {
    final user = _user;
    final bio = user.bio.trim();
    final city = user.city;
    final phone = user.phone;
    final joined = user.createdAt;
    final isFounder = user.role == AccountRole.founder;
    // Founders: their startups. Investors: Associations is a placeholder
    // feature for now, so the figure is 0 until it exists.
    final statCount = isFounder ? _viewModel.startupCount : 0;
    final statLabel = isFounder
        ? AccountStrings.startupsCount(statCount ?? 0)
        : AccountStrings.associationsCount(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.fullName,
          style: AppText.sans(
            size: 22,
            color: AppColors.ink,
            weight: FontWeight.w700,
            height: 28,
          ),
        ),
        const SizedBox(height: 8),
        _RolePill(
          label: user.role == AccountRole.founder ? 'Founder' : 'Investor',
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            bio,
            style: AppText.sans(size: 15, color: AppColors.ink, height: 22),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (city != null && city.isNotEmpty)
              _MetaItem(icon: Icons.location_on_outlined, text: city),
            if (user.email.isNotEmpty)
              _MetaItem(icon: Icons.mail_outline, text: user.email),
            if (phone != null && phone.isNotEmpty)
              _MetaItem(
                icon: Icons.phone_outlined,
                text: AccountStrings.formatPhone(phone),
              ),
            if (joined != null)
              _MetaItem(
                icon: Icons.calendar_today_outlined,
                text: AccountStrings.joined(joined),
              ),
          ],
        ),
        if (user.sectorsOfInterest.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sector in user.sectorsOfInterest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.moss100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    sector,
                    style: AppText.sans(
                      size: 13,
                      color: AppColors.green,
                      weight: FontWeight.w500,
                      height: 18,
                    ),
                  ),
                ),
            ],
          ),
        ],
        // Hidden while a founder's startup count hasn't loaded (or failed).
        if (!isFounder || statCount != null) ...[
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${statCount ?? 0}',
                  style: AppText.sans(
                    size: 15,
                    color: AppColors.ink,
                    weight: FontWeight.w700,
                    height: 22,
                  ),
                ),
                TextSpan(
                  text: ' $statLabel',
                  style: AppText.sans(
                    size: 15,
                    color: AppColors.grey,
                    height: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!isFounder) ...[
          const SizedBox(height: 20),
          _CriteriaCard(user: user, onEdit: _editCriteria),
        ],
      ],
    );
  }
}

/// White pill with a thin border, beside the avatar.
class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            AccountStrings.editAccount,
            style: AppText.sans(
              size: 14,
              color: AppColors.ink,
              weight: FontWeight.w600,
              height: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.sans(
          size: 13,
          color: AppColors.gold700,
          weight: FontWeight.w500,
          height: 18,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
          ),
        ),
      ],
    );
  }
}

/// Investors only (PBI 11): their investment criteria, with a link to edit
/// them (PBI 22).
class _CriteriaCard extends StatelessWidget {
  const _CriteriaCard({required this.user, required this.onEdit});

  final AppUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ticket = user.ticketSize;
    // Material (not a plain box) so the Edit button's ripple shows.
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    InvestorStrings.criteriaTitle,
                    style: AppText.sans(
                      size: 15,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                      height: 22,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label:
                      '${InvestorStrings.edit} '
                      '${InvestorStrings.criteriaTitle.toLowerCase()}',
                  // The tap is hidden by excludeSemantics, so expose it here.
                  onTap: onEdit,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Text(
                        InvestorStrings.edit,
                        style: AppText.sans(
                          size: 14,
                          color: AppColors.moss600,
                          weight: FontWeight.w600,
                          height: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TagLine(
                    label: InvestorStrings.sectorsLabel,
                    values: user.preferredSectors,
                  ),
                  const SizedBox(height: 12),
                  _TagLine(
                    label: InvestorStrings.stagesLabel,
                    values: user.preferredStages,
                  ),
                  const SizedBox(height: 12),
                  _TagLine(
                    label: InvestorStrings.ticketLabel,
                    values: [?ticket],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A grey label with its values as small green tags (Figma "Tag"), or
/// "Not set yet" when there are none.
class _TagLine extends StatelessWidget {
  const _TagLine({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.sans(size: 12, color: AppColors.grey, height: 16),
        ),
        const SizedBox(height: 6),
        if (values.isEmpty)
          Text(
            InvestorStrings.notSetYet,
            style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.moss100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    value,
                    style: AppText.sans(
                      size: 12,
                      color: AppColors.green,
                      weight: FontWeight.w500,
                      height: 16,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
