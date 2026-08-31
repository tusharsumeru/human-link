import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/ui_kit.dart';

/// Elder · Community Events & Settings — ported from
/// `src/app/elder/events/page.tsx`. A Samaja events list (upcoming/past) with
/// RSVP/Manage actions, plus a small committee preferences section.
class ElderEventsScreen extends StatelessWidget {
  const ElderEventsScreen({super.key});

  static List<Map<String, dynamic>> _eventsOf(AppLocalizations t) => [
    {
      'title': t.elderEvent1Title,
      'date': '15 Aug',
      'type': 'Cultural',
      'venue': t.elderEvent1Venue,
      'attendees': 420,
      'status': 'Upcoming',
    },
    {
      'title': t.elderEvent2Title,
      'date': '28 Jun',
      'type': 'Admin',
      'venue': t.elderEvent2Venue,
      'attendees': 12,
      'status': 'Upcoming',
    },
    {
      'title': t.elderEvent3Title,
      'date': '10 Jul',
      'type': 'Education',
      'venue': t.elderEvent3Venue,
      'attendees': 180,
      'status': 'Upcoming',
    },
    {
      'title': t.elderEvent4Title,
      'date': '22 Jul',
      'type': 'Community',
      'venue': t.elderEvent4Venue,
      'attendees': 250,
      'status': 'Planning',
    },
  ];

  static const Map<String, List<int>> _typeColors = {
    'Cultural': [0xFFD1FAE5, 0xFF065F46],
    'Admin': [0xFFEDE9FE, 0xFF5B21B6],
    'Education': [0xFFDBEAFE, 0xFF1E40AF],
    'Community': [0xFFFEF3C7, 0xFFD97706],
  };

  static String _typeLabel(String type, AppLocalizations t) => switch (type) {
        'Cultural' => t.elderTypeCultural,
        'Admin' => t.elderTypeAdmin,
        'Education' => t.elderTypeEducation,
        'Community' => t.elderTypeCommunity,
        _ => type,
      };

  static String _statusLabel(String status, AppLocalizations t) =>
      status == 'Planning' ? t.elderStatusPlanning : t.elderStatusUpcoming;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.forest800,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AppShell(
      title: t.elderSettings,
      currentRoute: '/elder/events',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SectionHeader(
                  eyebrow: t.elderManageEventsEyebrow,
                  title: t.elderCommunityEvents,
                  subtitle: t.elderEventsSubtitle,
                  titleSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ForestButton(
            label: t.elderAddEvent,
            icon: Icons.add_circle_outline_rounded,
            onPressed: () => _toast(context, t.elderAddEventToast),
          ),
          const SizedBox(height: 18),
          ..._eventsOf(t).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _eventCard(context, e, t),
              )),
          const SizedBox(height: 8),
          _settingsSection(context, t),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _eventCard(BuildContext context, Map<String, dynamic> e, AppLocalizations t) {
    final col = _typeColors[e['type']] ?? const [0xFFF3F4F6, 0xFF374151];
    final status = e['status'] as String;
    final isPlanning = status == 'Planning';
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date chip
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Color(col[0]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text((e['date'] as String).split(' ').first,
                    style: display(18, color: Color(col[1]))),
                Text((e['date'] as String).split(' ').last.toUpperCase(),
                    style: body(10,
                        weight: FontWeight.w700, color: Color(col[1]))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['title'] as String,
                    style: body(14.5,
                        weight: FontWeight.w700, color: AppColors.forest900)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Pill(_typeLabel(e['type'] as String, t),
                        bg: Color(col[0]), fg: Color(col[1])),
                    Pill(_statusLabel(status, t),
                        bg: isPlanning
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFD1FAE5),
                        fg: isPlanning
                            ? const Color(0xFFD97706)
                            : const Color(0xFF065F46)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.hint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(e['venue'] as String,
                          style: body(11.5, color: AppColors.textMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        size: 13, color: AppColors.hint),
                    const SizedBox(width: 4),
                    Text(t.elderAttendeesExpected(e['attendees'] as int),
                        style: body(11.5, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ForestButton(
                      label: t.elderRsvp,
                      onPressed: () => _toast(
                          context, t.elderRsvpConfirmed(e['title'] as String)),
                    ),
                    const SizedBox(width: 8),
                    OutlineButtonX(
                      label: t.elderManage,
                      onPressed: () => _toast(
                          context, t.elderManaging(e['title'] as String)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsSection(BuildContext context, AppLocalizations t) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.elderCommitteePreferences,
              style: display(18, color: AppColors.forest900)),
          const SizedBox(height: 4),
          Text(t.elderCommitteePreferencesSubtitle,
              style: body(12.5, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.notifications_active_outlined,
            title: t.elderEventReminders,
            subtitle: t.elderEventRemindersSubtitle,
            initial: true,
            onChanged: (v) => _toast(context,
                v ? t.elderEventRemindersOn : t.elderEventRemindersOff),
          ),
          _SettingsTile(
            icon: Icons.how_to_reg_outlined,
            title: t.elderAutoApproveRsvps,
            subtitle: t.elderAutoApproveRsvpsSubtitle,
            initial: false,
            onChanged: (v) => _toast(
                context, v ? t.elderAutoApproveOn : t.elderAutoApproveOff),
          ),
          _SettingsTile(
            icon: Icons.public_outlined,
            title: t.elderPublishToPublicCalendar,
            subtitle: t.elderPublishToPublicCalendarSubtitle,
            initial: true,
            onChanged: (v) => _toast(
                context, v ? t.elderPublicCalendarOn : t.elderPublicCalendarOff),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatefulWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool initial;
  final ValueChanged<bool> onChanged;

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  late bool _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.forest800.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, size: 18, color: AppColors.forest700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: body(13.5,
                        weight: FontWeight.w600, color: AppColors.forest900)),
                Text(widget.subtitle,
                    style: body(11.5, color: AppColors.textMuted, height: 1.4)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _value,
            activeThumbColor: AppColors.forest700,
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
