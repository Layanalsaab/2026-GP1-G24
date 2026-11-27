import 'package:flutter/material.dart';

import '../../../app_constants/wallet_strings.dart';
import '../../../helpers/app_session.dart';
import '../../../models/investor_criteria.dart';
import '../../../shared_ui/widgets/lists/app_refresh.dart';
import '../../startups/widgets/founder_ui.dart';
import '../../login_and_signup/view_models/investor_onboarding_view_model.dart';
import '../view_models/wallet_view_model.dart';
import '../widgets/wallet_requests_tab.dart';
import '../widgets/wallet_tickets_tab.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.viewModel});

  /// Tests pass their own view model.
  final WalletViewModel? viewModel;

  static void open(BuildContext context) {
    AppNav.push(context, const WalletScreen(), greenHeader: true);
  }

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletViewModel _vm;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final given = widget.viewModel;
    if (given != null) {
      _vm = given;
    } else {
      final user = AppSession.instance.user;
      _vm = WalletViewModel(
        investorId: user?.uid ?? '',
        commerceModels: user?.investorCriteria?.commerceModels ?? const [],
      )..load();
    }
    _vm.setOptionOrder(
      sectors: InvestorOnboardingViewModel.sectorOptions,
      stages: InvestorCriteria.stageOptions,
    );
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _vm.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _tab) return;
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              TabbedHeader(
                title: WalletStrings.title,
                equalTabs: true,
                tabs: [
                  const HeaderTab(WalletStrings.tabTickets),
                  const HeaderTab(WalletStrings.tabRequests),
                ],
                selectedIndex: _tab,
                onTabChanged: _selectTab,
                onBack: () => AppNav.back(context),
              ),
              Expanded(
                child: AppRefresh(
                  onRefresh: _vm.load,
                  child: SingleChildScrollView(
                    physics: AppRefresh.physics,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: TabPaneSlide(
                      index: _tab,
                      child: _tab == 0
                          ? WalletTicketsTab(vm: _vm)
                          : const WalletRequestsTab(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
