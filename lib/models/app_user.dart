import '../app_constants/firestore_collections.dart';
import 'investor_criteria.dart';

/// Roles that have an account. Startup seekers never have one.
enum AccountRole {
  founder('founder'),
  investor('investor');

  const AccountRole(this.value);

  /// The string stored in Firestore (`users/{uid}.role`).
  final String value;

  static AccountRole? fromValue(Object? value) {
    for (final role in AccountRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

/// A signed-up user's profile, stored in `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.fullName,
    required this.email,
    this.onboardingCompleted = false,
    this.city,
    this.bio = '',
    this.phone,
    this.sectorsOfInterest = const [],
    this.createdAt,
    this.preferredSectors = const [],
    this.preferredStages = const [],
    this.ticketSize,
    this.photoUrl,
    this.linkedin,
    this.gain = '',
    this.valueOffered = '',
    this.sectorsOther,
    this.investorCriteria,
  });

  final String uid;
  final AccountRole role;
  final String fullName;
  final String email;

  /// True once the user has finished their role's onboarding questions.
  /// Missing in older profiles, which counts as not completed.
  final bool onboardingCompleted;

  /// Where the user is based. Null until they choose one.
  final String? city;

  /// A short "about me" text. Empty when the user hasn't written one.
  final String bio;

  /// The 9-digit Saudi mobile number without +966 (starts with 5). Null when
  /// not saved (older profiles).
  final String? phone;

  /// "Sectors of interest" chosen at sign-up and shown on the profile.
  final List<String> sectorsOfInterest;

  /// When the account was created (shown as "Joined October 2026").
  final DateTime? createdAt;

  /// Investors only: the sectors and stages they invest in (one or more of
  /// each) and their typical ticket size. Empty / null until they answer the
  /// investor onboarding.
  final List<String> preferredSectors;
  final List<String> preferredStages;
  final String? ticketSize;

  /// Download URL of the profile photo; null when the user has none.
  final String? photoUrl;

  /// Optional LinkedIn profile link (sign-up, Edit profile).
  final String? linkedin;

  /// Investors: "What I hope to gain from startups" (at most 1000).
  final String gain;

  /// Investors: "What I can bring to startups" (at most 1000).
  final String valueOffered;

  /// What the user typed for "Other" in their sectors of interest.
  final String? sectorsOther;

  /// Investors: the answers to the sign-up questions (steps 3 and 4).
  final InvestorCriteria? investorCriteria;

  bool get isInvestor => role == AccountRole.investor;
  bool get isFounder => role == AccountRole.founder;

  /// First word of the full name ("Welcome back, Shahad").
  String get firstName {
    final words = fullName.trim().split(RegExp(r'\s+'));
    return words.isEmpty ? '' : words.first;
  }

  /// Two letters for the avatar: first letter of the first and last word.
  String get initials {
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    String first(String w) => String.fromCharCode(w.runes.first);
    if (words.length == 1) {
      final runes = words.first.runes.toList();
      return (first(words.first) +
              (runes.length > 1 ? String.fromCharCode(runes[1]) : ''))
          .toUpperCase();
    }
    return (first(words.first) + first(words.last)).toUpperCase();
  }

  AppUser copyWith({
    String? fullName,
    String? city,
    String? bio,
    String? phone,
    List<String>? sectorsOfInterest,
    bool? onboardingCompleted,
    List<String>? preferredSectors,
    List<String>? preferredStages,
    String? ticketSize,
    String? photoUrl,
    bool clearPhoto = false,
    String? linkedin,
    String? gain,
    String? valueOffered,
    String? sectorsOther,
    InvestorCriteria? investorCriteria,
  }) => AppUser(
    uid: uid,
    role: role,
    fullName: fullName ?? this.fullName,
    email: email,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    city: city ?? this.city,
    bio: bio ?? this.bio,
    phone: phone ?? this.phone,
    sectorsOfInterest: sectorsOfInterest ?? this.sectorsOfInterest,
    createdAt: createdAt,
    preferredSectors: preferredSectors ?? this.preferredSectors,
    preferredStages: preferredStages ?? this.preferredStages,
    ticketSize: ticketSize ?? this.ticketSize,
    photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    linkedin: linkedin ?? this.linkedin,
    gain: gain ?? this.gain,
    valueOffered: valueOffered ?? this.valueOffered,
    sectorsOther: sectorsOther ?? this.sectorsOther,
    investorCriteria: investorCriteria ?? this.investorCriteria,
  );

  /// Returns null when the document is missing a valid role, so callers never
  /// treat a half-created profile as a usable account.
  static AppUser? fromMap(String uid, Map<String, dynamic>? data) {
    if (data == null) return null;
    final role = AccountRole.fromValue(data['role']);
    if (role == null) return null;
    return AppUser(
      uid: uid,
      role: role,
      fullName: (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      onboardingCompleted: data['onboardingCompleted'] == true,
      city: data['city'] as String?,
      bio: (data['bio'] as String?) ?? '',
      phone: data['phone'] as String?,
      sectorsOfInterest: _strings(data['sectorsOfInterest']),
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : null,
      preferredSectors: _strings(data['preferredSectors']),
      preferredStages: _strings(data['preferredStages']),
      ticketSize: data['ticketSize'] as String?,
      photoUrl: data[UserFields.photoUrl] as String?,
      linkedin: data[UserFields.linkedin] as String?,
      gain: (data[UserFields.gain] as String?) ?? '',
      valueOffered: (data[UserFields.valueOffered] as String?) ?? '',
      sectorsOther: data[UserFields.sectorsOther] as String?,
      investorCriteria: InvestorCriteria.fromMap(
        data[UserFields.investorCriteria],
      ),
    );
  }

  /// A Firestore list as a list of strings (anything else is ignored).
  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
