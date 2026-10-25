import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/device_services/profile_photo_picker_service.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/chips/chip_group.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/forms/photo_pickers.dart';
import '../../../shared_ui/widgets/forms/select_field.dart';
import '../../../shared_ui/widgets/forms/visibility_pill.dart';
import '../../../shared_ui/widgets/overlays/multi_picker_sheet.dart';
import '../../../shared_ui/widgets/headers/header_buttons.dart';
import '../../../shared_ui/widgets/lists/press_surface.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';
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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final updated = await _vm.submit();
    if (!mounted) return;
    if (updated != null) {
      AppSession.instance.updateUser(updated);
      AppToast.confirm(context, ProfileStrings.profileSaved);
      AppNav.back(context, updated);
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
                subLabel:
                    'Select all that apply · ${_sectorSet.length} selected',
                error: _vm.sectorsError ?? _vm.otherError,
                child: SelectField(
                  placeholder: AuthStrings.sectorsPlaceholder,
                  value: _sectorsText(),
                  semanticLabel: AuthStrings.sectorsQuestion,
                  hasError: _vm.sectorsError != null || _vm.otherError != null,
                  onTap: _pickSectors,
                ),
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
            ],
          ),
        ],
      ),
    );
  }

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
          canPop: !loading,
          child: Scaffold(
            backgroundColor: AppColors.cream,
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                _TopBar(
                  onClose: () => AppNav.back(context),
                  onSave: _save,
                  loading: loading,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: u.isFounder
                        ? _founderForm(u)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PhotoHeader(
                                initials: _initials(),
                                photoUrl: u.photoUrl,
                                file: _vm.newPhoto,
                                showPhoto: _vm.hasPhoto,
                                onTap: _photo,
                              ),
                              FormFieldColumn(
                                children: [
                                  LabeledTextField(
                                    label: ProfileStrings.fullName,
                                    required: true,
                                    value: _vm.fullName,
                                    onChanged: _vm.setFullName,
                                    maxLength: 50,
                                    error: _vm.fullNameError,
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  LabeledTextField(
                                    label: ProfileStrings.bio,
                                    value: _vm.bio,
                                    onChanged: _vm.setBio,
                                    maxLength: u.isFounder
                                        ? Validators.maxFounderBio
                                        : Validators.maxBio,
                                    multiline: true,
                                  ),
                                  AppField(
                                    label: ProfileStrings.city,
                                    required: true,
                                    error: _vm.cityError,
                                    child: SelectField(
                                      placeholder:
                                          ProfileStrings.cityPlaceholder,
                                      value: _vm.city,
                                      hasError: _vm.cityError != null,
                                      semanticLabel: ProfileStrings.city,
                                      onTap: _pickCity,
                                    ),
                                  ),
                                  ChipGroupField(
                                    label: ProfileStrings.sectorsOfInterest,
                                    required: true,
                                    options: EditAccountViewModel.sectorOptions,
                                    selected: [
                                      ..._vm.sectors,
                                      if (_vm.otherSelected)
                                        EditAccountViewModel.otherLabel,
                                    ],
                                    onTap: _vm.toggleSector,
                                    error: _vm.sectorsError,
                                    otherValue: _vm.otherSector,
                                    onOtherChanged: _vm.setOtherSector,
                                    otherHint: ProfileStrings.otherSectorHint,
                                    otherError: _vm.otherError,
                                  ),
                                  if (u.isInvestor) ...[
                                    LabeledTextField(
                                      label: ProfileStrings.valueLabel,
                                      required: true,
                                      value: _vm.valueOffered,
                                      onChanged: _vm.setValueOffered,
                                      maxLength: 1000,
                                      multiline: true,
                                      info: ProfileStrings.valueTip,
                                      infoOpen: _infoOpen == 'value',
                                      onInfoToggle: () => _toggleInfo('value'),
                                      error: _vm.valueError,
                                    ),
                                    LabeledTextField(
                                      label: ProfileStrings.gainLabel,
                                      required: true,
                                      value: _vm.gain,
                                      onChanged: _vm.setGain,
                                      maxLength: 1000,
                                      multiline: true,
                                      placeholder: ProfileStrings.gainHint,
                                      info: ProfileStrings.gainTip,
                                      infoOpen: _infoOpen == 'gain',
                                      onInfoToggle: () => _toggleInfo('gain'),
                                      error: _vm.gainError,
                                    ),
                                  ],
                                  LabeledTextField(
                                    label: ProfileStrings.emailLabel,
                                    required: true,
                                    value: u.email,
                                    enabled: false,
                                    maxLength: 100,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  LabeledTextField(
                                    label: ProfileStrings.phoneLabel,
                                    required: true,
                                    value: _vm.phone,
                                    onChanged: _vm.setPhone,
                                    prefix: AppStrings.phoneCountryCode,
                                    maxLength: 9,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    error: _vm.phoneError,
                                  ),
                                  LabeledTextField(
                                    label: ProfileStrings.linkedinLabel,
                                    value: _vm.linkedin,
                                    onChanged: _vm.setLinkedin,
                                    maxLength: 120,
                                    placeholder: ProfileStrings.linkedinHint,
                                    keyboardType: TextInputType.url,
                                    valid:
                                        _vm.linkedin.trim().isNotEmpty &&
                                        _vm.linkedinError == null &&
                                        _vm.linkedin.contains('linkedin'),
                                    error: _vm.linkedinError,
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials() {
    final words = _vm.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return widget.user.initials;
    final a = words.first.characters.first;
    final b = words.length > 1
        ? words.last.characters.first
        : (words.first.characters.length > 1
              ? words.first.characters.elementAt(1)
              : '');
    return (a + b).toUpperCase();
  }
}

/// Cream top bar (prototype `.topbar`): close, title and the green "Save"
/// pill (38 high).
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onClose,
    required this.onSave,
    required this.loading,
  });

  final VoidCallback onClose;
  final VoidCallback onSave;
  final bool loading;

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
              onTap: loading ? null : onClose,
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

/// The 170 px green photo header: gradient with four gold circles, a cream
/// strip at the bottom and the 92 px avatar with the camera overlay.
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.initials,
    required this.photoUrl,
    required this.file,
    required this.showPhoto,
    required this.onTap,
  });

  final String initials;
  final String? photoUrl;
  final File? file;
  final bool showPhoto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (showPhoto) {
      if (file != null) {
        image = FileImage(file!);
      } else if ((photoUrl ?? '').isNotEmpty) {
        image = NetworkImage(photoUrl!);
      }
    }
    return SizedBox(
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: ClipRect(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.green, AppColors.moss600],
                    ),
                  ),
                  child: CustomPaint(painter: _CirclesPainter()),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 40,
            child: ColoredBox(color: AppColors.cream),
          ),
          Positioned(
            left: 16,
            bottom: 0,
            child: Semantics(
              button: true,
              label: ProfileStrings.changePhoto,
              excludeSemantics: true,
              child: Pressable(
                onTap: onTap,
                child: Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.moss600,
                    border: Border.all(color: AppColors.cream, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x801F3F27),
                        blurRadius: 20,
                        spreadRadius: -8,
                        offset: Offset(0, 8),
                      ),
                    ],
                    image: image == null
                        ? null
                        : DecorationImage(image: image, fit: BoxFit.cover),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (image == null)
                        Text(
                          initials,
                          style: AppText.sans(
                            size: 30,
                            weight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      Positioned.fill(
                        child: ColoredBox(
                          color: const Color(0x991F3F27),
                          child: const Center(
                            child: AppIcon.filled(
                              AppIcons.camera,
                              size: 26,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 390;
    for (final (r, a) in const [
      (60.0, .25),
      (100.0, .18),
      (140.0, .12),
      (180.0, .08),
    ]) {
      canvas.drawCircle(
        Offset(330 * s, 60 * s),
        r * s,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.gold.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(_CirclesPainter old) => false;
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
