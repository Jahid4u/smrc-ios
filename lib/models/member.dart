import 'member_tier.dart';

enum Gender { man, woman }

class Member {
  final String id;
  final String? memberNo; // e.g. "M-0005" / "No. 0148"
  final String name;
  final Gender gender;
  final MemberTier tier;
  final String? avatarUrl;
  final bool isYou;
  final bool isSuspended;
  final DateTime joinedAt;
  final String email;
  final String bio;
  final String location;
  final String industry;
  final String instagram;
  final String status; // active | cancelled | suspended
  final String? cancelEffectiveAt; // human-readable date the membership ends
  final String? renewsAt; // human-readable next renewal date (active)
  final String? expiresAt; // human-readable end date (renewal, or cancel date if cancelled)
  final String? expiresAtRaw; // ISO yyyy-MM-dd end date for reliable expiry checks
  final List<String> interests;
  final bool hasActiveMembership;

  const Member({
    required this.id,
    this.memberNo,
    required this.name,
    required this.gender,
    required this.tier,
    this.avatarUrl,
    this.isYou = false,
    this.isSuspended = false,
    required this.joinedAt,
    this.email = '',
    this.bio = '',
    this.location = '',
    this.industry = '',
    this.instagram = '',
    this.status = 'active',
    this.cancelEffectiveAt,
    this.renewsAt,
    this.expiresAt,
    this.expiresAtRaw,
    this.interests = const [],
    this.hasActiveMembership = true,
  });

  bool get isCancelled => status == 'cancelled';

  /// Every field ProfileCompletionScreen (and the invited merged application
  /// form) requires: bio, location, industry, Instagram, at least one
  /// interest. Used to enforce Complete Profile centrally in
  /// memberHomeRoute() rather than relying on any one screen in the flow
  /// actually being reached — which is exactly how this used to slip through:
  /// nothing ever routed a freshly-approved regular applicant to Complete
  /// Profile, so they landed in the app with an empty profile.
  bool get hasCompleteProfile =>
      bio.trim().isNotEmpty &&
      location.trim().isNotEmpty &&
      industry.trim().isNotEmpty &&
      instagram.trim().isNotEmpty &&
      interests.isNotEmpty;

  /// True when the membership end date (expiresAt) is in the past. Parsing is
  /// tolerant of the backend "MMMM d, y" format; unparseable/empty means active.
  bool get isExpired {
    final iso = expiresAtRaw;
    if (iso == null || iso.trim().isEmpty) return false;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return false;
    // Compare date-only (end of the expiry day is still valid).
    final today = DateTime.now();
    final endOfDay = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
    return endOfDay.isBefore(today);
  }

  /// Admin-tier and your own account are protected from suspension.
  bool get isProtectedFromSuspension => isYou || tier == MemberTier.admin;

  String get sinceLabel => 'SINCE ${joinedAt.year}';


  /// Backend row (smrc/v1): tier keys are silver|gold|diamond|amb|admin.
  factory Member.fromApi(Map<String, dynamic> j) {
    MemberTier tier;
    switch ('${j['tier'] ?? ''}') {
      case 'gold':
        tier = MemberTier.gold;
        break;
      case 'diamond':
        tier = MemberTier.blackDiamond;
        break;
      case 'amb':
        tier = MemberTier.ambassador;
        break;
      case 'admin':
        tier = MemberTier.admin;
        break;
      default:
        tier = MemberTier.silver;
    }
    if ('${j['role_type'] ?? ''}' == 'admin') tier = MemberTier.admin;
    if ('${j['role_type'] ?? ''}' == 'ambassador') tier = MemberTier.ambassador;
    final since = int.tryParse('${j['member_since'] ?? ''}');
    return Member(
      id: '${j['id'] ?? j['member_uid'] ?? ''}',
      memberNo: j['member_uid'] as String?,
      name: (j['full_name'] ?? '') as String,
      gender: ('${j['gender'] ?? ''}'.toLowerCase() == 'woman') ? Gender.woman : Gender.man,
      tier: tier,
      avatarUrl: (j['profile_photo'] ?? '') == '' ? null : j['profile_photo'] as String,
      isYou: j['is_you'] == 1 || j['is_you'] == true,
      joinedAt: DateTime.tryParse('${j['joined_at'] ?? ''}') ?? DateTime(since ?? DateTime.now().year),
      email: (j['email'] ?? '') as String? ?? '',
      bio: (j['bio'] ??  '') as String? ?? '',
      location: (j['city'] ?? '') as String? ?? '',
      industry: (j['industry'] ?? '') as String? ?? '',
      instagram: (j['instagram'] ?? '') as String? ?? '',
      status: (j['status'] ?? 'active') as String? ?? 'active',
      cancelEffectiveAt: j['cancelEffectiveAt'] as String?,
      renewsAt: j['renewsAt'] as String?,
      expiresAt: j['expiresAt'] as String?,
      expiresAtRaw: j['expiresAtRaw'] as String?,
      interests: (j['interests'] is List)
          ? (j['interests'] as List).map((e) => '$e').toList()
          : const [],
      hasActiveMembership: j['hasActiveMembership'] == true || j['hasActiveMembership'] == 1,
    );
  }

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        memberNo: json['member_no'] as String?,
        name: json['name'] as String,
        gender: (json['gender'] as String?) == 'woman' ? Gender.woman : Gender.man,
        tier: MemberTier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => MemberTier.silver,
        ),
        avatarUrl: json['avatar_url'] as String?,
        isYou: json['is_you'] as bool? ?? false,
        isSuspended: json['is_suspended'] as bool? ?? false,
        joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
        email: json['email'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        location: json['location'] as String? ?? '',
        industry: json['industry'] as String? ?? '',
        instagram: json['instagram'] as String? ?? '',
      );

  Member copyWith(
          {String? name,
          String? email,
          String? bio,
          String? location,
          String? industry,
          String? instagram,
          MemberTier? tier,
          String? status,
          String? cancelEffectiveAt,
          String? renewsAt,
          String? expiresAt,
          String? expiresAtRaw,
          List<String>? interests,
          bool? hasActiveMembership,
          bool clearCancellation = false}) =>
      Member(
        id: id,
        memberNo: memberNo,
        name: name ?? this.name,
        gender: gender,
        tier: tier ?? this.tier,
        avatarUrl: avatarUrl,
        status: status ?? this.status,
        cancelEffectiveAt: clearCancellation ? null : (cancelEffectiveAt ?? this.cancelEffectiveAt),
        renewsAt: renewsAt ?? this.renewsAt,
        expiresAt: expiresAt ?? this.expiresAt,
        expiresAtRaw: expiresAtRaw ?? this.expiresAtRaw,
        interests: interests ?? this.interests,
        hasActiveMembership: hasActiveMembership ?? this.hasActiveMembership,
        isYou: isYou,
        isSuspended: isSuspended,
        joinedAt: joinedAt,
        email: email ?? this.email,
        bio: bio ?? this.bio,
        location: location ?? this.location,
        industry: industry ?? this.industry,
        instagram: instagram ?? this.instagram,
      );
}
