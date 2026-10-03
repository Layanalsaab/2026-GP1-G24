import 'package:flutter/material.dart';

import '../../../features/explore_startups/screens/seeker_explore_screen.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import 'signup_screen.dart';

enum UserRole {
  founder(
    'Founder',
    'Create and manage your startups, connect with investors, and access support programs.',
    'role_founder.svg',
  ),
  investor(
    'Investor',
    'Discover startups aligned with your investment interests and connect with founders.',
    'role_investor.svg',
  ),
  seeker(
    'Startup Seeker',
    'Browse Saudi startups and express your interest in joining or supporting them.',
    'role_seeker.svg',
  );

  const UserRole(this.title, this.description, this.iconAsset);

  final String title;
  final String description;
  final String iconAsset;

  /// The role stored on an account. Null for seekers, who have no account.
  AccountRole? get accountRole => switch (this) {
        UserRole.founder => AccountRole.founder,
        UserRole.investor => AccountRole.investor,
        UserRole.seeker => null,
      };
}

/// Figma: "V2 · 03 · Choose Role"
class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  UserRole _selected = UserRole.founder;

  /// Founders and investors create an account. Seekers have no account, so
  /// they go straight to the guest explore page.
  void _continue() {
    final accountRole = _selected.accountRole;
    final Widget next = accountRole == null
        ? const SeekerExploreScreen()
        : SignupScreen(role: accountRole);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      bottom: PrimaryButton(label: 'Continue', onPressed: _continue),
      child: Column(
        children: [
          SizedBox(
            width: 72,
            height: 68,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 24),
          Text(
            'I am a...',
            style: AppText.serif(size: 28, color: AppColors.ink, height: 36),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose your role to personalize your experience.',
            textAlign: TextAlign.center,
            style: AppText.sans(size: 16, color: AppColors.grey, height: 24),
          ),
          for (final role in UserRole.values) ...[
            const SizedBox(height: 24),
            _RoleCard(
              role: role,
              selected: role == _selected,
              onTap: () => setState(() => _selected = role),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.moss100 : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.moss600 : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x142F5D3A),
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.moss600 : AppColors.mutedFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: svgIcon(
                  role.iconAsset,
                  size: 22,
                  color: selected ? Colors.white : AppColors.grey,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: AppText.sans(
                      size: 17,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                      height: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.description,
                    style: AppText.sans(size: 12, color: AppColors.grey, height: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            svgIcon(selected ? 'radio_selected.svg' : 'radio_unselected.svg', size: 22),
          ],
        ),
      ),
    );
  }
}
