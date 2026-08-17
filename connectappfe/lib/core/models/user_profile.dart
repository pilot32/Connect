/// A person's professional profile, as returned by every endpoint that embeds
/// one: `/profile/*`, `/directory`, `/connections`, and each feed post's author.
///
/// Lives in `core` because four separate features consume it — keeping it under
/// `features/auth` would force Directory and Feed to import from Auth.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.designation,
    required this.service,
    required this.department,
    required this.stateOrCadre,
    required this.yearsInService,
    this.photoUrl,
    this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      service: json['service'] as String? ?? '',
      department: json['department'] as String? ?? '',
      stateOrCadre: json['stateOrCadre'] as String? ?? '',
      yearsInService: (json['yearsInService'] as num?)?.toInt() ?? 0,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String?,
    );
  }

  final String name;
  final String designation;
  final String service;
  final String department;
  final String stateOrCadre;
  final int yearsInService;
  final String? photoUrl;
  final String? bio;

  /// First letters of the first two words, e.g. "Asha Menon" -> "AM".
  /// Avatar fallback when [photoUrl] is null.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    if (parts.length == 1) return first;
    return first + parts[1].substring(0, 1).toUpperCase();
  }

  /// "IAS · Revenue" — the one-line subtitle used in list rows.
  String get headline {
    final parts = <String>[
      if (service.isNotEmpty) service,
      if (department.isNotEmpty) department,
    ];
    return parts.join(' · ');
  }
}
