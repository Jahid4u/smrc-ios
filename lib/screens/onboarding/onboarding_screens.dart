import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/smrc_repository.dart';
import '../../core/error_classifier.dart';
import '../../providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/app_top_nav.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/tier_badge.dart';
import '../../models/member_tier.dart';
import '../../models/member.dart' show Gender;

// ═══════════════════════ Membership Path (Step 1 of 3) ═══════════════════════
class MembershipPathScreen extends ConsumerStatefulWidget {
  const MembershipPathScreen({super.key});
  @override
  ConsumerState<MembershipPathScreen> createState() => _MembershipPathScreenState();
}

class _MembershipPathScreenState extends ConsumerState<MembershipPathScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(screenCopyProvider).maybeWhen(data: (c) => c, orElse: () => const {});
    String cv(String k, String fb) { final v = copy[k]?.toString() ?? ''; return v.isNotEmpty ? v : fb; }
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text('STEP 1 OF 3', style: AppTextStyles.eyebrow),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.serif(size: 28, color: Colors.white),
                          children: [
                            TextSpan(text: '${cv('path_line1_p1', 'Choose your')} '),
                            TextSpan(
                                text: cv('path_line1_p2', 'path'),
                                style: AppTextStyles.serif(size: 28, color: AppColors.gold, style: FontStyle.italic)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(cv('path_two_ways', 'Two ways to belong, each reviewed by the Society.'),
                          style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: AppColors.muted)),
                      const SizedBox(height: 24),
                      _PathCard(
                        selected: _selected == 0,
                        onTap: () => setState(() => _selected = 0),
                        image: cv('membership_path_img_0', 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=600&q=80'),
                        roman: 'I',
                        romanColor: AppColors.gold,
                        title: cv('path_sm_label', 'SM Society Member'),
                        subtitle: cv('path_sm_desc', 'Access to the club, events and the private SM Society.'),
                        verified: false,
                      ),
                      const SizedBox(height: 14),
                      _PathCard(
                        selected: _selected == 1,
                        onTap: () => setState(() => _selected = 1),
                        image: cv('membership_path_img_1', 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80'),
                        roman: 'II',
                        romanColor: AppColors.ambassador,
                        title: cv('path_amb_label', 'Brand Ambassador'),
                        subtitle: cv('path_amb_desc', 'Verified status, partner perks and visibility within the Circle.'),
                        verified: true,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GoldButton('Continue',
                  onTap: () => context.push('/application-form',
                      extra: {'desiredRole': _selected == 1 ? 'ambassador' : 'member'})),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String image, roman, title, subtitle;
  final Color romanColor;
  final bool verified;
  const _PathCard({
    required this.selected,
    required this.onTap,
    required this.image,
    required this.roman,
    required this.romanColor,
    required this.title,
    required this.subtitle,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(20),
        ),
        // Border painted OVER the content on the exact rounded edge, so the
        // image is never clipped to a smaller inner radius (which caused the
        // 4-sided corner crop when a card was selected).
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      color: Colors.black.withValues(alpha: .18),
                      colorBlendMode: BlendMode.darken,
                      fadeInDuration: Duration.zero,
                      placeholder: (_, __) => Container(color: AppColors.charcoal2),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.charcoal2,
                        alignment: Alignment.center,
                        child: Icon(Icons.diamond_outlined, size: 22, color: romanColor.withValues(alpha: .35)),
                      )),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x26161619), Color(0xEB161619)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x660A0A0B),
                        border: Border.all(color: romanColor),
                      ),
                      child: Text(roman, style: AppTextStyles.serif(size: 12, color: romanColor)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title, style: AppTextStyles.serif(size: 18, color: Colors.white)),
                            if (verified) ...[
                              const SizedBox(width: 7),
                              Container(
                                width: 14,
                                height: 14,
                                decoration:
                                    const BoxDecoration(color: AppColors.ambassador, shape: BoxShape.circle),
                                child: const Icon(Icons.check, size: 9, color: AppColors.ink),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(subtitle,
                            style: AppTextStyles.inter(
                                size: 11, weight: FontWeight.w300, color: AppColors.muted, height: 1.45)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? AppColors.gold : AppColors.line)),
                    child: selected
                        ? Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle))
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ Application Form (Step 2 of 3) ═══════════════════════
/// Live signup: POST /signup (invite code optional route extra). On success
/// the backend emails a 6-digit code and we move to OTP verification.
class ApplicationFormScreen extends ConsumerStatefulWidget {
  /// Present when the user came through the invitation-code door.
  final String? inviteCode;
  /// The email already verified against the invite code on the previous
  /// screen. Pre-fills and locks the Email field so it can't drift from the
  /// code it was matched against.
  final String? inviteEmail;
  /// The path chosen on Choose Your Path — 'member' (SM Society Member) or
  /// 'ambassador' (Brand Ambassador). Only meaningful for the open
  /// (non-invited) application flow; an invite code's own role always
  /// takes priority server-side regardless of this value.
  final String desiredRole;
  const ApplicationFormScreen({super.key, this.inviteCode, this.inviteEmail, this.desiredRole = 'member'});

