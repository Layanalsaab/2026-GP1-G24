import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../helpers/startup_validators.dart';
import '../../../models/startup_enums.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/startup_form_view_model.dart';
import 'form_fields.dart';
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartupFormViewModel>();
    _scrollToFirstErrorIfNeeded(vm);
    final enabled = !vm.isBusy;
    final errors = vm.errors;
    final saved = vm.initial;

    final fields = <Widget>[
      // Figma "V2 · 25b": Edit opens with the saved visibility as a banner.
      if (saved != null) _VisibilityBanner(isPublic: saved.isPublic),
      const FieldGroupHeading(StartupStrings.sectionBasics),
      const LogoField(),
      _keyed(
        StartupField.name,
        StartupTextField(
          label: StartupStrings.nameLabel,
          hint: StartupStrings.nameHint,
          controller: vm.name,
          isRequired: true,
          enabled: enabled,
          maxLength: StartupValidators.nameMax,
          textCapitalization: TextCapitalization.words,
          errorText: errors[StartupField.name],
          onChanged: (_) => vm.clearError(StartupField.name),
        ),
      ),
      _keyed(
        StartupField.tagline,
        StartupTextField(
          label: StartupStrings.taglineLabel,
          hint: StartupStrings.taglineHint,
          controller: vm.tagline,
          isRequired: false,
          enabled: enabled,
          maxLength: StartupValidators.taglineMax,
          showCounter: true,
          textCapitalization: TextCapitalization.sentences,
          // One line only: block pasted line breaks.
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
          ],
          errorText: errors[StartupField.tagline],
          onChanged: (_) => vm.clearError(StartupField.tagline),
        ),
      ),
      _keyed(
        StartupField.description,
        StartupTextField(
          label: StartupStrings.descriptionLabel,
          hint: StartupStrings.descriptionHint,
          controller: vm.description,
          isRequired: true,
          enabled: enabled,
          minLines: 4,
          maxLines: 10,
          maxLength: StartupValidators.descriptionMax,
          showCounter: true,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
          helperText: StartupStrings.minChars(StartupValidators.descriptionMin),
          errorText: errors[StartupField.description],
          onChanged: (_) => vm.clearError(StartupField.description),
        ),
      ),
      const FieldGroupHeading(StartupStrings.sectionDetails),
      _keyed(
        StartupField.sector,
        SelectField<Sector>.single(
          label: StartupStrings.sectorLabel,
          options: Sector.values,
          labelOf: (s) => s.label,
          value: vm.sector,
          onChanged: vm.selectSector,
          enabled: enabled,
          errorText: errors[StartupField.sector],
        ),
      ),
      _keyed(
        StartupField.stage,
        SelectField<StartupStage>.single(
          label: StartupStrings.stageLabel,
          options: StartupStage.values,
          labelOf: (s) => s.label,
          value: vm.stage,
          onChanged: vm.selectStage,
          enabled: enabled,
          errorText: errors[StartupField.stage],
        ),
      ),
      _keyed(
        StartupField.location,
        SelectField<StartupLocation>.single(
          label: StartupStrings.locationLabel,
          options: StartupLocation.values,
          labelOf: (l) => l.label,
          value: vm.location,
          onChanged: vm.selectLocation,
          enabled: enabled,
          errorText: errors[StartupField.location],
        ),
      ),
      _keyed(
        StartupField.businessModel,
        SelectField<BusinessModel>.single(
          label: StartupStrings.businessModelLabel,
          options: BusinessModel.values,
          labelOf: (m) => m.label,
          value: vm.businessModel,
          onChanged: vm.selectBusinessModel,
          enabled: enabled,
          errorText: errors[StartupField.businessModel],
        ),
      ),
      _keyed(
        StartupField.foundedYear,
        StartupTextField(
          label: StartupStrings.foundedYearLabel,
          hint: StartupStrings.foundedYearHint,
          controller: vm.foundedYear,
          isRequired: false,
          enabled: enabled,
          maxLength: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: errors[StartupField.foundedYear],
          onChanged: (_) => vm.clearError(StartupField.foundedYear),
        ),
      ),
      _keyed(
        StartupField.website,
        StartupTextField(
          label: StartupStrings.websiteLabel,
          hint: StartupStrings.websiteHint,
          controller: vm.website,
          isRequired: false,
          enabled: enabled,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          errorText: errors[StartupField.website],
          onChanged: (_) => vm.clearError(StartupField.website),
        ),
      ),
      const FieldGroupHeading(StartupStrings.sectionLookingFor),
      _keyed(
        StartupField.lookingFor,
        SelectField<LookingFor>.multi(
          label: StartupStrings.lookingForLabel,
          options: LookingFor.values,
          labelOf: (l) => l.label,
          values: vm.lookingFor,
          onChanged: vm.setLookingFor,
          enabled: enabled,
          errorText: errors[StartupField.lookingFor],
        ),
      ),
      // Only asked when the founder is looking for funding.
      if (vm.seeksFunding)
        _keyed(
          StartupField.funding,
          StartupTextField(
            label: StartupStrings.fundingLabel,
            hint: StartupStrings.fundingHint,
            controller: vm.funding,
            isRequired: true,
            enabled: enabled,
            // 13 digits covers anything up to trillions of SAR.
            maxLength: 13,
            prefixText: '${StartupStrings.sar} ',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText: StartupStrings.fundingHelper,
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
