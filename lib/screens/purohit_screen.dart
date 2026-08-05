import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';
import 'directory_screen.dart' show openMemberChat, showMemberProfile;

/// Purohit directory — members who answered "Yes" to "Are you a purohit?"
/// at registration (GET /api/user/directory?isPurohit=true).
class PurohitScreen extends StatefulWidget {
  const PurohitScreen({super.key});

  @override
  State<PurohitScreen> createState() => _PurohitScreenState();
}

class _PurohitScreenState extends State<PurohitScreen> {
  List<Map<String, dynamic>> _purohits = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await Repository.instance.purohitDirectory();
      if (!mounted) return;
      setState(() {
        _purohits = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load purohits.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Purohit',
      currentRoute: '/purohit',
      scrollable: false,
      padding: EdgeInsets.zero,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.forest700, strokeWidth: 2))
          : _error != null
              ? _message(
                  icon: Icons.cloud_off_rounded,
                  title: "Couldn't load purohits",
                  subtitle: _error!,
                  retry: _load,
                )
              : _purohits.isEmpty
                  ? _message(
                      icon: Icons.temple_hindu_outlined,
                      title: 'No purohits yet',
                      subtitle: 'Members who mark themselves as a purohit at '
                          'registration will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.forest700,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        itemCount: _purohits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _PurohitCard(member: _purohits[i]),
                      ),
                    ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? retry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.hint),
            const SizedBox(height: 12),
            Text(title, style: display(16, color: AppColors.forest900)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: body(13, color: AppColors.textMuted)),
            if (retry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('Retry', style: body(13, weight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forest700,
                  side: const BorderSide(color: AppColors.forest700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PurohitCard extends StatelessWidget {
  const _PurohitCard({required this.member});
  final Map<String, dynamic> member;

  String _str(String k) => (member[k] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final name = _str('name');
    final gotra = _str('gotra');
    final native = _str('native');
    final sub = [
      if (gotra.isNotEmpty) '$gotra Gotra',
      if (native.isNotEmpty) native,
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => showMemberProfile(context, member),
      child: Row(
        children: [
          PexelsImage(
              url: _str('profileUrl'),
              name: name,
              size: 46,
              radius: BorderRadius.circular(12)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(14,
                              weight: FontWeight.w700,
                              color: AppColors.forest900)),
                    ),
                    if (member['verified'] == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          size: 14, color: AppColors.forest600),
                    ],
                  ],
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(12, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => openMemberChat(context, member),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FBF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: AppColors.forest700),
            ),
          ),
        ],
      ),
    );
  }
}
