import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../helpers/startup_validators.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/profile_form_fields.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/startup_form_view_model.dart';
import 'form_fields.dart';
import 'looking_for_chips.dart';
import 'logo_field.dart';
import 'select_field.dart';
import 'visibility_card.dart';

/// The startup form shared by Create and Edit (Figma "V2 · 25" and
/// "V2 · 25b"): labelled fields in one column, grouped under small headings.
/// Reads and writes the [StartupFormViewModel] provided above it.
class StartupForm extends StatefulWidget {
  const StartupForm({super.key});

  @override
  State<StartupForm> createState() => _StartupFormState();
}

class _StartupFormState extends State<StartupForm> {
  /// One key per field, to scroll the first invalid field into view.
  final _keys = {for (final f in StartupField.values) f: GlobalKey()};
  int _seenFailures = 0;

  void _scrollToFirstErrorIfNeeded(StartupFormViewModel vm) {
    if (vm.failedValidations == _seenFailures) return;
    _seenFailures = vm.failedValidations;
    final field = vm.firstErrorField;
    if (field == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _keys[field]?.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _keyed(StartupField field, Widget child) =>
      KeyedSubtree(key: _keys[field], child: child);

  /// The text box shown under a select field once "Other" is chosen.
  Widget _otherField(
    StartupFormViewModel vm, {
    required bool enabled,
    required StartupField field,
    required TextEditingController controller,
    required String label,
    required String hint,
  }) => AppTextField(
    label: label,
    hint: hint,
    controller: controller,
    enabled: enabled,
    maxLength: Startup.otherMaxLength,
    inputFormatters: otherTextFormatters,
    textInputAction: TextInputAction.next,
    errorText: vm.errors[field],
    onChanged: (_) => vm.clearError(field),
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartupFormViewModel>();
    _scrollToFirstErrorIfNeeded(vm);
    final enabled = !vm.isBusy;
    final errors = vm.errors;
    final saved = vm.initial;

    final fields = <Widget>[
      // Figma "Edit startup": the saved visibility is shown as a banner.
      if (saved != null) _VisibilityBanner(isPublic: saved.isPublic),
      const LogoField(),
      _keyed(
        StartupField.name,
        AppTextField(
          label: StartupStrings.nameLabel,
          hint: StartupStrings.nameHint,
          controller: vm.name,
          enabled: enabled,
          maxLength: StartupValidators.nameMax,
          textInputAction: TextInputAction.next,
          errorText: errors[StartupField.name],
          onChanged: (_) => vm.clearError(StartupField.name),
        ),
      ),
      _keyed(
        StartupField.description,
        AppTextField(
          label: StartupStrings.descriptionLabel,
          hint: StartupStrings.descriptionHint,
          controller: vm.description,
          enabled: enabled,
          maxLines: 6,
          maxLength: StartupValidators.descriptionMax,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          errorText: errors[StartupField.description],
          onChanged: (_) => vm.clearError(StartupField.description),
        ),
      ),
      _keyed(
        StartupField.website,
        AppTextField(
          label: StartupStrings.websiteLabel,
          hint: StartupStrings.websiteHint,
          controller: vm.website,
          optional: true,
          enabled: enabled,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          errorText: errors[StartupField.website],
          onChanged: (_) => vm.clearError(StartupField.website),
        ),
      ),
      _keyed(
        StartupField.sector,
        SelectField<Sector>.single(
          label: StartupStrings.sectorLabel,
          hint: StartupStrings.selectSector,
          options: Sector.values,
          labelOf: (s) => s.label,
          value: vm.sector,
          onChanged: vm.selectSector,
          enabled: enabled,
          errorText: errors[StartupField.sector],
          other: OtherChoice(
            option: Sector.other,
            controller: vm.sectorOther,
            label: StartupStrings.sectorOtherLabel,
            hint: StartupStrings.sectorOtherHint,
            maxLength: Startup.otherMaxLength,
            onChanged: () => vm.clearError(StartupField.sectorOther),
          ),
        ),
      ),
      if (vm.isSectorOther)
        _keyed(
          StartupField.sectorOther,
          _otherField(
            vm,
            enabled: enabled,
            field: StartupField.sectorOther,
            controller: vm.sectorOther,
            label: StartupStrings.sectorOtherLabel,
            hint: StartupStrings.sectorOtherHint,
          ),
        ),
      _keyed(
        StartupField.stage,
        SelectField<StartupStage>.single(
          label: StartupStrings.stageLabel,
          hint: StartupStrings.selectStage,
          options: StartupStage.values,
          labelOf: (s) => s.label,
          value: vm.stage,
          onChanged: vm.selectStage,
          enabled: enabled,
          errorText: errors[StartupField.stage],
          other: OtherChoice(
            option: StartupStage.other,
            controller: vm.stageOther,
            label: StartupStrings.stageOtherLabel,
            hint: StartupStrings.stageOtherHint,
            maxLength: Startup.otherMaxLength,
            onChanged: () => vm.clearError(StartupField.stageOther),
          ),
        ),
      ),
      if (vm.isStageOther)
        _keyed(
          StartupField.stageOther,
          _otherField(
            vm,
            enabled: enabled,
            field: StartupField.stageOther,
            controller: vm.stageOther,
            label: StartupStrings.stageOtherLabel,
            hint: StartupStrings.stageOtherHint,
          ),
        ),
      _keyed(
        StartupField.businessModel,
        SelectField<BusinessModel>.single(
          label: StartupStrings.businessModelLabel,
          hint: StartupStrings.selectBusinessModel,
          options: BusinessModel.values,
          labelOf: (m) => m.label,
          value: vm.businessModel,
          onChanged: vm.selectBusinessModel,
          enabled: enabled,
          errorText: errors[StartupField.businessModel],
          other: OtherChoice(
            option: BusinessModel.other,
            controller: vm.businessModelOther,
            label: StartupStrings.businessModelOtherLabel,
            hint: StartupStrings.businessModelOtherHint,
            maxLength: Startup.otherMaxLength,
            onChanged: () => vm.clearError(StartupField.businessModelOther),
          ),
        ),
      ),
      if (vm.isBusinessModelOther)
        _keyed(
          StartupField.businessModelOther,
          _otherField(
            vm,
            enabled: enabled,
            field: StartupField.businessModelOther,
            controller: vm.businessModelOther,
            label: StartupStrings.businessModelOtherLabel,
            hint: StartupStrings.businessModelOtherHint,
          ),
        ),
      _keyed(
        StartupField.location,
        SelectField<StartupLocation>.single(
          label: StartupStrings.locationLabel,
          hint: StartupStrings.selectLocation,
          options: [
            ...StartupLocation.values,
            // An old startup saved with city "Other" keeps showing it.
            if (vm.location == StartupLocation.other) StartupLocation.other,
          ],
          labelOf: (l) => l.label,
          value: vm.location,
          onChanged: vm.selectLocation,
          // The same searchable city list as the sign-up screen.
          customPicker: (context) async {
            final city = await showCityPicker(
              context,
              selected: vm.location?.label,
            );
            if (city == null) return null;
            for (final l in StartupLocation.values) {
              if (l.label == city) return l;
            }
            return null;
          },
          enabled: enabled,
          errorText: errors[StartupField.location],
        ),
      ),
      // Typed, not picked. Not marked "(optional)", but a startup without a
      // year (older documents) still saves.
      _keyed(
        StartupField.foundedYear,
        AppTextField(
          label: StartupStrings.foundedYearLabel,
          hint: StartupStrings.foundedYearHint,
          controller: vm.foundedYearText,
          enabled: enabled,
          maxLength: 4,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: errors[StartupField.foundedYear],
          onChanged: (_) => vm.clearError(StartupField.foundedYear),
        ),
      ),
      _keyed(
        StartupField.lookingFor,
        LookingForChips(
          values: vm.lookingFor,
          onChanged: vm.setLookingFor,
          enabled: enabled,
          errorText: errors[StartupField.lookingFor],
          otherController: vm.lookingForOther,
          otherErrorText: errors[StartupField.lookingForOther],
          onOtherChanged: () => vm.clearError(StartupField.lookingForOther),
        ),
      ),
      // Only asked when the founder is looking for funding.
      if (vm.seeksFunding)
        _keyed(
          StartupField.funding,
          AppTextField(
            label: StartupStrings.fundingLabel,
            hint: StartupStrings.fundingHint,
            controller: vm.funding,
            enabled: enabled,
            // 13 digits covers anything up to trillions of SAR.
            maxLength: 13,
            prefix: const _SarPrefix(),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: errors[StartupField.funding],
            onChanged: (_) => vm.clearError(StartupField.funding),
          ),
        ),
      const FieldGroupHeading(StartupStrings.sectionVisibility),
      const VisibilityCard(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          fields[i],
        ],
      ],
    );
  }
}

/// The "SAR" before the funding amount (Figma "Funding amount").
class _SarPrefix extends StatelessWidget {
  const _SarPrefix();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 14, right: 8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          StartupStrings.sar,
          style: AppText.sans(
            size: 16,
            color: AppColors.ink,
            weight: FontWeight.w500,
            height: 24,
          ),
        ),
        const SizedBox(width: 6),
        Container(width: 1, height: 24, color: AppColors.border),
      ],
    ),
  );
}

/// Gold (private) or moss (public) note at the top of Edit.
class _VisibilityBanner extends StatelessWidget {
  const _VisibilityBanner({required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isPublic ? AppColors.moss50 : AppColors.gold100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isPublic ? AppColors.moss400 : AppColors.gold,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: AppSizes.iconSm,
            color: isPublic ? AppColors.moss600 : AppColors.gold700,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isPublic
                  ? StartupStrings.editPublicBanner
                  : StartupStrings.editPrivateBanner,
              style: AppText.caption.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