  @override
  ConsumerState<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends ConsumerState<ApplicationFormScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _instagram = TextEditingController();
  final _whyJoin = TextEditingController();
  final _location = TextEditingController();
  // Invited-signup only: merged straight into this screen instead of a
  // separate Complete Profile step, since an invited signup is one
  // continuous flow with no OTP/review gap in between.
  final _bio = TextEditingController();
  final _industry = TextEditingController();
  final _otherInterest = TextEditingController();
  final Set<String> _selectedInterests = {};
  bool _otherActive = false;
  // Invited-signup only, same as ProfileCompletionScreen: this form IS the
  // complete-profile step for invited members, so a portrait is required
  // here too, not just on the reviewed-applicant path. Uploaded once
  // signupInvited() succeeds (see _submit()) since a valid token is
  // required and doesn't exist before that.
  File? _pickedPhoto;
  static const _interestOptions = [
    'Arts & Culture', 'Business & Finance', 'Dining & Gastronomy', 'Fashion & Style',
    'Film & Theatre', 'Fitness & Wellness', 'Golf', 'Hospitality & Events',
    'Motorsport', 'Music', 'Philanthropy', 'Real Estate', 'Sport', 'Technology',
    'Travel & Adventure', 'Wine & Spirits',
  ];
  bool _isMan = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.inviteCode != null) _code.text = widget.inviteCode!;
    if (widget.inviteEmail != null) _email.text = widget.inviteEmail!;
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _code, _instagram, _whyJoin, _location, _bio, _industry, _otherInterest]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked == null) return;
    setState(() => _pickedPhoto = File(picked.path));
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pass = _password.text;
    final code = _code.text.trim().toUpperCase();
    final isInvited = widget.inviteEmail != null;

    // Collect every missing required field in one pass instead of bailing
    // out on the first sequential check — otherwise the person only ever
    // sees the first problem, fixes it, resubmits, and hits the *next*
    // generic message, one at a time, even though several fields were
    // empty from the start.
    final missing = <String>[];
    if (name.isEmpty) missing.add('Full name');
    if (email.isEmpty) missing.add('Email');
    final otherText = _otherInterest.text.trim();
    final hasOther = _otherActive && otherText.isNotEmpty;
    if (isInvited) {
      // Invited signup has no separate Complete Profile step afterwards, so
      // bio/location/industry/interests/photo are required right here —
      // same requirement ProfileCompletionScreen enforces for the regular
      // (reviewed) path. Every field on this form is mandatory.
      if (_pickedPhoto == null) missing.add('Profile photo');
      if (_bio.text.trim().isEmpty) missing.add('Bio');
      if (_location.text.trim().isEmpty) missing.add('Location');
      if (_industry.text.trim().isEmpty) missing.add('Industry');
      if (_instagram.text.trim().isEmpty) missing.add('Instagram');
      if (_selectedInterests.isEmpty && !hasOther) missing.add('At least one interest');
    } else {
      if (_location.text.trim().isEmpty) missing.add('Location');
      if (_instagram.text.trim().isEmpty) missing.add('Instagram');
      if (_whyJoin.text.trim().isEmpty) missing.add('Why you want to join');
    }
    if (missing.isNotEmpty) {
      setState(() => _error = '${missing.join(', ')} ${missing.length == 1 ? 'is' : 'are'} required.');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      if (isInvited) {
        // Email + code already verified — activate the account immediately,
        // no application review, no OTP, and the profile fields on this same
        // screen are saved right away, so there's no separate Complete
        // Profile step afterwards.
        await ref.read(repoProvider).signupInvited(
              fullName: name,
              email: email,
              password: pass,
              inviteCode: code,
              phone: _phone.text.trim(),
              gender: _isMan ? 'man' : 'woman',
              location: _location.text.trim(),
            );
        // Only reachable once signupInvited() has succeeded, which is the
        // earliest point a valid session/token exists — the upload
        // endpoint requires one, so this can't happen any earlier (e.g. at
        // pick-time, before the account even exists).
        if (_pickedPhoto != null) {
          final bytes = await _pickedPhoto!.readAsBytes();
          await ref.read(repoProvider).uploadProfilePhoto(bytes);
        }
        await ref.read(repoProvider).updateProfile(
              bio: _bio.text.trim(),
              city: _location.text.trim(),
              industry: _industry.text.trim(),
              instagram: _instagram.text.trim(),
              interests: [..._selectedInterests, if (hasOther) otherText],
            );
        final me = await ref.read(repoProvider).me();
        ref.read(currentMemberProvider.notifier).state = me;
        if (mounted) context.go(memberHomeRoute(me));
      } else {
        final id = await ref.read(repoProvider).signup(
              fullName: name,
              email: email,
              password: pass,
              inviteCode: code,
              phone: _phone.text.trim(),
              gender: _isMan ? 'man' : 'woman',
              location: _location.text.trim(),
              instagram: _instagram.text.trim(),
              whyJoin: _whyJoin.text.trim(),
              desiredRole: widget.desiredRole,
            );
        if (mounted) context.push('/verify-email', extra: {'application_id': id, 'email': email});
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = describeError(e).display);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(String label, TextEditingController c, String hint,
      {TextInputType? keyboard, bool obscure = false, TextCapitalization caps = TextCapitalization.none, bool readOnly = false}) {
    return LabeledField(
      label: label,
      controller: c,
      hint: hint,
      keyboardType: keyboard,
      obscureText: obscure,
      textCapitalization: caps,
      readOnly: readOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                      onTap: () => context.pop(),
                      child: Text('‹', style: AppTextStyles.inter(size: 20, color: AppColors.muted))),
                  Text(widget.inviteEmail != null ? 'YOUR PROFILE' : 'STEP 2 OF 3', style: AppTextStyles.eyebrow),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.serif(size: 27, color: Colors.white),
                  children: [
                    TextSpan(text: widget.inviteEmail != null ? 'Your ' : 'Your '),
                    TextSpan(
                        text: widget.inviteEmail != null ? 'profile' : 'application',
                        style: AppTextStyles.serif(size: 27, color: AppColors.gold, style: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                  widget.inviteEmail != null
                      ? 'Invitation verified. Complete your profile to activate your account instantly.'
                      : 'Tell us who you are. Reviewed within 72 hours.',
                  style: AppTextStyles.inter(size: 12, weight: FontWeight.w300, color: AppColors.muted)),
              const SizedBox(height: 14),
              if (widget.inviteEmail != null) ...[
                Center(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _pickPhoto,
                        customBorder: const CircleBorder(),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _pickedPhoto != null
                                ? Container(
                                    width: 84,
                                    height: 84,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.gold, width: 1.6)),
                                    child: ClipOval(child: Image.file(_pickedPhoto!, fit: BoxFit.cover)),
                                  )
                                : RingAvatar(
                                    tier: MemberTier.silver,
                                    size: 84,
                                    imageUrl: '',
                                    gender: _isMan ? Gender.man : Gender.woman),
                            Positioned(
                              bottom: -4,
                              right: -4,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.ink, width: 3)),
                                child: const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('TAP TO ADD PORTRAIT', style: AppTextStyles.eyebrow),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _f('Full Name', _name, 'John Doe', caps: TextCapitalization.words),
              const SizedBox(height: 9),
              _f('Email', _email, 'you@example.com',
                  keyboard: TextInputType.emailAddress, readOnly: widget.inviteEmail != null),
              const SizedBox(height: 9),
              FieldBox(
                label: 'I am',
                child: Row(
                  children: [
                    FilterChipPill('Man', on: _isMan, onTap: () => setState(() => _isMan = true)),
                    const SizedBox(width: 8),
                    FilterChipPill('Woman', on: !_isMan, onTap: () => setState(() => _isMan = false)),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              _f('Phone. Optional', _phone, '+1 (212) 555-0198', keyboard: TextInputType.phone),
              const SizedBox(height: 9),
              _f('Password', _password, 'At least 8 characters', obscure: true),
              // Invited signup has no separate Complete Profile step
              // afterwards — Bio/Location/Industry/Interests are merged into
              // this same screen so the whole account is ready in one go.
              // The regular (reviewed) path still collects these later, in
              // ProfileCompletionScreen, once the application is approved.
              if (widget.inviteEmail != null) ...[
                const SizedBox(height: 9),
                LabeledField(label: 'Bio', controller: _bio, hint: 'Creative director, collector of quiet places.', maxLines: 3),
                const SizedBox(height: 9),
                _f('Location', _location, 'City, Country', caps: TextCapitalization.words),
                const SizedBox(height: 9),
                _f('Instagram', _instagram, '@daniel.hart'),
                const SizedBox(height: 9),
                _f('Industry', _industry, 'Design & Architecture'),
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: Text('INTERESTS', style: AppTextStyles.label)),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tap to select what interests you.',
                      style: AppTextStyles.inter(size: 10.5, weight: FontWeight.w300, color: AppColors.muted2)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._interestOptions.map((opt) {
                    final sel = _selectedInterests.contains(opt);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (sel) {
                          _selectedInterests.remove(opt);
                        } else {
                          _selectedInterests.add(opt);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.gold.withValues(alpha: .14) : Colors.white.withValues(alpha: .02),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: sel ? AppColors.gold : AppColors.line, width: sel ? 1.3 : 1),
                        ),
                        child: Text(opt,
                            style: AppTextStyles.inter(
                                size: 11.5,
                                weight: sel ? FontWeight.w500 : FontWeight.w300,
                                color: sel ? AppColors.gold : AppColors.muted)),
                      ),
                    );
                  }).toList(),
                    GestureDetector(
                      onTap: () => setState(() => _otherActive = !_otherActive),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: _otherActive ? AppColors.gold.withValues(alpha: .14) : Colors.white.withValues(alpha: .02),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _otherActive ? AppColors.gold : AppColors.line, width: _otherActive ? 1.3 : 1),
                        ),
                        child: Text('Other',
                            style: AppTextStyles.inter(
                                size: 11.5,
                                weight: _otherActive ? FontWeight.w500 : FontWeight.w300,
                                color: _otherActive ? AppColors.gold : AppColors.muted)),
                      ),
                    ),
                  ],
                ),
                if (_otherActive) ...[
                  const SizedBox(height: 9),
                  _f('Your interest', _otherInterest, 'e.g. Sailing'),
                ],
              ] else ...[
                const SizedBox(height: 9),
                _f('Location', _location, 'City, Country', caps: TextCapitalization.words),
              ],
              // "Why join" is a review-justification field — not needed for
              // an invited signup, which skips review entirely. Instagram is
              // required for both paths.
              if (widget.inviteEmail == null) ...[
                const SizedBox(height: 9),
                _f('Instagram', _instagram, '@daniel.hart'),
                const SizedBox(height: 9),
                LabeledField(
                  label: 'Why do you want to join?',
                  controller: _whyJoin,
                  hint: 'Tell the Society a little about yourself\u2026',
                  maxLines: 4,
                ),
              ],
              const SizedBox(height: 9),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.admin.withValues(alpha: .5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE68688))),
                ),
              ],
              const SizedBox(height: 24),
              _busy
                  ? const Center(
                      child: SizedBox(
                          width: 26, height: 26,
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
                  : GoldButton(widget.inviteEmail != null ? 'Activate Account' : 'Submit Application', onTap: _submit),
              const SizedBox(height: 12),
              Center(
                child: PrivacyConsentText(
                    action: widget.inviteEmail != null
                        ? 'activating your account'
                        : 'submitting your application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════ Verify Email (signup OTP) ═══════════════════════
/// POST /verify-otp with the 6-digit code the backend emailed at signup.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final int applicationId;
  final String email;
  const VerifyEmailScreen({super.key, required this.applicationId, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _len = 6;
  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _nodes = List.generate(_len, (_) => FocusNode());
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _len) {
      setState(() => _error = 'Enter the full 6-digit code.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final refNo = await ref.read(repoProvider).verifyOtp(widget.applicationId, otp);
      if (mounted) context.go('/pending-review', extra: refNo);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = describeError(e).display);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 42, 26, 28),
          child: Column(
            children: [
              const GoldRingIcon(icon: Icons.mark_email_read_outlined, size: 74),
              const SizedBox(height: 22),
              Text('CHECK YOUR EMAIL', style: AppTextStyles.eyebrow),
              const SizedBox(height: 10),
              const HeroTitle(line1: 'Enter the', em: 'code we sent.', size: 27),
              const SizedBox(height: 14),
              Text('A 6-digit code was sent to ${widget.email}. It expires in 10 minutes.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.inter(
                      size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.6)),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_len, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.5),
                    child: SizedBox(
                      width: 38,
                      height: 50,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _nodes[i],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.serif(size: 18, color: Colors.white),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.gold),
                          ),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < _len - 1) _nodes[i + 1].requestFocus();
                          if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                          if (i == _len - 1 && v.isNotEmpty) _verify();
                        },
                      ),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE68688))),
              ],
              const Spacer(),
              _busy
                  ? const Center(
                      child: SizedBox(
                          width: 26, height: 26,
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
                  : GoldButton('Verify Email', onTap: _verify),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════ Application Submitted ═══════════════════════
class ApplicationSubmittedScreen extends StatelessWidget {
  final String? refNo;
  const ApplicationSubmittedScreen({super.key, this.refNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoldRingIcon(icon: Icons.check, size: 78),
                    const SizedBox(height: 28),
                    Text('RECEIVED', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 12),
                    const HeroTitle(line1: 'Your name is', em: 'now before us.', size: 30),
                    const SizedBox(height: 16),
                    Text(
                        'The Society reviews each application personally. You will hear from us within 72 hours by email.',
                        textAlign: TextAlign.center,
                        style:
                            AppTextStyles.inter(size: 13, weight: FontWeight.w300, color: AppColors.muted, height: 1.65)),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('REF. ${refNo ?? '\u2014'}',
                          style: AppTextStyles.inter(size: 11, color: AppColors.gold, letterSpacing: 2)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              bottom: 46,
              child: GoldButton('Back to Start', style: GoldBtnStyle.ghost, onTap: () => context.go('/welcome')),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ Pending Review ═══════════════════════
class PendingReviewScreen extends StatelessWidget {
  final String? refNo;
  const PendingReviewScreen({super.key, this.refNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoldRingIcon(icon: Icons.schedule, size: 80),
                    const SizedBox(height: 26),
                    Text('UNDER REVIEW', style: AppTextStyles.eyebrow),
                    const SizedBox(height: 12),
                    const HeroTitle(line1: 'Your application', em: 'is with us.', size: 29),
                    const SizedBox(height: 14),
                    Text(
                        'The Society is reviewing your application personally. Most decisions are made within three days.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inter(
                            size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.65)),
                    const SizedBox(height: 24),
                    _kvCard('Reference', refNo ?? '\u2014'),
                    const SizedBox(height: 10),
                    _kvCard('Est. review', '48 to 72 hours'),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              bottom: 44,
              child: GoldButton('Contact Support', style: GoldBtnStyle.ghost,
                  onTap: () => launchUrlString('mailto:info@smroyalcircle.club?subject=${Uri.encodeComponent('Application Support')}')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvCard(String k, String v) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k.toUpperCase(),
                style: AppTextStyles.inter(size: 9.5, weight: FontWeight.w600, color: AppColors.muted2, letterSpacing: 3)),
            Text(v, style: AppTextStyles.inter(size: 12, color: const Color(0xFFE9E7E1))),
          ],
        ),
      );
}

// ═══════════════════════ Approved ═══════════════════════
class ApprovedScreen extends ConsumerStatefulWidget {
  const ApprovedScreen({super.key});

  @override
  ConsumerState<ApprovedScreen> createState() => _ApprovedScreenState();
}

class _ApprovedScreenState extends ConsumerState<ApprovedScreen> {
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    // Show the complimentary-membership gift popup once, after first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGiftPopup());
  }

  void _showGiftPopup() {
    if (_popupShown || !mounted) return;
    _popupShown = true;
    final copy = ref.read(screenCopyProvider).maybeWhen(data: (c) => c, orElse: () => const {});
    final msg = (copy['approved_gift_popup']?.toString().trim().isNotEmpty ?? false)
        ? copy['approved_gift_popup'].toString()
        : 'Congratulations! You have been gifted a complimentary 6-month Silver Membership by SM Royal Circle.';
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .6),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 34),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GoldRingIcon(icon: Icons.card_giftcard, size: 66),
              const SizedBox(height: 20),
              Text('A GIFT FOR YOU', style: AppTextStyles.eyebrow),
              const SizedBox(height: 12),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.inter(
                      size: 13.5, weight: FontWeight.w300, color: const Color(0xFFE9E7E1), height: 1.6)),
              const SizedBox(height: 24),
              GoldButton('Wonderful', onTap: () => Navigator.of(ctx).pop()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(screenCopyProvider).maybeWhen(data: (c) => c, orElse: () => const {});
    String cv(String k, String fb) { final v = copy[k]?.toString() ?? ''; return v.isNotEmpty ? v : fb; }
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
              imageUrl: cv('approved_img',
                  'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?w=700&q=80'),
              fit: BoxFit.cover,
              memCacheWidth: 700,
              fadeInDuration: Duration.zero,
              placeholder: (_, __) => const SizedBox(),
              errorWidget: (_, __, ___) => const SizedBox()),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x990A0A0B), Color(0xF20A0A0B)],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 92),
                        const SizedBox(height: 18),
                        Text('APPROVED', style: AppTextStyles.eyebrow),
                        const SizedBox(height: 12),
                        HeroTitle(
                            line1: cv('approved_line1_p1', 'Welcome to the'),
                            em: cv('approved_line1_p2', 'SM Royal Circle.'),
                            size: 31),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 26,
                  right: 26,
                  bottom: 44,
                  child: GoldButton('Create Profile', onTap: () => context.push('/profile-completion-2')),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════ Not Approved ═══════════════════════
