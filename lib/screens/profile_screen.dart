import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/avatars.dart';
import '../data/follow_events.dart';
import '../data/repository.dart';
import '../data/saved_store.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';
import 'full_screen_reel.dart';

/// Member profile — mirrors `src/app/profile/[id]/page.tsx`.
///
/// When [id] is a MongoDB id (24 hex chars) it is read as a family member record
/// (`GET /api/family/:id`), shown with how they relate to me
/// (`GET /api/family/relations/:id`) and their immediate relations (the direct
/// nodes of `GET /api/family/tree?rootMemberId=:id`). A member linked to a real
/// account also pulls that account in for its gotra / native / occupation.
/// Otherwise the currently authenticated user's own profile is rendered. No demo
/// data is used.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.id});

  final String id;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

bool _isMongoId(String id) => RegExp(r'^[a-f0-9]{24}$').hasMatch(id);

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;
  Map<String, dynamic>? _member;

  /// The account behind [_member], when it has one — the member record itself
  /// carries no gotra / native / occupation.
  Map<String, dynamic>? _account;

  /// `{related, relation, generation, path, …}` for this member as seen from me.
  Map<String, dynamic>? _relation;

  /// This member's own immediate family (`distance == 1` in their tree).
  List<Map<String, dynamic>> _immediate = const [];

  @override
  void initState() {
    super.initState();
    if (_isMongoId(widget.id)) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final member = await Repository.instance.familyMemberById(widget.id);
      // Everything below only enriches the page — a failure must not cost us the
      // member we already have.
      Map<String, dynamic>? account;
      Map<String, dynamic>? relation;
      var immediate = const <Map<String, dynamic>>[];
      final linkedUserId = (member['linkedUserId'] ?? '').toString();
      if (linkedUserId.isNotEmpty) {
        try {
          account = await Repository.instance.userById(linkedUserId);
        } catch (_) {
          /* best-effort */
        }
      }
      try {
        relation = await Repository.instance.familyRelation(widget.id);
      } catch (_) {
        /* best-effort */
      }
      try {
        final tree = await Repository.instance.familyTree(
          rootMemberId: widget.id,
          maxNodes: 200,
        );
        final nodes = tree['nodes'];
        if (nodes is List) {
          immediate = nodes
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              // distance 1 is exactly the seven stored relations — parents,
              // siblings, spouse and children — and nothing derived.
              .where((n) => ((n['distance'] ?? 0) as num).toInt() == 1)
              .toList();
        }
      } catch (_) {
        /* best-effort */
      }
      if (!mounted) return;
      setState(() {
        _member = member;
        _account = account;
        _relation = relation;
        _immediate = immediate;
        _loading = false;
      });
    } catch (_) {
      // Not a family member record (or it is gone) — fall back to the self view.
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static bool _isLate(Map<String, dynamic> m) =>
      m['status'] == 'deceased' ||
      m['deceased'] == true ||
      (m['dod'] ?? '').toString().trim().isNotEmpty;

  static String _dash(Object? v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? '-' : s;
  }

  /// Member dates come back as ISO timestamps (`1938-02-11T00:00:00.000Z`); only
  /// the day matters here.
  static String _date(Object? v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return '—';
    final t = s.indexOf('T');
    return t > 0 ? s.substring(0, t) : s;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.onBrightness(
          light: AppColors.cream,
          dark: AppColors.darkBg,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.forest700),
        ),
      );
    }
    if (_member != null) return _dbMemberProfile(_member!);
    return _selfProfile();
  }

  // ── Family member profile ──────────────────────────────────────────────────
  Widget _dbMemberProfile(Map<String, dynamic> m) {
    final t = AppLocalizations.of(context);
    final isLate = _isLate(m);
    final account = _account ?? const {};
    final rel = _relation ?? const {};
    // The relation label is derived server-side and relative to me, so it is only
    // shown for someone actually connected to my tree.
    final relation = rel['related'] == true
        ? (rel['relation'] ?? t.profileRelative).toString()
        : (m['isPlaceholder'] == true
              ? t.profilePendingInvitation
              : t.profileFamilyMember);
    final biography = (m['biography'] ?? '').toString().trim();
    final placeOfDeath = (m['placeOfDeath'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            name: _dash(m['name']),
            relation: relation,
            gotra: _dash(account['gotra']),
            native: _dash(account['native']),
            avatarUrl: '',
            photoPath: '',
            photoUrl: (m['profileUrl'] ?? '').toString(),
            isLate: isLate,
            verified: (m['linkedUserId'] ?? '').toString().isNotEmpty,
            t: t,
          ),
          // Follow stats only make sense for a member linked to a real
          // account — a placeholder/deceased member record has no followers.
          if ((m['linkedUserId'] ?? '').toString().isNotEmpty)
            _FollowStatsRow(userId: (m['linkedUserId'] ?? '').toString()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _aboutCard(
                  _dash(account['occupation']),
                  _date(m['dob']),
                  isLate ? 'Late' : 'Active',
                ),
                if (isLate) ...[
                  const SizedBox(height: 16),
                  _memoriamCard(_date(m['dod']), placeOfDeath),
                ],
                const SizedBox(height: 16),
                _lineageCard(_immediate),
                if (biography.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _archiveCard(biography),
                ],
                const SizedBox(height: 16),
                _statsCard(
                  _dash(account['gotra']),
                  _dash(account['native']),
                  isLate ? 'Late' : 'Active',
                ),
                const SizedBox(height: 24),
                ForestButton(
                  label: t.profileViewInFamilyTree,
                  icon: Icons.account_tree_outlined,
                  expand: true,
                  onPressed: () => context.go('/family-tree'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Current-user (self) profile ─────────────────────────────────────────────
  Widget _selfProfile() {
    final t = AppLocalizations.of(context);
    final user = context.watch<AuthService>().user;
    if (user == null) {
      return Scaffold(
        backgroundColor: context.onBrightness(
          light: AppColors.cream,
          dark: AppColors.darkBg,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.profilePleaseSignIn,
                style: body(
                  14,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ForestButton(
                label: t.profileGoToLogin,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      );
    }

    final archive = user.bio.trim();
    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            name: user.name,
            relation: user.isElder ? t.profileElderAdmin : t.profileSamajMember,
            gotra: _dash(user.gotra),
            native: _dash(user.native),
            avatarUrl: avatarUrl(user.avatar),
            photoPath: user.photoPath,
            photoUrl: user.photoUrl,
            isLate: false,
            verified: user.verified,
            t: t,
          ),
          _FollowStatsRow(userId: user.id, showPosts: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user.verified) ...[
                  _aadhaarVerifiedCard(user.maskedAadhaar),
                  const SizedBox(height: 16),
                ],
                _aboutCard(
                  _dash(user.occupation),
                  _dash(user.dob.isEmpty ? null : user.dob),
                  'Active',
                  samajId: user.samajId,
                ),
                if (archive.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _archiveCard(archive),
                ],
                const SizedBox(height: 16),
                _statsCard(_dash(user.gotra), _dash(user.native), 'Active'),
                const SizedBox(height: 16),
                const _PhonePrivacyCard(),
                const SizedBox(height: 16),
                const _AppearanceCard(),
                const SizedBox(height: 16),
                const _SavedCard(),
                const SizedBox(height: 24),
                ForestButton(
                  label: t.profileEditProfile,
                  icon: Icons.edit_outlined,
                  expand: true,
                  onPressed: () => context.push('/profile/edit'),
                ),
                const SizedBox(height: 12),
                // A married member has no use for this — the matrimonial hub
                // itself is already hidden from them (see AppShell), and its
                // eligibility gate refuses them outright regardless.
                if (user.maritalStatus != 'married') ...[
                  OutlineButtonX(
                    label: t.profileMatrimonialDetails,
                    expand: true,
                    onPressed: () => context.push('/matrimonial/edit'),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlineButtonX(
                  label: t.profileViewInFamilyTree,
                  expand: true,
                  onPressed: () => context.go('/family-tree'),
                ),
                const SizedBox(height: 12),
                // Optional — nothing in the app requires Aadhaar. It only
                // fills some profile fields in for you.
                OutlineButtonX(
                  label: t.profileVerifyIdentityOptional,
                  expand: true,
                  color: AppColors.gold700,
                  onPressed: () => context.push('/profile/verify'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aadhaarVerifiedCard(String maskedAadhaar) {
    final t = AppLocalizations.of(context);
    return AppCard(
      color: const Color(0xFFF0FBF4),
      border: true,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppGradients.forest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t.profileAadhaarVerified,
                      style: display(16, color: AppColors.forest900),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.forest700,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  maskedAadhaar.isEmpty
                      ? t.profileVerifiedViaDigilocker
                      : t.profileViaDigilockerMasked(maskedAadhaar),
                  style: body(12, color: AppColors.forest700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(
    String occupation,
    String birthYear,
    String status, {
    String samajId = '',
  }) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.work_outline,
                size: 18,
                color: context.onBrightness(
                  light: AppColors.gold700,
                  dark: AppColors.goldSoft,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.profileAboutOccupation,
                style: display(
                  18,
                  color: context.onBrightness(
                    light: AppColors.forest900,
                    dark: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (samajId.isNotEmpty) ...[
            _samajRow(samajId),
            Divider(
              height: 22,
              color: context.onBrightness(
                light: AppColors.creamDark,
                dark: AppColors.darkBorder,
              ),
            ),
          ],
          _detailRow(Icons.badge_outlined, t.profileOccupation, occupation),
          Divider(
            height: 22,
            color: context.onBrightness(
              light: AppColors.creamDark,
              dark: AppColors.darkBorder,
            ),
          ),
          _detailRow(Icons.cake_outlined, t.profileBirthYear, birthYear),
          Divider(
            height: 22,
            color: context.onBrightness(
              light: AppColors.creamDark,
              dark: AppColors.darkBorder,
            ),
          ),
          _detailRow(
            status == 'Late'
                ? Icons.local_florist_outlined
                : Icons.verified_user_outlined,
            t.profileStatus,
            status == 'Late' ? t.profileInMemoriam : t.profileActiveMember,
          ),
        ],
      ),
    );
  }

  /// In memoriam details, which only a deceased member record carries.
  Widget _memoriamCard(String dod, String placeOfDeath) {
    final t = AppLocalizations.of(context);
    return AppCard(
      color: const Color(0xFFF3F4F6),
      border: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_florist_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                t.profileInMemoriam,
                style: display(18, color: AppColors.forest900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            [
              if (dod != '—') t.profilePassedAway(dod),
              if (placeOfDeath.isNotEmpty) t.profileAt(placeOfDeath),
            ].join(' '),
            style: body(13, color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  /// This member's own immediate family — the seven stored relations, labelled as
  /// the server derives them from *their* viewpoint.
  Widget _lineageCard(List<Map<String, dynamic>> immediate) {
    final t = AppLocalizations.of(context);
    final hasAny = immediate.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 18,
                    color: context.onBrightness(
                      light: AppColors.forest700,
                      dark: AppColors.forest300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.profileFamilyRelations,
                    style: display(
                      18,
                      color: context.onBrightness(
                        light: AppColors.forest900,
                        dark: AppColors.darkText,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go('/family-tree'),
                child: Text(
                  t.profileFullTree,
                  style: body(
                    12,
                    weight: FontWeight.w600,
                    color: context.onBrightness(
                      light: AppColors.forest800,
                      dark: AppColors.forest300,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAny)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                t.profileNoConnectedRelations,
                style: body(
                  13,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
            ),
          for (final r in immediate) _relationTile(r),
        ],
      ),
    );
  }

  /// One tree node from [_immediate]: `id` (not `_id`), the derived `relation`
  /// and `profileUrl`.
  Widget _relationTile(Map<String, dynamic> m) {
    final t = AppLocalizations.of(context);
    final mid = (m['id'] ?? '').toString();
    final late = _isLate(m);
    final label = (m['relation'] ?? '').toString().trim();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: mid.isEmpty ? null : () => context.push('/profile/$mid'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            PexelsImage(
              url: (m['profileUrl'] ?? '').toString(),
              name: (m['name'] ?? '').toString(),
              size: 44,
              borderColor: AppColors.border,
              borderWidth: 2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${late ? "${t.profileLate} " : ""}${m['name']}',
                    style: body(
                      14,
                      weight: FontWeight.w600,
                      color: context.onBrightness(
                        light: AppColors.ink,
                        dark: AppColors.darkText,
                      ),
                    ),
                  ),
                  Text(
                    [
                      label.isEmpty ? t.profileRelative : label,
                      if (m['isPlaceholder'] == true) t.profileNotJoinedYet,
                    ].join(' · '),
                    style: body(
                      11,
                      color: context.onBrightness(
                        light: AppColors.textMuted,
                        dark: AppColors.darkTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: context.onBrightness(
                light: AppColors.hint,
                dark: AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _archiveCard(String archive) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                size: 18,
                color: context.onBrightness(
                  light: AppColors.gold700,
                  dark: AppColors.goldSoft,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.profileLifeArchive,
                style: display(
                  18,
                  color: context.onBrightness(
                    light: AppColors.forest900,
                    dark: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(left: 14),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.gold700, width: 4),
              ),
            ),
            child: Text(
              '“$archive”',
              style: display(
                14,
                weight: FontWeight.w400,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
                height: 1.6,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(String gotra, String native, String status) {
    final t = AppLocalizations.of(context);
    return AppCard(
      color: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.profileQuickStats,
            style: display(
              16,
              color: context.onBrightness(
                light: AppColors.forest900,
                dark: AppColors.darkText,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(t.profileGotra, gotra),
              _stat(t.profileNative, native.split(',').first.trim()),
              _stat(
                t.profileStanding,
                status == 'Late' ? t.profileAncestor : t.profileMember,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: context.onBrightness(
            light: Colors.white,
            dark: AppColors.darkBg,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.onBrightness(
              light: AppColors.border,
              dark: AppColors.darkBorder,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: body(
                10,
                color: context.onBrightness(
                  light: AppColors.textMuted,
                  dark: AppColors.darkTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body(
                13,
                weight: FontWeight.w700,
                color: context.onBrightness(
                  light: AppColors.forest800,
                  dark: AppColors.forest300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Samaj ID row for the About card — like [_detailRow] but with a trailing
  /// one-tap copy, since this is the number relatives search by to connect.
  Widget _samajRow(String samajId) {
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.badge_outlined,
          size: 16,
          color: context.onBrightness(
            light: AppColors.gold700,
            dark: AppColors.goldSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.profileSamajId,
                style: body(
                  11,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                samajId,
                style: body(
                  14,
                  weight: FontWeight.w700,
                  color: context.onBrightness(
                    light: AppColors.forest800,
                    dark: AppColors.forest300,
                  ),
                ).copyWith(letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: samajId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.profileSamajIdCopied(samajId)),
                backgroundColor: AppColors.forest800,
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.copy_rounded,
              size: 18,
              color: context.onBrightness(
                light: AppColors.forest700,
                dark: AppColors.forest300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: context.onBrightness(
            light: AppColors.gold700,
            dark: AppColors.goldSoft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: body(
                  11,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: body(
                  14,
                  weight: FontWeight.w600,
                  color: context.onBrightness(
                    light: AppColors.ink,
                    dark: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Forest-gradient header with back button, big avatar, name, pills + badge.
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.relation,
    required this.gotra,
    required this.native,
    required this.avatarUrl,
    required this.photoPath,
    required this.photoUrl,
    required this.isLate,
    required this.verified,
    required this.t,
  });

  final String name;
  final String relation;
  final String gotra;
  final String native;
  final String avatarUrl;
  final String photoPath;
  final String photoUrl;
  final bool isLate;
  final bool verified;
  final AppLocalizations t;

  Widget _avatar() {
    // Prefer the uploaded (remote) photo, then a local selfie file, then
    // initials (via PexelsImage's fallback on an empty/avatar URL).
    if (photoUrl.isNotEmpty) {
      return PexelsImage(url: photoUrl, name: name, size: 104);
    }
    if (photoPath.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(photoPath),
          width: 104,
          height: 104,
          fit: BoxFit.cover,
        ),
      );
    }
    return PexelsImage(url: avatarUrl, name: name, size: 104);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.deepForest),
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 28),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold500, width: 4),
                ),
                child: isLate
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.6,
                          0.3,
                          0.1,
                          0,
                          0,
                          0.6,
                          0.3,
                          0.1,
                          0,
                          0,
                          0.6,
                          0.3,
                          0.1,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: _avatar(),
                      )
                    : _avatar(),
              ),
              if (verified)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.gold500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLate)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                t.profileInMemoriam,
                style: body(
                  11,
                  weight: FontWeight.w600,
                  color: AppColors.forest300,
                ),
              ),
            ),
          Text(
            '${isLate ? "${t.profileLate} " : ""}$name',
            textAlign: TextAlign.center,
            style: display(24, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(relation, style: body(13, color: AppColors.forest300)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Pill(
                gotra,
                icon: Icons.spa_outlined,
                bg: Colors.white.withValues(alpha: 0.14),
                fg: Colors.white,
              ),
              Pill(
                native.split(',').first.trim(),
                icon: Icons.place_outlined,
                bg: Colors.white.withValues(alpha: 0.14),
                fg: Colors.white,
              ),
              if (verified)
                Pill(
                  t.profileVerifiedPill,
                  icon: Icons.verified,
                  bg: AppColors.gold500.withValues(alpha: 0.25),
                  fg: AppColors.goldSoft,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Follower / following counts shown right below the profile header. Tapping
/// either opens the matching list in a bottom sheet. Counts and lists come
/// from `GET /follow-users/followers|following/:userId` (see
/// [Repository.followers] / [Repository.following]).
class _FollowStatsRow extends StatefulWidget {
  const _FollowStatsRow({required this.userId, this.showPosts = false});

  final String userId;

  /// Adds a third "Posts" stat backed by `GET /api/posts/my-posts` — that
  /// endpoint is scoped to the signed-in member via the bearer token (no
  /// userId param), so this only makes sense on the viewer's own profile.
  final bool showPosts;

  @override
  State<_FollowStatsRow> createState() => _FollowStatsRowState();
}

class _FollowStatsRowState extends State<_FollowStatsRow> {
  bool _loading = true;
  int _followers = 0;
  int _following = 0;
  int _posts = 0;
  StreamSubscription<FollowChange>? _followSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Keeps this stat row live for as long as it's mounted, even when the
    // follow/unfollow that changed it happened on a different, earlier-
    // pushed route (e.g. this profile was reached via push, then covered by
    // another profile where Follow was tapped) — otherwise it only ever
    // shows the count fetched once at mount.
    _followSub = FollowEvents.stream.listen((e) {
      if (!mounted) return;
      final delta = e.following ? 1 : -1;
      if (e.followerId == widget.userId) {
        setState(() => _following += delta);
      }
      if (e.followingId == widget.userId) {
        setState(() => _followers += delta);
      }
    });
  }

  @override
  void dispose() {
    _followSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.userId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final futures = <Future<dynamic>>[
        Repository.instance.followCounts(widget.userId),
        if (widget.showPosts) Repository.instance.myPosts(limit: 1),
      ];
      final results = await Future.wait(futures);
      if (!mounted) return;
      final counts = results[0] as ({int followers, int following});
      setState(() {
        _followers = counts.followers;
        _following = counts.following;
        if (widget.showPosts) {
          final page = results[1] as Map<String, dynamic>;
          final count = page['count'];
          _posts = count is num
              ? count.toInt()
              : (page['posts'] as List? ?? const []).length;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openList(_FollowListMode mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowListSheet(userId: widget.userId, mode: mode),
    );
  }

  void _openMyPosts() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _MyPostsScreen()));
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: context.onBrightness(
        light: AppColors.border,
        dark: AppColors.darkBorder,
      ),
    );
  }

  Widget _stat(String label, int count, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                _loading ? '—' : '$count',
                style: display(
                  18,
                  color: context.onBrightness(
                    light: AppColors.forest900,
                    dark: AppColors.darkText,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: body(
                  12,
                  color: context.onBrightness(
                    light: AppColors.textMuted,
                    dark: AppColors.darkTextMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: context.onBrightness(
          light: Colors.white,
          dark: AppColors.darkSurface,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.onBrightness(
            light: AppColors.border,
            dark: AppColors.darkBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          _stat(
            'Followers',
            _followers,
            onTap: widget.userId.isEmpty
                ? null
                : () => _openList(_FollowListMode.followers),
          ),
          _divider(),
          _stat(
            'Following',
            _following,
            onTap: widget.userId.isEmpty
                ? null
                : () => _openList(_FollowListMode.following),
          ),
          if (widget.showPosts) ...[
            _divider(),
            _stat('Posts', _posts, onTap: _openMyPosts),
          ],
        ],
      ),
    );
  }
}

enum _FollowListMode { followers, following }

/// Bottom sheet listing either side of [_FollowStatsRow]. Each relation
/// document comes back with the other user either populated as a map
/// (`{_id, userName, profileUrl}`) or as a bare id string, matching the same
/// `userId` shape `_Post.fromBackend` already handles for feed posts — a bare
/// id falls back to [Repository.userById].
class _FollowListSheet extends StatefulWidget {
  const _FollowListSheet({required this.userId, required this.mode});

  final String userId;
  final _FollowListMode mode;

  @override
  State<_FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<_FollowListSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _people = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rels = widget.mode == _FollowListMode.followers
          ? await Repository.instance.followers(widget.userId)
          : await Repository.instance.following(widget.userId);
      final key = widget.mode == _FollowListMode.followers
          ? 'followerId'
          : 'followingId';
      final people = <Map<String, dynamic>>[];
      for (final rel in rels) {
        final field = rel[key];
        if (field is Map) {
          people.add(Map<String, dynamic>.from(field));
          continue;
        }
        final id = (field ?? '').toString();
        if (id.isEmpty) continue;
        try {
          people.add(await Repository.instance.userById(id));
        } catch (_) {
          /* skip a member we can no longer resolve */
        }
      }
      if (!mounted) return;
      setState(() {
        _people = people;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == _FollowListMode.followers
        ? 'Followers'
        : 'Following';
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.onBrightness(
              light: AppColors.cream,
              dark: AppColors.darkBg,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: display(
                    18,
                    color: context.onBrightness(
                      light: AppColors.forest900,
                      dark: AppColors.darkText,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.forest700,
                        ),
                      )
                    : _people.isEmpty
                    ? Center(
                        child: Text(
                          widget.mode == _FollowListMode.followers
                              ? 'No followers yet'
                              : 'Not following anyone yet',
                          style: body(
                            13,
                            color: context.onBrightness(
                              light: AppColors.textMuted,
                              dark: AppColors.darkTextMuted,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _people.length,
                        itemBuilder: (context, i) {
                          final p = _people[i];
                          final id = (p['_id'] ?? p['id'] ?? '').toString();
                          final name = (p['userName'] ?? p['name'] ?? '')
                              .toString();
                          final photo = (p['profileUrl'] ?? p['photoUrl'] ?? '')
                              .toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: PexelsImage(
                              url: photo,
                              name: name,
                              size: 44,
                            ),
                            title: Text(
                              name.isEmpty ? 'Samaj member' : name,
                              style: body(
                                14,
                                weight: FontWeight.w600,
                                color: context.onBrightness(
                                  light: AppColors.ink,
                                  dark: AppColors.darkText,
                                ),
                              ),
                            ),
                            onTap: id.isEmpty
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    context.push('/profile/$id');
                                  },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full list of the signed-in member's own posts, opened from the "Posts"
/// stat. Pages through `GET /api/posts/my-posts?limit=10&after=<lastId>` —
/// [after] is the `_id` of the last post already on screen, so scrolling to
/// the bottom just re-requests with that id as the cursor.
class _MyPostsScreen extends StatefulWidget {
  const _MyPostsScreen();

  @override
  State<_MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<_MyPostsScreen> {
  static const _pageSize = 10;

  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Repository.instance.myPosts(limit: _pageSize);
      final posts = (data['posts'] as List? ?? const [])
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
        _hasMore = posts.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load your posts';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_posts.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final lastId = (_posts.last['_id'] ?? '').toString();
      final data = await Repository.instance.myPosts(
        limit: _pageSize,
        after: lastId,
      );
      final posts = (data['posts'] as List? ?? const [])
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();
      if (!mounted) return;
      setState(() {
        _posts.addAll(posts);
        _hasMore = posts.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      // Best-effort — leave what's already loaded on screen and let the
      // next scroll-to-bottom retry.
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.onBrightness(
        light: AppColors.cream,
        dark: AppColors.darkBg,
      ),
      appBar: AppBar(
        title: const Text('My Posts'),
        backgroundColor: context.onBrightness(
          light: AppColors.cream,
          dark: AppColors.darkBg,
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.forest700),
            )
          : _error != null
          ? Center(
              child: Text(_error!, style: body(13, color: AppColors.textMuted)),
            )
          : _posts.isEmpty
          ? Center(
              child: Text(
                'No posts yet',
                style: body(13, color: AppColors.textMuted),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFirstPage,
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i >= _posts.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.forest700,
                        ),
                      ),
                    );
                  }
                  return _MyPostTile(post: _posts[i]);
                },
              ),
            ),
    );
  }
}

class _MyPostTile extends StatelessWidget {
  const _MyPostTile({required this.post});

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final urls = post['mediaUrls'];
    final mediaUrl = urls is List && urls.isNotEmpty
        ? urls.first.toString()
        : '';
    final isVideo = (post['postType'] ?? '').toString() == 'video';
    final caption = (post['caption'] ?? '').toString();
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  mediaUrl.isEmpty
                      ? const ColoredBox(color: AppColors.forest900)
                      : Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: AppColors.forest900),
                        ),
                  if (isVideo)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption.isEmpty ? '(No caption)' : caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: body(
                    13,
                    weight: FontWeight.w600,
                    color: context.onBrightness(
                      light: AppColors.ink,
                      dark: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    '${(post['likeCount'] as num?)?.toInt() ?? 0} likes',
                    '${(post['commentCount'] as num?)?.toInt() ?? 0} comments',
                  ].join(' · '),
                  style: body(11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Controls whether other members can see this member's phone number.
///
/// The switch writes `showPhoneToMembers` through `PATCH /api/user/profile`.
/// The server is what actually enforces the choice — with it off, the directory
/// and `/api/user/:id` return `phone: ''`, so a hidden number is never sent to
/// another member's device rather than being sent and hidden by the app.
class _PhonePrivacyCard extends StatefulWidget {
  const _PhonePrivacyCard();

  @override
  State<_PhonePrivacyCard> createState() => _PhonePrivacyCardState();
}

class _PhonePrivacyCardState extends State<_PhonePrivacyCard> {
  bool _saving = false;

  Future<void> _toggle(AuthService auth, bool next) async {
    final user = auth.user;
    if (user == null || _saving) return;
    // Move the switch immediately, then confirm with the server. A rejected or
    // unreachable save puts it back where it was — leaving it on the new
    // position would tell the member their number is hidden when it isn't.
    setState(() => _saving = true);
    await auth.updateUser(user.copyWith(showPhoneToMembers: next));
    try {
      final saved = await Repository.instance.saveProfile(
        showPhoneToMembers: next,
      );
      // Trust the server's echo over our optimistic value.
      final confirmed = (saved['showPhoneToMembers'] ?? next) as bool;
      if (!mounted) return;
      if (confirmed != next) {
        await auth.updateUser(
          auth.user!.copyWith(showPhoneToMembers: confirmed),
        );
      }
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      await auth.updateUser(auth.user!.copyWith(showPhoneToMembers: !next));
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : AppLocalizations.of(context).profileCouldNotSave,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();
    final on = user.showPhoneToMembers;
    final t = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 18,
                color: context.onBrightness(
                  light: AppColors.gold700,
                  dark: AppColors.goldSoft,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.profilePhoneNumber,
                style: display(
                  18,
                  color: context.onBrightness(
                    light: AppColors.forest900,
                    dark: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.profileShareWithMembers,
                      style: body(
                        14,
                        weight: FontWeight.w600,
                        color: context.onBrightness(
                          light: AppColors.ink,
                          dark: AppColors.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      on ? t.profilePhoneVisibleDesc : t.profilePhoneHiddenDesc,
                      style: body(
                        12,
                        color: context.onBrightness(
                          light: AppColors.textMuted,
                          dark: AppColors.darkTextMuted,
                        ),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // The spinner replaces the switch while saving so the control
              // can't be flipped again before the first write lands.
              _saving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.forest700,
                        ),
                      ),
                    )
                  : Switch(
                      value: on,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.forest700,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: AppColors.border,
                      onChanged: (v) => _toggle(auth, v),
                    ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: on
                  ? const Color(0xFFF0FBF4)
                  : context.onBrightness(
                      light: AppColors.cream,
                      dark: AppColors.darkSurface,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.onBrightness(
                  light: AppColors.border,
                  dark: AppColors.darkBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  on ? Icons.visibility_outlined : Icons.lock_outline,
                  size: 16,
                  color: on
                      ? AppColors.forest700
                      : context.onBrightness(
                          light: AppColors.textMuted,
                          dark: AppColors.darkTextMuted,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    on
                        ? (user.phone.isEmpty
                              ? t.profileVisibleToMembers
                              : user.phone)
                        : t.profileHiddenFromMembers,
                    style: body(
                      13,
                      weight: FontWeight.w600,
                      color: on
                          ? AppColors.forest800
                          : context.onBrightness(
                              light: AppColors.textMuted,
                              dark: AppColors.darkTextMuted,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the member pick System/Light/Dark. Writes straight through
/// [ThemeService], which persists it and drives `MaterialApp`'s `themeMode`
/// — see that service's own doc comment for what does (Material's default
/// chrome) and doesn't (screens with hardcoded [AppColors]) respond yet.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final mode = context.watch<ThemeService>().mode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dark_mode_outlined,
                size: 18,
                color: context.onBrightness(
                  light: AppColors.gold700,
                  dark: AppColors.goldSoft,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.profileAppearance,
                style: display(
                  18,
                  color: context.onBrightness(
                    light: AppColors.forest900,
                    dark: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.profileAppearanceDesc,
            style: body(
              12,
              color: context.onBrightness(
                light: AppColors.textMuted,
                dark: AppColors.darkTextMuted,
              ),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(t.themeSystem),
                icon: const Icon(Icons.brightness_auto_outlined, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(t.themeLight),
                icon: const Icon(Icons.light_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(t.themeDark),
                icon: const Icon(Icons.dark_mode_outlined, size: 16),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                context.read<ThemeService>().setMode(selection.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.forest300,
              selectedForegroundColor: AppColors.forest900,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Saved" shelf on the profile — a grid of the posts/reels the user has
/// bookmarked from the feed or the full-screen reel player. Live-updates as
/// the app-wide [SavedStore] changes; tapping a saved reel re-opens it.
class _SavedCard extends StatelessWidget {
  const _SavedCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SavedStore.instance,
      builder: (context, _) {
        final t = AppLocalizations.of(context);
        final items = SavedStore.instance.items;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark_rounded,
                    size: 18,
                    color: context.onBrightness(
                      light: AppColors.gold700,
                      dark: AppColors.goldSoft,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.profileSaved,
                    style: display(
                      18,
                      color: context.onBrightness(
                        light: AppColors.forest900,
                        dark: AppColors.darkText,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (items.isNotEmpty)
                    Text(
                      '${items.length}',
                      style: body(
                        13,
                        weight: FontWeight.w700,
                        color: context.onBrightness(
                          light: AppColors.textMuted,
                          dark: AppColors.darkTextMuted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    t.profileNoSavedPostsYet,
                    style: body(
                      13,
                      color: context.onBrightness(
                        light: AppColors.textMuted,
                        dark: AppColors.darkTextMuted,
                      ),
                      height: 1.4,
                    ),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.85,
                  children: [for (final item in items) _SavedTile(item: item)],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.item});
  final SavedItem item;

  void _open(BuildContext context) {
    // Only reels re-open into the immersive player; image posts just sit in
    // the shelf. Tapping either does nothing destructive.
    if (!item.isReel || (item.mediaPath == null && item.mediaUrl == null)) {
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => FullScreenReelPage(
          path: item.mediaPath,
          url: item.mediaUrl,
          author: item.author,
          caption: item.caption,
          saved: item,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFileImage = item.mediaPath != null && !item.isReel;
    final hasUrlImage = item.mediaUrl != null && !item.isReel;
    return GestureDetector(
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasFileImage)
              Image.file(File(item.mediaPath!), fit: BoxFit.cover)
            else if (hasUrlImage)
              Image.network(
                item.mediaUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: AppColors.forest900,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 24,
                  ),
                ),
              )
            else ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.gradient,
                  ),
                ),
              ),
              Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 34)),
              ),
            ],
            // Reel play badge (top-left)
            if (item.isReel)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            // Un-save (top-right)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => SavedStore.instance.remove(item.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    size: 18,
                    color: AppColors.gold500,
                  ),
                ),
              ),
            ),
            // Author scrim
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Text(
                  item.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(10, weight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
