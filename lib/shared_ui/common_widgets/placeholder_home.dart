import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_constants/app_strings.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

/// Temporary home page for a signed-in role, until the real screens are built.
class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({
    super.key,
    required this.title,
    required this.userName,
    required this.onLogOut,
  });

  final String title;
  final String userName;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.green,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 20,
                24,
                20,
              ),
              child: Text(
                title,
                style: AppText.serif(size: 22, color: Colors.white, height: 28),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.welcomeUser(userName),
                      style: AppText.serif(
                        size: 22,
                        color: AppColors.ink,
                        height: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.comingSoon,
                      style: AppText.sans(
                        size: 14,
                        color: AppColors.grey,
                        height: 20,
                      ),
                    ),
                    const Spacer(),
                    SafeArea(
                      top: false,
                      child: PrimaryButton(
                        label: AppStrings.logOut,
                        onPressed: onLogOut,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