class NotApprovedScreen extends ConsumerWidget {
  final String? refNo;
  const NotApprovedScreen({super.key, this.refNo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(screenCopyProvider).maybeWhen(data: (c) => c, orElse: () => const {});
    String cv(String k, String fb) { final v = copy[k]?.toString() ?? ''; return v.isNotEmpty ? v : fb; }
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line)),
                      child: const Icon(Icons.info_outline, color: AppColors.muted, size: 24),
                    ),
                    const SizedBox(height: 26),
                    Text('DECISION',
                        style: AppTextStyles.inter(
                            size: 9.5, weight: FontWeight.w600, color: AppColors.muted2, letterSpacing: 3)),
                    const SizedBox(height: 12),
                    Text(cv('notapp_title', 'Not approved\nat this time.'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.serif(size: 28, color: const Color(0xFFE9E7E1), height: 1.12)),
                    const SizedBox(height: 14),
                    Text(
                        cv('notapp_body',
                            'Thank you for your interest in SM Royal Circle. Membership is limited and the Society is unable to extend an invitation right now. You are welcome to apply again in the future.'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inter(
                            size: 12.5, weight: FontWeight.w300, color: AppColors.muted, height: 1.7)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              bottom: 46,
              child: Column(
                children: [
                  GoldButton(cv('notapp_cta', 'Reapply Later'), style: GoldBtnStyle.ghost, onTap: () => context.go('/welcome')),
                  const SizedBox(height: 12),
                  Text('REF. ${refNo ?? '\u2014'}',
                      style: AppTextStyles.inter(size: 10, color: AppColors.muted2, letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════ Profile Completion (invitation + post-approval) ═══════════════
class ProfileCompletionScreen extends ConsumerStatefulWidget {
  /// invitation=true shows the green "Invitation verified" banner.
  final bool invitation;
  const ProfileCompletionScreen({super.key, this.invitation = false});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final _bio = TextEditingController();
  final _industry = TextEditingController();
  final _location = TextEditingController();
  final _instagram = TextEditingController();
  final _otherInterest = TextEditingController();
  final Set<String> _selectedInterests = {};
  bool _otherActive = false;
  bool _busy = false;
  String? _error;
  File? _pickedPhoto;
  bool _uploadingPhoto = false;

  // Same curated list Edit Profile and the admin panel use.
  static const _interestOptions = [
    'Arts & Culture', 'Business & Finance', 'Dining & Gastronomy', 'Fashion & Style',
    'Film & Theatre', 'Fitness & Wellness', 'Golf', 'Hospitality & Events',
    'Motorsport', 'Music', 'Philanthropy', 'Real Estate', 'Sport', 'Technology',
    'Travel & Adventure', 'Wine & Spirits',
  ];

  @override
  void initState() {
    super.initState();
    final m = ref.read(currentMemberProvider);
    if (m != null) {
      _bio.text = m.bio;
      _industry.text = m.industry;
      _location.text = m.location;
      _instagram.text = m.instagram;
      _selectedInterests.addAll(m.interests);
      // Anything already saved that isn't one of the curated chips is a
      // previously-typed custom interest — surface it in the Other field
      // instead of silently dropping it (it wouldn't render as a chip
      // otherwise, since it has no match in _interestOptions).
      final custom = m.interests.where((i) => !_interestOptions.contains(i)).toList();
      if (custom.isNotEmpty) {
        _otherActive = true;
        _otherInterest.text = custom.first;
        _selectedInterests.removeWhere((i) => !_interestOptions.contains(i));
      }
    }
  }

  @override
  void dispose() {
    _bio.dispose();
    _industry.dispose();
    _location.dispose();
    _instagram.dispose();
    _otherInterest.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _pickedPhoto = File(picked.path);
      _uploadingPhoto = true;
    });
    try {
      final bytes = await picked.readAsBytes();
      await ref.read(repoProvider).uploadProfilePhoto(bytes);
      // Refresh the member so the new portrait carries through to the rest
      // of the app once profile completion finishes.
      final me = await ref.read(repoProvider).me();
      ref.read(currentMemberProvider.notifier).state = me;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Portrait added.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e).display)));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    final otherText = _otherInterest.text.trim();
    final hasOther = _otherActive && otherText.isNotEmpty;
    final hasPhoto = _pickedPhoto != null || (ref.read(currentMemberProvider)?.avatarUrl ?? '').isNotEmpty;
    final missing = <String>[];
    if (!hasPhoto) missing.add('Profile photo');
    if (_bio.text.trim().isEmpty) missing.add('Bio');
    if (_industry.text.trim().isEmpty) missing.add('Industry');
    if (_location.text.trim().isEmpty) missing.add('Location');
    if (_instagram.text.trim().isEmpty) missing.add('Instagram');
    if (_selectedInterests.isEmpty && !hasOther) missing.add('At least one interest');
    if (missing.isNotEmpty) {
      setState(() => _error = '${missing.join(', ')} ${missing.length == 1 ? 'is' : 'are'} required.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(repoProvider).updateProfile(
            bio: _bio.text.trim(),
            industry: _industry.text.trim(),
            city: _location.text.trim(),
            instagram: _instagram.text.trim(),
            interests: [..._selectedInterests, if (hasOther) otherText],
          );
      // Refresh the member so the rest of the app has the completed profile.
      try {
        final me = await ref.read(repoProvider).me();
        ref.read(currentMemberProvider.notifier).state = me;
      } catch (_) {/* keep whatever was cached; route conservatively below */}
      final me = ref.read(currentMemberProvider);
      if (mounted) context.go(me != null ? memberHomeRoute(me) : '/membership-locked');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not save your profile. ' + describeError(e).display);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(String label, TextEditingController c, String hint, {int maxLines = 1}) =>
      LabeledField(label: label, controller: c, hint: hint, maxLines: maxLines);

  @override
  Widget build(BuildContext context) {
    // Mandatory step after approval — no way back, no way to skip. The member
    // cannot proceed into the app without completing this profile.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        appBar: AppTopNav(
          title: 'Complete Profile',
          showBack: false,
          trailing: Text('REQUIRED', style: AppTextStyles.eyebrow),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 22),
          child: Column(
            children: [
              if (widget.invitation) ...[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  borderColor: AppColors.success.withValues(alpha: .4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Invitation verified. No Society review needed \u2014 just finish your profile.',
                            style: AppTextStyles.inter(
                                size: 11.5, weight: FontWeight.w300, color: const Color(0xFFE9E7E1))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  borderColor: AppColors.gold.withValues(alpha: .35),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'One last step \u2014 complete your profile to continue into SM Royal Circle.',
                            style: AppTextStyles.inter(
                                size: 11.5, weight: FontWeight.w300, color: const Color(0xFFE9E7E1))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Builder(builder: (context) {
                final m = ref.watch(currentMemberProvider);
                return Column(
                  children: [
                    InkWell(
                      onTap: _pickPhoto,
                      customBorder: const CircleBorder(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _pickedPhoto != null
                              ? Container(
                                  width: 84,
                                  height: 84,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.gold, width: 1.6)),
                                  child: ClipOval(child: Image.file(_pickedPhoto!, fit: BoxFit.cover)),
                                )
                              : RingAvatar(
                                  tier: m?.tier ?? MemberTier.silver,
                                  size: 84,
                                  imageUrl: m?.avatarUrl ?? '',
                                  gender: m?.gender),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.ink, width: 3)),
                              child: _uploadingPhoto
                                  ? const Padding(
                                      padding: EdgeInsets.all(7),
                                      child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2))
                                  : const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('TAP TO ADD PORTRAIT', style: AppTextStyles.eyebrow),
                  ],
                );
              }),
              const SizedBox(height: 16),
              _f('Bio', _bio, 'Creative director, collector of quiet places.', maxLines: 3),
              const SizedBox(height: 9),
              _f('Industry', _industry, 'Design & Architecture'),
              const SizedBox(height: 9),
              _f('Location', _location, 'City, Country'),
              const SizedBox(height: 9),
              _f('Instagram', _instagram, '@handle'),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: Text('INTERESTS', style: AppTextStyles.label)),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Tap to select what interests you.',
                    style: AppTextStyles.inter(size: 10.5, weight: FontWeight.w300, color: AppColors.muted2)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._interestOptions.map((opt) {
                  final sel = _selectedInterests.contains(opt);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel) {
                        _selectedInterests.remove(opt);
                      } else {
                        _selectedInterests.add(opt);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.gold.withValues(alpha: .14) : Colors.white.withValues(alpha: .02),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: sel ? AppColors.gold : AppColors.line, width: sel ? 1.3 : 1),
                      ),
                      child: Text(opt,
                          style: AppTextStyles.inter(
                              size: 11.5,
                              weight: sel ? FontWeight.w500 : FontWeight.w300,
                              color: sel ? AppColors.gold : AppColors.muted)),
                    ),
                  );
                }).toList(),
                  GestureDetector(
                    onTap: () => setState(() => _otherActive = !_otherActive),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _otherActive ? AppColors.gold.withValues(alpha: .14) : Colors.white.withValues(alpha: .02),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: _otherActive ? AppColors.gold : AppColors.line, width: _otherActive ? 1.3 : 1),
                      ),
                      child: Text('Other',
                          style: AppTextStyles.inter(
                              size: 11.5,
                              weight: _otherActive ? FontWeight.w500 : FontWeight.w300,
                              color: _otherActive ? AppColors.gold : AppColors.muted)),
                    ),
                  ),
                ],
              ),
              if (_otherActive) ...[
                const SizedBox(height: 9),
                _f('Your interest', _otherInterest, 'e.g. Sailing'),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.admin.withValues(alpha: .5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: AppTextStyles.inter(size: 11.5, color: const Color(0xFFE68688))),
                ),
              ],
              const SizedBox(height: 22),
              _busy
                  ? const Center(
                      child: SizedBox(
                          width: 26, height: 26,
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)))
                  : GoldButton(
                      widget.invitation ? 'Save & Enter the Circle' : 'Save & Continue',
                      onTap: _submit,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
