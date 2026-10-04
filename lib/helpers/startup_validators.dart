import '../app_constants/startup_strings.dart';
import '../models/startup_enums.dart';

/// Pure validators for the startup form. Each returns an error message, or
/// null when the value is valid. Inputs are the raw text from the fields.
class StartupValidators {
  StartupValidators._();

  static const nameMin = 3;
  static const nameMax = 60;
  static const taglineMax = 80;
  static const descriptionMin = 50;
  static const descriptionMax = 1000;
  static const firstFoundedYear = 2000;

  static String? name(String value) {
    final name = value.trim();
    if (name.isEmpty) return StartupStrings.nameRequired;
    if (name.length < nameMin || name.length > nameMax) {
      return StartupStrings.nameLength(nameMin, nameMax);
    }
    return null;
  }

  static String? tagline(String value) {
    final tagline = value.trim();
    if (tagline.contains('\n')) return StartupStrings.taglineOneLine;
    if (tagline.length > taglineMax) {
      return StartupStrings.taglineTooLong(taglineMax);
    }
    return null;
  }

  static String? description(String value) {
    final description = value.trim();
    if (description.isEmpty) return StartupStrings.descriptionRequired;
    if (description.length < descriptionMin) {
      return StartupStrings.descriptionTooShort(
        descriptionMin,
        description.length,
      );
    }
    if (description.length > descriptionMax) {
      return StartupStrings.descriptionTooLong(descriptionMax);
    }
    return null;
  }

  /// Optional. [now] is injectable so tests don't depend on today's date.
  static String? foundedYear(String value, {DateTime? now}) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final year = int.tryParse(text);
    final lastYear = (now ?? DateTime.now()).year;
    if (year == null || year < firstFoundedYear || year > lastYear) {
      return StartupStrings.foundedYearRange(firstFoundedYear, lastYear);
    }
    return null;
  }

  /// Optional. Accepts addresses without a scheme ("example.com").
  static String? websiteUrl(String value) {
    if (value.trim().isEmpty) return null;
    return normalizeUrl(value) == null ? StartupStrings.websiteInvalid : null;
  }

  /// "example.com" -> "https://example.com". Null when it isn't a usable
  /// http(s) address with a real domain (something.tld).
  static String? normalizeUrl(String value) {
    final text = value.trim();
    if (text.isEmpty || text.contains(' ')) return null;
    final withScheme = text.contains('://') ? text : 'https://$text';
    final uri = Uri.tryParse(withScheme);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final host = uri.host;
    final labels = host.split('.');
    final looksLikeDomain =
        labels.length >= 2 &&
        labels.every((l) => l.isNotEmpty) &&
        RegExp(r'^[a-zA-Z]{2,}$').hasMatch(labels.last);
    return looksLikeDomain ? uri.toString() : null;
  }

  static String? lookingFor(Set<LookingFor> selected) =>
      selected.isEmpty ? StartupStrings.lookingForRequired : null;

  /// Only checked when the founder is looking for funding.
  static String? fundingRequirement(String value) {
    final text = value.trim();
    if (text.isEmpty) return StartupStrings.fundingRequired;
    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) return StartupStrings.fundingInvalid;
    return null;
  }

  static String? required<T>(T? value, String message) =>
      value == null ? message : null;
}
