import 'dart:async';

import 'package:startsa/data_access/remote/for_you_api.dart';

/// Runs before every test file: tests never call the real For You server
/// (a test that needs one passes its own fake).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ForYouApi.instance = ForYouApi(baseUrl: '');
  await testMain();
}
