import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/profile_banner.dart';
import '../../../shared_ui/common_widgets/profile_form_fields.dart';
import '../../../shared_ui/common_widgets/profile_photo_field.dart';
import '../../../shared_ui/common_widgets/user_avatar.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/edit_account_view_model.dart';

/// Figma: "V2 · 43e · Edit Profile — Founder" and "43be — Investor"
/// (PBIs 10 and 12). The same screen for founders and investors, with the
/// same fields, limits and messages as Create Account. On success it closes
/// and returns the updated user.
class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late final EditAccountViewModel _viewModel = EditAccountViewModel(
    user: widget.user,
  );
  late final TextEditingController _fullName = TextEditingController(
    text: widget.user.fullName,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.user.email,
  );
  late final TextEditingController _bio = TextEditingController(
    text: widget.user.bio,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.user.phone ?? '',
  );

  @override
  void dispose() {
    _viewModel.dispose();
    _fullName.dispose();
    _email.dispose();
    _bio.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final updated = await _viewModel.submit(
      fullName: _fullName.text,
      bio: _bio.text,
      phone: _phone.text,
    );
    if (updated == null || !mounted) return;
    if (_viewModel.newPhoto != null || _viewModel.removePhoto) {
      // The photo keeps its URL, so drop the cached image of the old one.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
    Navigator.of(context).pop(updated);
  }

  String? _photoError;

  /// The avatar was tapped: pick a photo, or change / remove the current one.
  Future<void> _changePhoto() async {
    if (_viewModel.isLoading) return;
    if (_viewModel.hasPhoto) {
      final choice = await showPhotoOptionsSheet(context);
      if (choice == null || !mounted) return;
      if (choice == PhotoChoice.remove) {
        setState(() => _photoError = null);
        _viewModel.clearPhoto();
        return;
      }
    }
    final result = await pickProfilePhoto();
    if (!mounted) return;
    setState(() => _photoError = result.error);
    final file = result.file;
    if (file != null) _viewModel.pickPhoto(file);
  }

  Future<void> _pickCity() async {
    final picked = await showCityPicker(context, selected: _viewModel.city);
    if (picked != null) _viewModel.selectCity(picked);
  }

  /// A submit error is only shown when every live rule is met; otherwise the
  /// checklist already explains what is wrong (same as Create Account).
  String? _errorFor(String? error, List<FieldRule> rules) =>
      rules.every((r) => r.met) ? error : null;

  static const _bannerHeight = 88.0;
  static const _avatarSize = 88.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _fullName, _phone]),
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        final attempted = _viewModel.attempted;
        final nameRules = Validators.fullNameRules(_fullName.text);
        final phoneRules = Validators.phoneRules(_phone.text);
        // While saving, Back is blocked so the result is not lost.
        return PopScope(
          canPop: !loading,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
            child: Scaffold(
              backgroundColor: AppColors.cream,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _header(loading),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _banner(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_photoError != null) ...[
                                  FormMessage.error(_photoError!),
                                  const SizedBox(height: 16),
                                ],
                                if (_viewModel.formError != null) ...[
                                  FormMessage.error(_viewModel.formError!),
                                  const SizedBox(height: 16),
                                ],
                                AppTextField(
                                  label: AppStrings.fullNameLabel,
                                  hint: AppStrings.fullNameHint,
                                  controller: _fullName,
                                  rules: nameRules,
                                  showRules: attempted,
                                  errorText: _errorFor(
                                    _viewModel.fullNameError,
                                    nameRules,
                                  ),
                                  maxLength: Validators.maxFullNameLength,
                                  enabled: !loading,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) =>
                                      _viewModel.clearFieldError(),
                                ),
                                const SizedBox(height: 20),
                                AppTextField(
                                  label: AppStrings.bioLabel,
                                  hint: AppStrings.bioHint,
                                  controller: _bio,
                                  maxLines: 4,
                                  maxLength: AccountStrings.bioMaxLength,
                                  enabled: !loading,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                ),
                                const SizedBox(height: 20),
                                CityField(
                                  label: AccountStrings.cityLabel,
                                  city: _viewModel.city,
                                  error: _viewModel.cityError,
                                  enabled: !loading,
                                  onTap: _pickCity,
                                ),
                                const SizedBox(height: 20),
                                _sectors(loading),
                                const SizedBox(height: 20),
                                AppTextField(
                                  label: AppStrings.emailLabel,
                                  hint: AppStrings.emailHint,
                                  controller: _email,
                                  readOnly: true,
                                  maxLength: Validators.maxEmailLength,
                                ),
                                const SizedBox(height: 20),
                                AppTextField(
                                  label: AppStrings.phoneLabel,
                                  hint: AppStrings.phoneHint,
                                  controller: _phone,
                                  rules: phoneRules,
                                  showRules: attempted,
                                  errorText: _errorFor(
                                    _viewModel.phoneError,
                                    phoneRules,
                                  ),
                                  maxLength: Validators.phoneLength,
                                  enabled: !loading,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  prefix: const PhonePrefix(),
                                  onChanged: (_) =>
                                      _viewModel.clearFieldError(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Close (X), "Edit profile" and the Save pill.
  Widget _header(bool loading) => Container(
    height: 56,
    color: AppColors.cream,
    padding: const EdgeInsets.only(left: 4, right: 16),
    child: Row(
      children: [
        IconButton(
          tooltip: AccountStrings.closeEdit,
          onPressed: loading ? null : () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close, color: AppColors.ink),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            AccountStrings.editAccountTitle,
            style: AppText.sans(
              size: 18,
              color: AppColors.ink,
              weight: FontWeight.w600,
              height: 24,
            ),
          ),
        ),
        Material(
          color: AppColors.moss600,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: loading ? null : _save,
            child: Container(
              constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      AccountStrings.save,
                      style: AppText.sans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w600,
                        height: 20,
                      ),
                    ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _banner() => SizedBox(
    height: _bannerHeight + _avatarSize / 2,
    child: Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ProfileBanner(height: _bannerHeight),
        ),
        Positioned(
          top: _bannerHeight - _avatarSize / 2,
          left: 12,
          child: Semantics(
            button: true,
            label: AccountStrings.changePhoto,
            excludeSemantics: true,
            onTap: _changePhoto,
            child: GestureDetector(
              onTap: _changePhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  UserAvatar(
                    name: _fullName.text,
                    size: _avatarSize,
                    ring: true,
                    file: _viewModel.newPhoto,
                    photoUrl: _viewModel.removePhoto
                        ? null
                        : widget.user.photoUrl,
                  ),
                  Container(
                    width: _avatarSize - 8,
                    height: _avatarSize - 8,
                    decoration: const BoxDecoration(
                      color: Color(0x591C1F1D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  /// "Sectors of interest": the same chips as Create Account, on the soft
  /// green fill of the Edit profile design. "Other" is a plain chip.
  Widget _sectors(bool loading) {
    final hasError = _viewModel.sectorsError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AccountStrings.sectorsOfInterest,
          style: AppText.sans(
            size: 14,
            color: hasError ? AppColors.error : AppColors.ink,
            weight: FontWeight.w500,
            height: 20,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final sector in [
              ...AppStrings.sectors,
              AppStrings.otherSector,
            ])
              SectorChip(
                label: sector,
                selected: _viewModel.isSectorSelected(sector),
                soft: true,
                onTap: loading ? null : () => _viewModel.toggleSector(sector),
              ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          FormMessage.error(_viewModel.sectorsError!),
        ],
      ],
    );
  }
}
