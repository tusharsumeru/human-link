import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/avatars.dart';
import '../data/demo_data.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Member profile — ported from `src/app/profile/[id]/page.tsx`.
///
/// The [id] may be a [kFamilyMembers] id ("1".."6"); if no member matches we
/// fall back to the currently authenticated user mapped into a profile shape.
/// Rendered as a polished drill-down page: a forest-gradient header with a big
/// avatar + verified badge + gotra/native pills, then About, Lineage, Life
/// Archive and Quick-stats cards.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.id});

  final String id;

  // Life-archive blurbs ported verbatim from the web page's LIFE_ARCHIVES.
  static const Map<String, String> _lifeArchives = {
    '1':
        'Ramachandra Suvarna was the patriarch of our Kundapura branch and a master goldsmith. He established the family jewellery tradition in 1942 and his 47-year handwritten ledger is the foundation of our digital tree today.',
    '2':
        "Savitribai Suvarna was the matriarch renowned for her devotion to Samaj seva and Sanskrit shlokas. She organised the first Samaj women's collective in Kundapura and raised funds for the community temple.",
    '3':
        'Venkatesh Haldankar migrated from Kumta to Bengaluru in 1975 to expand the jewellery business to Commercial Street. His descendants now span Bengaluru, Mangaluru, Singapore, and Dubai.',
    '4':
        'Suresh Haldankar is the first in the family to enter software engineering — bridging the goldsmith legacy with the Bengaluru IT boom. He co-founded the Daivajna Samaja IT professionals\' network.',
    '5':
        'Rekha Diwakar is a distinguished educator and Samaj community leader. She established the Daivajna Samaja annual scholarship fund in 2008, mentoring over 300 students from the community.',
    '6':
        'Priya Haldankar represents the new generation — digitising 500+ family photos, creating this Daivajna Samaja platform, and connecting 1,400+ families across the Daivajna Samaja worldwide.',
  };

  @override
  Widget build(BuildContext context) {
    // 1. Try resolve as a family member.
    Map<String, dynamic>? member;
    for (final m in kFamilyMembers) {
      if (m['id'] == id) {
        member = m;
        break;
      }
    }

    // 2. Fall back to the current user (avatar-key based profile).
    final user = context.watch<AuthService>().user;
    final bool isCurrentUser = member == null;

    final String name = member?['name'] as String? ?? user?.name ?? 'Samaj Member';
    final String gotra = member?['gotra'] as String? ?? user?.gotra ?? '—';
    final String native = member?['native'] as String? ?? user?.native ?? 'Karnataka';
    final String relation = member?['relation'] as String? ??
        (user?.isElder == true ? 'Elder & Samaj Admin' : 'Samaj Member');
    final String occupation = member?['occupation'] as String? ?? '—';
    final String birthYear = member?['birthYear'] as String? ??
        (isCurrentUser && (user?.dob.isNotEmpty ?? false) ? user!.dob : '—');
    final String status = member?['status'] as String? ?? 'Active';
    final bool isLate = status == 'Late';

    // Aadhaar (DigiLocker) verification — for the current user.
    final bool isVerified =
        isCurrentUser ? (user?.verified ?? false) : (status == 'Active');
    final String maskedAadhaar =
        isCurrentUser ? (user?.maskedAadhaar ?? '') : '';

    // Avatar: family ids "1".."6" map directly; user uses their avatar key.
    final String? avatarKey = member != null ? id : user?.avatar;
    final String avatarUrlStr = avatarUrl(avatarKey);
    // The current user's photo: prefer the uploaded (remote) URL, fall back to
    // the locally-saved selfie file.
    final String photoPath = isCurrentUser ? (user?.photoPath ?? '') : '';
    final String photoUrl = isCurrentUser ? (user?.photoUrl ?? '') : '';

    // Lineage resolution from kFamilyMembers.
    final String? parentId = member?['parent'] as String?;
    final Map<String, dynamic>? parent =
        parentId != null ? _byId(parentId) : null;
    final children = member != null
        ? kFamilyMembers.where((m) => m['parent'] == id).toList()
        : const <Map<String, dynamic>>[];
    final String? spouseId = member?['spouse'] as String?;
    final Map<String, dynamic>? spouse =
        spouseId != null ? _byId(spouseId) : null;

    final String? archive = _lifeArchives[id] ??
        (isCurrentUser && (user?.bio.isNotEmpty ?? false) ? user!.bio : null);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            name: name,
            relation: relation,
            gotra: gotra,
            native: native,
            avatarUrl: avatarUrlStr,
            photoPath: photoPath,
            photoUrl: photoUrl,
            isLate: isLate,
            verified: isVerified,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCurrentUser && isVerified) ...[
                  _aadhaarVerifiedCard(maskedAadhaar),
                  const SizedBox(height: 16),
                ],
                _aboutCard(occupation, birthYear, status),
                const SizedBox(height: 16),
                _lineageCard(context, parent, children, spouse),
                if (archive != null) ...[
                  const SizedBox(height: 16),
                  _archiveCard(archive),
                ],
                const SizedBox(height: 16),
                _statsCard(gotra, native, status),
                const SizedBox(height: 24),
                ForestButton(
                  label: 'View in Family Tree',
                  icon: Icons.account_tree_outlined,
                  expand: true,
                  onPressed: () => context.go('/family-tree'),
                ),
                const SizedBox(height: 12),
                OutlineButtonX(
                  label: isCurrentUser
                      ? 'Verify Identity'
                      : 'Verify & Update Info',
                  expand: true,
                  color: AppColors.gold700,
                  onPressed: () => context.go('/profile/verify'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic>? _byId(String mid) {
    for (final m in kFamilyMembers) {
      if (m['id'] == mid) return m;
    }
    return null;
  }

  Widget _aadhaarVerifiedCard(String maskedAadhaar) {
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
            child: const Icon(Icons.verified_user, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Aadhaar Verified',
                        style: display(16, color: AppColors.forest900)),
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle,
                        size: 16, color: AppColors.forest700),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  maskedAadhaar.isEmpty
                      ? 'Verified via DigiLocker'
                      : 'via DigiLocker · $maskedAadhaar',
                  style: body(12, color: AppColors.forest700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(String occupation, String birthYear, String status) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline, size: 18, color: AppColors.gold700),
              const SizedBox(width: 8),
              Text('About & Occupation',
                  style: display(18, color: AppColors.forest900)),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(Icons.badge_outlined, 'Occupation', occupation),
          const Divider(height: 22, color: AppColors.creamDark),
          _detailRow(Icons.cake_outlined, 'Birth Year', birthYear),
          const Divider(height: 22, color: AppColors.creamDark),
          _detailRow(
            status == 'Late' ? Icons.local_florist_outlined : Icons.verified_user_outlined,
            'Status',
            status == 'Late' ? 'In Memoriam' : 'Active Member',
          ),
        ],
      ),
    );
  }

  Widget _lineageCard(
    BuildContext context,
    Map<String, dynamic>? parent,
    List<Map<String, dynamic>> children,
    Map<String, dynamic>? spouse,
  ) {
    final hasAny = parent != null || children.isNotEmpty || spouse != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined,
                      size: 18, color: AppColors.forest700),
                  const SizedBox(width: 8),
                  Text('Family Relations',
                      style: display(18, color: AppColors.forest900)),
                ],
              ),
              GestureDetector(
                onTap: () => context.go('/family-tree'),
                child: Text('Full Tree →',
                    style: body(12,
                        weight: FontWeight.w600, color: AppColors.forest800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAny)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No connected relations yet',
                  style: body(13, color: AppColors.textMuted)),
            ),
          if (spouse != null)
            _relationTile(context, spouse, 'Spouse'),
          if (parent != null) _relationTile(context, parent, 'Parent'),
          for (final c in children) _relationTile(context, c, 'Child'),
        ],
      ),
    );
  }

  Widget _relationTile(
      BuildContext context, Map<String, dynamic> m, String label) {
    final mid = m['id'] as String;
    final late = m['status'] == 'Late';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/profile/$mid'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AvatarImage(
              avatarKey: mid,
              name: m['name'] as String,
              size: 44,
              borderColor: AppColors.border,
              borderWidth: 2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${late ? 'Late ' : ''}${m['name']}',
                      style: body(14,
                          weight: FontWeight.w600, color: AppColors.ink)),
                  Text(label,
                      style: body(11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.hint),
          ],
        ),
      ),
    );
  }

  Widget _archiveCard(String archive) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: AppColors.gold700),
              const SizedBox(width: 8),
              Text('Life Archive',
                  style: display(18, color: AppColors.forest900)),
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
            child: Text('“$archive”',
                style: display(14,
                    weight: FontWeight.w400,
                    color: AppColors.textMuted,
                    height: 1.6)
                    .copyWith(fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(String gotra, String native, String status) {
    return AppCard(
      color: AppColors.cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Stats',
              style: display(16, color: AppColors.forest900)),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('Gotra', gotra),
              _stat('Native', native.split(',').first.trim()),
              _stat('Standing', status == 'Late' ? 'Ancestor' : 'Verified'),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(label,
                style: body(10, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(13,
                    weight: FontWeight.w700, color: AppColors.forest800)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.gold700),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: body(11, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: body(14, weight: FontWeight.w600, color: AppColors.ink)),
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

  Widget _avatar() {
    // Prefer the uploaded (remote) photo, then the local selfie, then initials.
    if (photoUrl.isNotEmpty) {
      return PexelsImage(url: photoUrl, name: name, size: 104);
    }
    if (photoPath.isNotEmpty) {
      return ClipOval(
        child: Image.file(File(photoPath),
            width: 104, height: 104, fit: BoxFit.cover),
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
          // Back row.
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
          // Avatar + verified badge.
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
                          0.6, 0.3, 0.1, 0, 0,
                          0.6, 0.3, 0.1, 0, 0,
                          0.6, 0.3, 0.1, 0, 0,
                          0, 0, 0, 1, 0,
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
                    child: const Icon(Icons.check,
                        size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLate)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('In Memoriam',
                  style: body(11,
                      weight: FontWeight.w600, color: AppColors.forest300)),
            ),
          Text('${isLate ? 'Late ' : ''}$name',
              textAlign: TextAlign.center,
              style: display(24, color: Colors.white)),
          const SizedBox(height: 4),
          Text(relation,
              style: body(13, color: AppColors.forest300)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Pill(gotra,
                  icon: Icons.spa_outlined,
                  bg: Colors.white.withValues(alpha: 0.14),
                  fg: Colors.white),
              Pill(native.split(',').first.trim(),
                  icon: Icons.place_outlined,
                  bg: Colors.white.withValues(alpha: 0.14),
                  fg: Colors.white),
              if (verified)
                Pill('Verified',
                    icon: Icons.verified,
                    bg: AppColors.gold500.withValues(alpha: 0.25),
                    fg: AppColors.goldSoft),
            ],
          ),
        ],
      ),
    );
  }
}