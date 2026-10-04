import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../data_access/device_services/logo_picker_service.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/startup_validators.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import 'startup_error_message.dart';

/// Every field that can show an inline error, in the order they appear on
/// screen (used to scroll to the first error).
enum StartupField {
  name,
  tagline,
  description,
  sector,
  stage,
  businessModel,
  location,
  foundedYear,
  website,
  lookingFor,
  funding,
}

/// State of the Add Startup and Edit Startup form (see the Provider note in
/// my_startups_view_model.dart).
///
/// Validation rules:
/// - errors are shown only after the founder taps Save, never while typing;
///   editing a field clears that field's error;
/// - Save is enabled once every required field has a value (and, on Edit,
///   something changed). Tapping it runs the full validation.
class StartupFormViewModel extends ChangeNotifier {
  StartupFormViewModel({
    this.initial,
    StartupRepository? repository,
    LogoPickerService? logoPicker,
  }) : _repository = repository ?? StartupRepository.instance,
       _logoPicker = logoPicker ?? LogoPickerService() {
    _fillFrom(initial);
    _savedSnapshot = _snapshot();
    _lastCanSave = canSave;
    for (final controller in _textControllers) {
      controller.addListener(_onTextChanged);
    }
  }

  /// The startup being edited, as last saved. Null on Add.
  final Startup? initial;
  final StartupRepository _repository;
  final LogoPickerService _logoPicker;

  bool get isEditing => initial != null;

  // Text fields
  final name = TextEditingController();
  final tagline = TextEditingController();
  final description = TextEditingController();
  final foundedYear = TextEditingController();
  final website = TextEditingController();
  final funding = TextEditingController();

  List<TextEditingController> get _textControllers => [
    name,
    tagline,
    description,
    foundedYear,
    website,
    funding,
  ];

  // Selections
  Sector? sector;
  StartupStage? stage;
  BusinessModel? businessModel;
  StartupLocation? location;
  Set<LookingFor> lookingFor = {};

  /// Default false, so a new startup is never exposed before it's ready.
  bool isPublic = false;

  // Logo
  File? newLogo;
  bool removeLogo = false;
  String? get existingLogoUrl => removeLogo ? null : initial?.logoUrl;
  bool get hasLogo => newLogo != null || existingLogoUrl != null;

  // Async state
  bool isPickingLogo = false;
  bool isSaving = false;
  bool isDeleting = false;
  bool get isBusy => isSaving || isDeleting || isPickingLogo;

  // Messages
  Map<StartupField, String> errors = {};

  /// Goes up by one on every Save that fails validation, so the form knows
  /// when to scroll to the first error.
  int failedValidations = 0;
  String? logoError;

  /// Network/permission failure from the last save or delete.
  String? actionError;

  bool get seeksFunding => lookingFor.contains(LookingFor.funding);

  late Map<String, Object?> _savedSnapshot;
  bool _disposed = false;

  // Cached so text changes only rebuild when these actually flip.
  bool _lastCanSave = false;
  bool _lastDirty = false;

  /// Every required field has something in it.
  bool get requiredFilled =>
      name.text.trim().isNotEmpty &&
      description.text.trim().isNotEmpty &&
      sector != null &&
      stage != null &&
      businessModel != null &&
      location != null &&
      lookingFor.isNotEmpty &&
      (!seeksFunding || funding.text.trim().isNotEmpty);

  bool get isDirty =>
      newLogo != null || removeLogo || !mapEquals(_snapshot(), _savedSnapshot);

  bool get canSave => requiredFilled && (!isEditing || isDirty);

  /// On Edit, turning a public startup private needs a confirmation.
  bool needsPrivateConfirmation(bool newValue) =>
      isEditing && initial!.isPublic && isPublic && !newValue;

  // ---------------------------------------------------------------- changes

  void selectSector(Sector value) =>
      _change(() => sector = value, StartupField.sector);

  void selectStage(StartupStage value) =>
      _change(() => stage = value, StartupField.stage);

  void selectBusinessModel(BusinessModel value) =>
      _change(() => businessModel = value, StartupField.businessModel);

  void selectLocation(StartupLocation value) =>
      _change(() => location = value, StartupField.location);

  void toggleLookingFor(LookingFor value) => _change(() {
    lookingFor = {...lookingFor};
    if (!lookingFor.remove(value)) lookingFor.add(value);
    if (!seeksFunding) errors.remove(StartupField.funding);
  }, StartupField.lookingFor);

  void setPublic(bool value) => _change(() => isPublic = value, null);

  /// Clears a field's error as soon as the founder edits it.
  void clearError(StartupField field) {
    if (errors.remove(field) != null) _notify();
  }

  Future<void> pickLogo() async {
    if (isBusy) return;
    isPickingLogo = true;
    logoError = null;
    _notify();
    try {
      final file = await _logoPicker.pickSquareLogo();
      if (file != null) {
        newLogo = file;
        removeLogo = false;
      }
    } on LogoPickException catch (e) {
      logoError = e.failure == LogoPickFailure.tooLarge
          ? StartupStrings.logoTooLarge
          : StartupStrings.logoPickFailed;
    } finally {
      isPickingLogo = false;
      _notify();
    }
  }

  void clearLogo() => _change(() {
    newLogo = null;
    removeLogo = initial?.logoUrl != null;
    logoError = null;
  }, null);

  // ---------------------------------------------------------------- actions

