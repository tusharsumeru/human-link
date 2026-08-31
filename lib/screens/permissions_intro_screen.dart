import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Shown exactly once, right after the app's very first launch (before
/// login/landing) — asks for media, notification, and location access
/// together so the OS prompts are front-loaded instead of interrupting the
/// user mid-task later. [onDone] is called once the user has been through
/// every permission, whether they granted or denied each one — this screen
/// never blocks getting into the app, and a denial here doesn't stop a
/// feature from asking again contextually later (e.g. the "use my current
/// location" flow still requests location itself if this was skipped).
class PermissionsIntroScreen extends StatefulWidget {
  const PermissionsIntroScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<PermissionsIntroScreen> createState() => _PermissionsIntroScreenState();
}

class _PermissionsIntroScreenState extends State<PermissionsIntroScreen> {
  bool _requesting = false;

  Future<void> _continue() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    // Requested one at a time (not Future.wait) so each OS prompt appears in
    // its own turn rather than all firing at once, which some Android/iOS
    // versions coalesce or drop.
    for (final p in [Permission.photos, Permission.videos, Permission.notification, Permission.locationWhenInUse]) {
      try {
        await p.request();
      } catch (_) {
        // A permission this platform doesn't recognize (e.g. Permission.photos
        // pre-Android 13) — never blocks the rest of the flow.
      }
    }
    if (!mounted) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.forest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              Text(t.permIntroTitle, style: display(24, color: AppColors.forest900)),
              const SizedBox(height: 8),
              Text(t.permIntroBody, style: body(14, color: AppColors.textMuted, height: 1.5)),
              const SizedBox(height: 28),
              _PermissionRow(
                icon: Icons.photo_library_outlined,
                title: t.permMediaTitle,
                bodyText: t.permMediaBody,
              ),
              const SizedBox(height: 16),
              _PermissionRow(
                icon: Icons.notifications_outlined,
                title: t.permNotificationTitle,
                bodyText: t.permNotificationBody,
              ),
              const SizedBox(height: 16),
              _PermissionRow(
                icon: Icons.place_outlined,
                title: t.permLocationTitle,
                bodyText: t.permLocationBody,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ForestButton(
                  label: _requesting ? t.permRequesting : t.permContinue,
                  loading: _requesting,
                  onPressed: _requesting ? null : _continue,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _requesting ? null : widget.onDone,
                  child: Text(t.permSkip, style: body(13, color: AppColors.hint)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.icon, required this.title, required this.bodyText});
  final IconData icon;
  final String title;
  final String bodyText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Color(0xFFF0FBF4), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.forest700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: body(14, weight: FontWeight.w700, color: AppColors.forest900)),
                const SizedBox(height: 3),
                Text(bodyText, style: body(13, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
