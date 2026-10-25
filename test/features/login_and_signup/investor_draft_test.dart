import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/helpers/investor_draft_store.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/investor_criteria.dart';

class _MemoryStore extends InvestorDraftStore {
  final Map<String, InvestorCriteria> saved = {};

  @override
  Future<InvestorCriteria?> load(String uid) async => saved[uid];

  @override
  Future<void> save(String uid, InvestorCriteria answers) async =>
      saved[uid] = answers;

  @override
  Future<void> clear(String uid) async => saved.remove(uid);
}

const _user = AppUser(
  uid: 'u1',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
);

void main() {
  test('answers are kept on the phone and come back filled in', () async {
    final store = _MemoryStore();
    final first = InvestorOnboardingViewModel(
      user: _user,
      keepDraft: true,
      draftStore: store,
    );
    first.pickYears('1–3 years');
    first.pickDeals('0');
    first.pickLed('Yes');
    first.dispose();
    expect(store.saved['u1']!.dealsCount, '0');

    final again = InvestorOnboardingViewModel(
      user: _user,
      keepDraft: true,
      draftStore: store,
    );
    addTearDown(again.dispose);
    expect(again.step3Complete, isFalse);
    await again.restoreDraft();
    expect(again.years, '1–3 years');
    expect(again.step3Complete, isTrue);
    expect(again.step4Complete, isFalse);
  });

  test('nothing is saved or pre-selected for a fresh investor', () async {
    final store = _MemoryStore();
    final vm = InvestorOnboardingViewModel(
      user: _user,
      keepDraft: true,
      draftStore: store,
    );
    addTearDown(vm.dispose);
    await vm.restoreDraft();
    expect(vm.years, isNull);
    expect(vm.deals, isNull);
    expect(vm.hasLedRound, isNull);
    expect(vm.sectors, isEmpty);
    expect(vm.stages, isEmpty);
    expect(vm.models, isEmpty);
    expect(store.saved, isEmpty);
  });
}
