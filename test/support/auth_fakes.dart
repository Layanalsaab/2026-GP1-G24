import 'dart:io';

import 'package:startsa/data_access/device_services/profile_photo_picker_service.dart';

/// Stand-in for [ProfilePhotoPickerService]: returns [result] (or throws
/// [failure]) instead of opening the gallery.
class FakePhotoPicker implements ProfilePhotoPickerService {
  File? result;
  ProfilePhotoFailure? failure;
  int picks = 0;

  @override
  Future<File?> pickSquarePhoto() async {
    picks++;
    if (failure != null) throw ProfilePhotoException(failure!);
    return result;
  }
}
