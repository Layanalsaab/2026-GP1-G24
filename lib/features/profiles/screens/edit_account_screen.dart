import 'package:flutter/material.dart';

import '../../../helpers/picture_data.dart';

import 'package:flutter/services.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/device_services/profile_photo_picker_service.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/emoji_filter.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/forms/photo_pickers.dart';
import '../../../shared_ui/widgets/forms/select_field.dart';
import '../../../shared_ui/widgets/forms/visibility_pill.dart';
import '../../../shared_ui/widgets/overlays/multi_picker_sheet.dart';
import '../../../shared_ui/widgets/headers/header_buttons.dart';
import '../../../shared_ui/widgets/lists/press_surface.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';
import '../../login_and_signup/widgets/investor_fields.dart';
import '../../login_and_signup/widgets/phone_formatter.dart';
import '../view_models/edit_account_view_model.dart';

/// Edit profile (docs/05 C5, docs/06 section 7, screenshots 41 and 41b):
/// cream top bar with close and "Save", the green photo header, then the
/// fields. Saving validates, closes with the updated [AppUser] and shows
/// "Profile saved".
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditAccountViewModel _vm = EditAccountViewModel(user: widget.user);

  /// Which "i" tip is open (one at a time).
  String? _infoOpen;

  void _toggleInfo(String id) =>
      setState(() => _infoOpen = _infoOpen == id ? null : id);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  /// Close / system back. An investor with unsaved changes is asked first.
  Future<void> _leave() async {
    // While a save is still running the screen can always be left.
    if (_vm.isLoading || !(widget.user.isInvestor && _vm.dirty)) {
      AppNav.back(context);
      return;
    }
    final discard = await showDiscardDialog(
      context,
      title: FounderToolsStrings.discardEditTitle,
      message: FounderToolsStrings.discardEditMessage,
      discardLabel: FounderToolsStrings.discard,
      keepLabel: FounderToolsStrings.keepEditing,
    );
    if (!mounted || !discard) return;
    // pop() directly: the guard below would otherwise ask again.
    Navigator.of(context).pop();
  }

  /// The investor's form: the same fields, order, labels and limits as
  /// "Create your account" and the two question steps (no password fields),
  /// all pre-filled. Same layout as the founder's form.
  Widget _investorForm(AppUser u) {
    final c = _vm.criteria!;
    ImageProvider? image;
    if (_vm.hasPhoto) {
      if (_vm.newPhoto != null) {
        image = FileImage(_vm.newPhoto!);
      } else if (PictureData.bytes(u.photoData) != null) {
        image = MemoryImage(PictureData.bytes(u.photoData)!);
      } else if ((u.photoUrl ?? '').isNotEmpty) {
        image = NetworkImage(u.photoUrl!);
      }
    }
    const noEmoji = [NoEmojiFormatter()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilePhotoRow(onTap: _photo, image: image),
          FormFieldColumn(
            children: [
              LabeledTextField(
                label: AuthStrings.fullName,
                required: true,
                value: _vm.fullName,
                onChanged: _vm.setFullName,
                placeholder: AuthStrings.fullNamePlaceholder,
                maxLength: Validators.maxFullName,
                error: _vm.fullNameError,
                textCapitalization: TextCapitalization.words,
                inputFormatters: noEmoji,
              ),
              LabeledTextField(
                label: AuthStrings.bio,
                required: true,
                value: _vm.bio,
                onChanged: _vm.setBio,
                placeholder: AuthStrings.bioPlaceholder,
                maxLength: Validators.maxFounderBio,
                multiline: true,
                inputFormatters: noEmoji,
                error: _vm.bioError,
              ),
              LabeledTextField(
                label: AuthStrings.email,
                required: true,
                value: u.email,
                enabled: false,
                maxLength: Validators.maxEmail,
                keyboardType: TextInputType.emailAddress,
                labelTrailing: VisibilityPill(
                  isPublic: _vm.emailPublic,
                  onChanged: _vm.setEmailPublic,
                  fieldName: 'email',
                ),
              ),
              LabeledTextField(
                label: AuthStrings.phone,
                required: true,
                value: _vm.phone,
                onChanged: _vm.setPhone,
                placeholder: AuthStrings.phonePlaceholder,
                prefix: AuthStrings.phonePrefix,
                maxLength: Validators.phoneLength,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                error: _vm.phoneError,
                labelTrailing: VisibilityPill(
                  isPublic: _vm.phonePublic,
                  onChanged: _vm.setPhonePublic,
                  fieldName: 'phone',
                ),
              ),
              LabeledTextField(
                label: AuthStrings.linkedin,
                value: _vm.linkedin,
                onChanged: _vm.setLinkedin,
                placeholder: AuthStrings.linkedinPlaceholder,
                maxLength: Validators.maxLinkedin,
                keyboardType: TextInputType.url,
                inputFormatters: noEmoji,
                valid:
                    _vm.linkedin.trim().isNotEmpty &&
                    _vm.linkedinError == null &&
                    _vm.linkedin.contains('linkedin'),
                error: _vm.linkedinError,
              ),
              AppField(
                label: AuthStrings.city,
                required: true,
                error: _vm.cityError,
                child: SelectField(
                  placeholder: AuthStrings.cityPlaceholder,
                  value: _vm.city,
                  semanticLabel: AuthStrings.city,
                  hasError: _vm.cityError != null,
                  onTap: _pickCity,
                ),
              ),
              LabeledTextField(
                label: AuthStrings.valueQuestion,
                required: true,
                value: _vm.valueOffered,
                onChanged: _vm.setValueOffered,
                maxLength: Validators.maxValueText,
                multiline: true,
                placeholder: AuthStrings.valuePlaceholder,
                inputFormatters: noEmoji,
                info: AuthStrings.valueTip,
                infoOpen: _infoOpen == 'value',
                onInfoToggle: () => _toggleInfo('value'),
                error: _vm.valueError,
              ),
              LabeledTextField(
                label: AuthStrings.gainQuestion,
                required: true,
                value: _vm.gain,
                onChanged: _vm.setGain,
                maxLength: Validators.maxValueText,
                multiline: true,
                placeholder: AuthStrings.gainPlaceholder,
                inputFormatters: noEmoji,
                info: AuthStrings.gainTip,
                infoOpen: _infoOpen == 'gain',
                onInfoToggle: () => _toggleInfo('gain'),
                error: _vm.gainError,
              ),
              ...InvestorFields.background(context, c),
              ...InvestorFields.interests(context, c),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final updated = await _vm.submit();
    if (!mounted) return;
    if (updated != null) {
      AppSession.instance.updateUser(updated);
      AppToast.confirm(
        context,
        widget.user.isInvestor
            ? ProfileStrings.changesSaved
            : ProfileStrings.profileSaved,
      );
      // pop() directly: the unsaved-changes guard must not hold the screen.
      Navigator.of(context).pop(updated);
    } else if (_vm.formError != null) {
      AppToast.error(context, _vm.formError!);
    } else {
      AppToast.error(context, ProfileStrings.fixFields);
    }
  }

  Future<void> _pickCity() async {
    final result = await showPickerSheet(
      context,
      title: ProfileStrings.selectCityTitle,
      options: AppStrings.allCities,
      selected: _vm.city,
      searchHint: ProfileStrings.searchCities,
      noResultsText: ProfileStrings.noCities,
    );
    if (result != null) _vm.setCity(result.value);
  }

  /// The sectors shown in the sheet (kept in step with the view model).
  late final Set<String> _sectorSet = {
    ..._vm.sectors,
    if (_vm.otherSelected) EditAccountViewModel.otherLabel,
  };

  Future<void> _pickSectors() async {
    FocusScope.of(context).unfocus();
    await showMultiPickerSheet(
      context,
      title: AuthStrings.sectorsSheetTitle,
      options: EditAccountViewModel.sectorOptions,
      selected: _sectorSet,
      onToggle: (label) {
        if (!_sectorSet.remove(label)) _sectorSet.add(label);
        _vm.toggleSector(label);
      },
      searchHint: AuthStrings.sectorsSearch,
      noResultsText: AuthStrings.sectorsNone,
      otherLabel: EditAccountViewModel.otherLabel,
      otherNoun: AuthStrings.nounSector,
      otherHint: AuthStrings.sectorOtherHint,
      otherText: _vm.otherSector,
      onOtherChanged: _vm.setOtherSector,
      onUndoOther: () {
        _sectorSet.remove(EditAccountViewModel.otherLabel);
        _vm.toggleSector(EditAccountViewModel.otherLabel);
      },
    );
  }

  /// The picked sectors in list order, "Other" shown as what was typed.
  String _sectorsText() {
    final other = _vm.otherSector.trim();
    return [
      for (final o in EditAccountViewModel.sectorOptions)
        if (_sectorSet.contains(o))
          if (o != EditAccountViewModel.otherLabel)
            o
          else if (other.isNotEmpty)
            other,
    ].join(', ');
  }

  /// The founder's form: the same fields, order, labels and limits as
  /// "Create your account" (no password fields).
  Widget _founderForm(AppUser u) {
    ImageProvider? image;
    if (_vm.hasPhoto) {
      if (_vm.newPhoto != null) {
        image = FileImage(_vm.newPhoto!);
      } else if (PictureData.bytes(u.photoData) != null) {
        image = MemoryImage(PictureData.bytes(u.photoData)!);
      } else if ((u.photoUrl ?? '').isNotEmpty) {
        image = NetworkImage(u.photoUrl!);
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilePhotoRow(onTap: _photo, image: image),
          FormFieldColumn(
            children: [
              LabeledTextField(
                label: AuthStrings.fullName,
                required: true,
                value: _vm.fullName,
                onChanged: _vm.setFullName,
                placeholder: AuthStrings.fullNamePlaceholder,
                maxLength: Validators.maxFullName,
                error: _vm.fullNameError,
                textCapitalization: TextCapitalization.words,
              ),
              LabeledTextField(
                label: AuthStrings.bio,
                required: true,
                value: _vm.bio,
                onChanged: _vm.setBio,
                placeholder: AuthStrings.bioPlaceholder,
                maxLength: Validators.maxFounderBio,
                multiline: true,
                error: _vm.bioError,
              ),
              LabeledTextField(
                label: AuthStrings.email,
                required: true,
                value: u.email,
                enabled: false,
                maxLength: Validators.maxEmail,
                keyboardType: TextInputType.emailAddress,
                labelTrailing: VisibilityPill(
                  isPublic: _vm.emailPublic,
                  onChanged: _vm.setEmailPublic,
                  fieldName: 'email',
                ),
              ),
              AppField(
                label: AuthStrings.phone,
                required: true,
                labelTrailing: VisibilityPill(
                  isPublic: _vm.phonePublic,
                  onChanged: _vm.setPhonePublic,
                  fieldName: 'phone',
                ),
                error: _vm.phoneError,
                child: AppTextField(
                  value: _phoneShown(),
                  onChanged: _vm.setPhone,
                  hint: AuthStrings.phonePlaceholder,
                  semanticLabel: AuthStrings.phone,
                  prefix: AuthStrings.phonePrefix,
                  counterMax: Validators.phoneLength,
                  counterOf: (t) => Validators.phoneDigits(t).length,
                  warnLow: false,
                  keyboardType: TextInputType.phone,
                  inputFormatters: const [PhoneInputFormatter()],
                  hasError: _vm.phoneError != null,
                ),
              ),
              LabeledTextField(
                label: AuthStrings.linkedin,
                value: _vm.linkedin,
                onChanged: _vm.setLinkedin,
                placeholder: AuthStrings.linkedinPlaceholder,
                maxLength: Validators.maxLinkedin,
                keyboardType: TextInputType.url,
                valid:
                    _vm.linkedin.trim().isNotEmpty &&
                    _vm.linkedinError == null &&
                    _vm.linkedin.contains('linkedin'),
                error: _vm.linkedinError,
              ),
              AppField(
                label: AuthStrings.city,
                required: true,
                error: _vm.cityError,
                child: SelectField(
                  placeholder: AuthStrings.cityPlaceholder,
                  value: _vm.city,
                  semanticLabel: AuthStrings.city,
                  hasError: _vm.cityError != null,
                  onTap: _pickCity,
                ),
              ),
              AppField(
                label: AuthStrings.sectorsQuestion,
                required: true,
                error: _vm.sectorsError ?? _vm.otherError,
                child: SelectField(
                  placeholder: AuthStrings.sectorsPlaceholder,
                  value: _sectorsText(),
                  semanticLabel: AuthStrings.sectorsQuestion,
                  hasError: _vm.sectorsError != null || _vm.otherError != null,
                  onTap: _pickSectors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The saved digits as "5X XXX XXXX" (what the field shows).
  String _phoneShown() => const PhoneInputFormatter()
      .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: _vm.phone),
      )
      .text;

  Future<void> _photo() async {
    var pick = true;
    if (_vm.hasPhoto) {
      final choice = await showAppBottomSheet<String>(
        context,
        builder: (sheet) => AppSheetScaffold(
          title: ProfileStrings.changePhoto,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetOption(
                  label: AccountStrings.changePhoto,
                  onTap: () => Navigator.of(sheet).pop('change'),
                ),
                _SheetOption(
                  label: AccountStrings.removePhoto,
                  destructive: true,
                  onTap: () => Navigator.of(sheet).pop('remove'),
                ),
              ],
            ),
          ),
        ),
      );
      if (choice == 'remove') {
        _vm.clearPhoto();
      }
      pick = choice == 'change';
    }
    if (!pick || !mounted) return;
    try {
      final file = await ProfilePhotoPickerService.instance.pickSquarePhoto();
      if (file != null) _vm.pickPhoto(file);
    } on ProfilePhotoException catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          e.failure == ProfilePhotoFailure.tooLarge
              ? AccountStrings.photoTooLarge
              : AccountStrings.photoFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final u = widget.user;
        final loading = _vm.isLoading;
        return PopScope(
          canPop: !(u.isInvestor && _vm.dirty),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave();
          },
          child: Scaffold(
            backgroundColor: AppColors.cream,
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                _TopBar(
                  onClose: _leave,
                  onSave: _save,
                  loading: loading,
                  looksOff: u.isInvestor && !_vm.isValid,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: u.isFounder ? _founderForm(u) : _investorForm(u),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cream top bar (prototype `.topbar`): close, title and the green "Save"
/// pill (38 high).
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onClose,
    required this.onSave,
    required this.loading,
    this.looksOff = false,
  });

  final VoidCallback onClose;
  final VoidCallback onSave;
  final bool loading;

  /// Grey until the form is valid; still tappable (tapping shows the errors).
  final bool looksOff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.paddingOf(context).top,
        12,
        0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppIconButton(
              icon: AppIcons.close,
              semanticLabel: 'Close',
              onTap: onClose,
            ),
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  ProfileStrings.editProfile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 18, weight: FontWeight.w700),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: AppButton(
                label: ProfileStrings.save,
                variant: looksOff
                    ? AppButtonVariant.off
                    : AppButtonVariant.primary,
                expanded: false,
                size: AppButtonSize.small,
                loading: loading,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => PressSurface(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        label,
        style: AppText.sans(
          size: 16,
          color: destructive ? AppColors.error : AppColors.ink,
        ),
      ),
    ),
  );
}
