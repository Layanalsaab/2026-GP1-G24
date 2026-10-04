import '../../../app_constants/startup_strings.dart';
import '../../../models/auth_failure.dart';

/// Turns a data-layer failure into a message the founder can act on.
String startupErrorMessage(Object error) {
  if (error is! AuthException) return StartupStrings.genericError;
  return switch (error.failure) {
    AuthFailure.network => StartupStrings.networkError,
    AuthFailure.permissionDenied => StartupStrings.permissionError,
    AuthFailure.notFound => StartupStrings.notFoundError,
    _ => StartupStrings.genericError,
  };
}