  /// Validates everything; returns true when there are no errors.
  bool validate() {
    final found = <StartupField, String?>{
      StartupField.name: StartupValidators.name(name.text),
      StartupField.tagline: StartupValidators.tagline(tagline.text),
      StartupField.description: StartupValidators.description(description.text),
      StartupField.sector: StartupValidators.required(
        sector,
        StartupStrings.sectorRequired,
      ),
      StartupField.stage: StartupValidators.required(
        stage,
        StartupStrings.stageRequired,
      ),
      StartupField.businessModel: StartupValidators.required(
        businessModel,
        StartupStrings.businessModelRequired,
      ),
      StartupField.location: StartupValidators.required(
        location,
        StartupStrings.locationRequired,
      ),
      StartupField.foundedYear: StartupValidators.foundedYear(foundedYear.text),
      StartupField.website: StartupValidators.websiteUrl(website.text),
      StartupField.lookingFor: StartupValidators.lookingFor(lookingFor),
      if (seeksFunding)
        StartupField.funding: StartupValidators.fundingRequirement(
          funding.text,
        ),
    };
    errors = {
      for (final entry in found.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    actionError = errors.isEmpty ? null : StartupStrings.fixErrors;
    if (errors.isNotEmpty) failedValidations++;
    _notify();
    return errors.isEmpty;
  }

  /// First field with an error, in screen order.
  StartupField? get firstErrorField {
    for (final field in StartupField.values) {
      if (errors.containsKey(field)) return field;
    }
    return null;
  }

  /// Validates, then creates or updates the startup. Returns the saved
  /// startup, or null when validation failed or [actionError] says why.
  Future<Startup?> save() async {
    if (isBusy || !validate()) return null;
    isSaving = true;
    actionError = null;
    _notify();
    try {
      final startup = _buildStartup();
      final saved = isEditing
          ? await _repository.update(
              startup,
              newLogo: newLogo,
              removeLogo: removeLogo,
            )
          : await _repository.create(startup, logo: newLogo);
      // Nothing is pending any more, so leaving won't ask to discard.
      newLogo = null;
      removeLogo = false;
      _savedSnapshot = _snapshot();
      return saved;
    } catch (e) {
      actionError = '${StartupStrings.saveFailed} ${startupErrorMessage(e)}';
      return null;
    } finally {
      isSaving = false;
      _notify();
    }
  }

  /// Deletes the startup being edited. Returns true on success.
  Future<bool> delete() async {
    final startup = initial;
    if (startup == null || isBusy) return false;
    isDeleting = true;
    actionError = null;
    _notify();
    try {
      await _repository.delete(startup);
      return true;
    } catch (e) {
      actionError = '${StartupStrings.deleteFailed} ${startupErrorMessage(e)}';
      return false;
    } finally {
      isDeleting = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------- helpers

  Startup _buildStartup() {
    final taglineText = tagline.text.trim();
    final websiteText = website.text.trim();
    return Startup(
      id: initial?.id ?? '',
      founderId: initial?.founderId ?? '',
      name: name.text.trim(),
      tagline: taglineText.isEmpty ? null : taglineText,
      description: description.text.trim(),
      sector: sector!,
      stage: stage!,
      businessModel: businessModel!,
      location: location!,
      foundedYear: int.tryParse(foundedYear.text.trim()),
      websiteUrl: websiteText.isEmpty
          ? null
          : StartupValidators.normalizeUrl(websiteText),
      lookingFor: lookingFor,
      fundingRequirement: seeksFunding
          ? int.tryParse(funding.text.trim())
          : null,
      isPublic: isPublic,
      logoUrl: initial?.logoUrl,
      createdAt: initial?.createdAt,
      updatedAt: initial?.updatedAt,
    );
  }

  void _fillFrom(Startup? s) {
    if (s == null) return;
    name.text = s.name;
    tagline.text = s.tagline ?? '';
    description.text = s.description;
    foundedYear.text = s.foundedYear?.toString() ?? '';
    website.text = s.websiteUrl ?? '';
    funding.text = s.fundingRequirement?.toString() ?? '';
    sector = s.sector;
    stage = s.stage;
    businessModel = s.businessModel;
    location = s.location;
    lookingFor = {...s.lookingFor};
    isPublic = s.isPublic;
  }

  /// Comparable copy of every field, to detect unsaved changes.
  Map<String, Object?> _snapshot() => {
    'name': name.text.trim(),
    'tagline': tagline.text.trim(),
    'description': description.text.trim(),
    'foundedYear': foundedYear.text.trim(),
    'website': website.text.trim(),
    // Funding text only matters while Funding is selected.
    'funding': seeksFunding ? funding.text.trim() : '',
    'sector': sector,
    'stage': stage,
    'businessModel': businessModel,
    'location': location,
    'lookingFor': (lookingFor.map((e) => e.index).toList()..sort()).join(','),
    'isPublic': isPublic,
  };

  void _change(VoidCallback change, StartupField? field) {
    if (isBusy) return;
    change();
    if (field != null) errors.remove(field);
    _notify();
  }

  void _onTextChanged() {
    // Rebuild only when the Save button or the discard guard would change.
    final canSaveNow = canSave;
    final dirtyNow = isDirty;
    if (canSaveNow != _lastCanSave || dirtyNow != _lastDirty) _notify();
  }

  void _notify() {
    if (_disposed) return;
    _lastCanSave = canSave;
    _lastDirty = isDirty;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
