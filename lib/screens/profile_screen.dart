import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/avatars.dart';
import '../data/repository.dart';
import '../data/saved_store.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';
import 'full_screen_reel.dart';

/// Member profile — mirrors `src/app/profile/[id]/page.tsx`.
///
/// When [id] is a MongoDB id (24 hex chars) the real member is loaded from
/// `/api/family` and shown with their DB details + lineage (parent/children by
/// `parentId`). Otherwise the currently authenticated user's own profile is
/// rendered. No demo data is used.
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
  Map<String, dynamic>? _parent;
  List<Map<String, dynamic>> _children = const [];

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
      final all = await Repository.instance.familyTree();
      final member = all
          .cast<Map<String, dynamic>?>()
          .firstWhere((m) => m!['_id'].toString() == widget.id,
              orElse: () => null);
      if (member != null) {
        final parentId = (member['parentId'] ?? '').toString();
        _parent = parentId.isEmpty
            ? null
            : all.cast<Map<String, dynamic>?>().firstWhere(
                (m) => m!['_id'].toString() == parentId,
                orElse: () => null);
        _children = all
            .where((m) => (m['parentId'] ?? '').toString() == widget.id)
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _member = member;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static bool _isLate(Map<String, dynamic> m) =>
      (m['dod'] ?? '').toString().trim().isNotEmpty;

  static String _dash(Object? v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? '—' : s;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.forest700)),
      );
    }
    if (_member != null) return _dbMemberProfile(_member!);
    return _selfProfile();
  }

  // ── DB member profile ──────────────────────────────────────────────────────
  Widget _dbMemberProfile(Map<String, dynamic> m) {
    final isLate = _isLate(m);
    final gen = ((m['generation'] ?? 1) as num).toInt();
    final branch = _dash(m['branch']);
    final relation = 'Gen $gen · $branch Branch';
    final notes = (m['notes'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            name: _dash(m['name']),
            relation: relation,
            gotra: _dash(m['gotra']),
            native: _dash(m['native']),
            avatarUrl: '',
            photoPath: '',
            photoUrl: (m['photoUrl'] ?? '').toString(),
            isLate: isLate,
            verified: !isLate,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _aboutCard(_dash(m['occupation']), _dash(m['dob']),
                    isLate ? 'Late' : 'Active'),
                const SizedBox(height: 16),
                _lineageCard(_parent, _children),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _archiveCard(notes),
                ],
                const SizedBox(height: 16),
                _statsCard(_dash(m['gotra']), _dash(m['native']),
                    isLate ? 'Late' : 'Active'),
                const SizedBox(height: 24),
                ForestButton(
                  label: 'View in Family Tree',
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
    final user = context.watch<AuthService>().user;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please sign in to view your profile.',
                  style: body(14, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              ForestButton(
                  label: 'Go to Login',
                  onPressed: () => context.go('/login')),
            ],
          ),
        ),
      );
    }

    final archive = user.bio.trim();
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            name: user.name,
            relation: user.isElder ? 'Elder & Samaj Admin' : 'Samaj Member',
            gotra: _dash(user.gotra),
            native: _dash(user.native),
            avatarUrl: avatarUrl(user.avatar),
            photoPath: user.photoPath,
            photoUrl: user.photoUrl,
            isLate: false,
            verified: user.verified,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user.verified) ...[
                  _aadhaarVerifiedCard(user.maskedAadhaar),
                  const SizedBox(height: 16),
                ],
                _aboutCard('—', _dash(user.dob.isEmpty ? null : user.dob),
                    'Active'),
                if (archive.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _archiveCard(archive),
                ],
                const SizedBox(height: 16),
                _statsCard(_dash(user.gotra), _dash(user.native), 'Active'),
                const SizedBox(height: 16),
                const _SavedCard(),
                const SizedBox(height: 24),
                ForestButton(
                  label: 'Edit Profile',
                  icon: Icons.edit_outlined,
                  expand: true,
                  onPressed: () => context.push('/profile/edit'),
                ),
                const SizedBox(height: 12),
                OutlineButtonX(
                  label: 'Matrimonial Details',
                  expand: true,
                  onPressed: () => context.push('/matrimonial/edit'),
                ),
                const SizedBox(height: 12),
                OutlineButtonX(
                  label: 'View in Family Tree',
                  expand: true,
                  onPressed: () => context.go('/family-tree'),
                ),
                const SizedBox(height: 12),
                // Optional — nothing in the app requires Aadhaar. It only
                // fills some profile fields in for you.
                OutlineButtonX(
                  label: 'Verify Identity (optional)',
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
            status == 'Late'
                ? Icons.local_florist_outlined
                : Icons.verified_user_outlined,
            'Status',
            status == 'Late' ? 'In Memoriam' : 'Active Member',
          ),
        ],
      ),
    );
  }

  Widget _lineageCard(
    Map<String, dynamic>? parent,
    List<Map<String, dynamic>> children,
  ) {
    final hasAny = parent != null || children.isNotEmpty;
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
          if (parent != null) _relationTile(parent, 'Parent'),
          for (final c in children) _relationTile(c, 'Child'),
        ],
      ),
    );
  }

  Widget _relationTile(Map<String, dynamic> m, String label) {
    final mid = m['_id'].toString();
    final late = _isLate(m);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/profile/$mid'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            PexelsImage(
              url: (m['photoUrl'] ?? '').toString(),
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
                  Text('${late ? 'Late ' : ''}${m['name']}',
                      style: body(14,
                          weight: FontWeight.w600, color: AppColors.ink)),
                  Text(
                      '$label · Gen ${((m['generation'] ?? 1) as num).toInt()}',
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
              _stat('Standing', status == 'Late' ? 'Ancestor' : 'Member'),
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
            Text(label, style: body(10, color: AppColors.textMuted)),
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
    // Prefer the uploaded (remote) photo, then a local selfie file, then
    // initials (via PexelsImage's fallback on an empty/avatar URL).
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
          Text(relation, style: body(13, color: AppColors.forest300)),
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
        final items = SavedStore.instance.items;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark_rounded,
                      size: 18, color: AppColors.gold700),
                  const SizedBox(width: 8),
                  Text('Saved', style: display(18, color: AppColors.forest900)),
                  const Spacer(),
                  if (items.isNotEmpty)
                    Text('${items.length}',
                        style: body(13,
                            weight: FontWeight.w700,
                            color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No saved posts yet. Tap the bookmark on any reel or post '
                    'to keep it here.',
                    style: body(13, color: AppColors.textMuted, height: 1.4),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.72,
                  children: [
                    for (final item in items) _SavedTile(item: item),
                  ],
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
    Navigator.of(context).push(PageRouteBuilder(
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
    ));
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
              Image.network(item.mediaUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.forest900,
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white54, size: 24)))
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
                child: Text(item.emoji,
                    style: const TextStyle(fontSize: 34)),
              ),
            ],
            // Reel play badge (top-left)
            if (item.isReel)
              const Positioned(
                top: 6,
                left: 6,
                child: Icon(Icons.play_circle_fill_rounded,
                    size: 18, color: Colors.white),
              ),
            // Un-save (top-right)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => SavedStore.instance.remove(item.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.bookmark_rounded,
                      size: 18, color: AppColors.gold500),
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
                child: Text(item.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(10,
                        weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
