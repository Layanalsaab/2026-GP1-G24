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
import 'visibility_card.dart';

/// The startup form shared by Add and Edit: four section cards (Basics,
/// Details, What you're looking for, Visibility). Reads and writes the
/// [StartupFormViewModel] provided above it.
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

    return Column(
      children: [
        FormSectionCard(
          icon: Icons.storefront_outlined,
          title: StartupStrings.sectionBasics,
          subtitle: StartupStrings.sectionBasicsHint,
          children: [
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
                minLines: 5,
                maxLines: 10,
                maxLength: StartupValidators.descriptionMax,
                showCounter: true,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                helperText: StartupStrings.minChars(
                  StartupValidators.descriptionMin,
                ),
                errorText: errors[StartupField.description],
                onChanged: (_) => vm.clearError(StartupField.description),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSectionCard(
          icon: Icons.tune_rounded,
          title: StartupStrings.sectionDetails,
          subtitle: StartupStrings.sectionDetailsHint,
          children: [
            _keyed(
              StartupField.sector,
              ChipGroupField<Sector>(
                label: StartupStrings.sectorLabel,
                options: Sector.values,
                labelOf: (s) => s.label,
                isSelected: (s) => s == vm.sector,
                onTap: vm.selectSector,
                enabled: enabled,
                errorText: errors[StartupField.sector],
              ),
            ),
            _keyed(
              StartupField.stage,
              ChipGroupField<StartupStage>(
                label: StartupStrings.stageLabel,
                options: StartupStage.values,
                labelOf: (s) => s.label,
                isSelected: (s) => s == vm.stage,
                onTap: vm.selectStage,
                enabled: enabled,
                errorText: errors[StartupField.stage],
              ),
            ),
            _keyed(
              StartupField.businessModel,
              ChipGroupField<BusinessModel>(
                label: StartupStrings.businessModelLabel,
                options: BusinessModel.values,
                labelOf: (m) => m.label,
                isSelected: (m) => m == vm.businessModel,
                onTap: vm.selectBusinessModel,
                enabled: enabled,
                errorText: errors[StartupField.businessModel],
              ),
            ),
            _keyed(
              StartupField.location,
              ChipGroupField<StartupLocation>(
                label: StartupStrings.locationLabel,
                options: StartupLocation.values,
                labelOf: (l) => l.label,
                isSelected: (l) => l == vm.location,
                onTap: vm.selectLocation,
                enabled: enabled,
                errorText: errors[StartupField.location],
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
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSectionCard(
          icon: Icons.track_changes_rounded,
          title: StartupStrings.sectionLookingFor,
          subtitle: StartupStrings.sectionLookingForHint,
          children: [
            _keyed(
              StartupField.lookingFor,
              ChipGroupField<LookingFor>(
                label: StartupStrings.lookingForLabel,
                options: LookingFor.values,
                labelOf: (l) => l.label,
                isSelected: vm.lookingFor.contains,
                onTap: vm.toggleLookingFor,
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
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FormSectionCard(
          icon: Icons.visibility_outlined,
          title: StartupStrings.sectionVisibility,
          subtitle: StartupStrings.sectionVisibilityHint,
          children: [VisibilityCard()],
        ),
      ],
    );
  }
}
