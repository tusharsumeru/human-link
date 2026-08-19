import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models/compatibility_models.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Compatibility consent settings — one explicit, separately-labeled toggle
/// per purpose (GET/POST/POST /api/v1/compatibility/consent[...]), following
/// the same design as the phone-number privacy card on the profile screen:
/// AppCard + Switch, optimistic, rolled back on a failed save.
///
/// Deliberately never a single "I agree" checkbox: each purpose is its own
/// card with its own description, and turning one on never turns on another.
/// Only Birth-Data Matching does anything today (it's what Jataka
/// compatibility requires) — the other four purposes in the backend's
/// CONSENT_TYPES enum (profile answers, family-tree relationship check,
/// sensitive fields, report sharing) aren't read by any feature yet, so they
/// don't get a toggle here either; a toggle that does nothing would be
/// misleading, not "explicit."
class CompatibilityConsentScreen extends StatefulWidget {
  const CompatibilityConsentScreen({super.key});

  @override
  State<CompatibilityConsentScreen> createState() => _CompatibilityConsentScreenState();
}

class _CompatibilityConsentScreenState extends State<CompatibilityConsentScreen> {
  bool _loading = true;
  String? _loadError;
  List<ConsentStatus> _consents = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final consents = await Repository.instance.myCompatibilityConsent();
      if (!mounted) return;
      setState(() {
        _consents = consents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError =
            e is ApiException ? e.message : 'Could not load your consent settings';
        _loading = false;
      });
    }
  }

  ConsentStatus? _find(CompatibilityConsentType type) {
    for (final c in _consents) {
      if (c.consentType == type) return c;
    }
    return null;
  }

  void _applyUpdate(ConsentStatus updated) {
    setState(() {
      _consents = [
        for (final c in _consents)
          if (c.consentType == updated.consentType) updated else c,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Compatibility Consent', style: display(18, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!,
                            textAlign: TextAlign.center,
                            style: body(14, color: AppColors.textMuted)),
                        const SizedBox(height: 14),
                        OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    Text(
                      'Each purpose below is separate - turning one on never turns on '
                      'another. You can revoke at any time; the compatibility engine '
                      'checks this directly before every calculation.',
                      style: body(12, color: AppColors.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    _ConsentPurposeCard(
                      icon: Icons.cake_outlined,
                      title: 'Birth-Data Matching',
                      description:
                          'Use your birth date, time and place to calculate traditional '
                          'Jataka (10 Porutham) compatibility with another member.',
                      status: _find(CompatibilityConsentType.birthDataMatching),
                      onChanged: _applyUpdate,
                    ),
                  ],
                ),
    );
  }
}

class _ConsentPurposeCard extends StatefulWidget {
  const _ConsentPurposeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final ConsentStatus? status;
  final ValueChanged<ConsentStatus> onChanged;

  @override
  State<_ConsentPurposeCard> createState() => _ConsentPurposeCardState();
}

class _ConsentPurposeCardState extends State<_ConsentPurposeCard> {
  bool _saving = false;

  Future<void> _toggle(bool next) async {
    final status = widget.status;
    if (status == null || _saving) return;
    setState(() => _saving = true);
    try {
      if (next) {
        await Repository.instance.grantCompatibilityConsent(status.consentType.wireValue);
      } else {
        await Repository.instance.revokeCompatibilityConsent(status.consentType.wireValue);
      }
      // Re-read from the server rather than guessing the new policyVersion /
      // timestamps ourselves — the server is the source of truth for both.
      final fresh = await Repository.instance.myCompatibilityConsent();
      var updated = status;
      for (final c in fresh) {
        if (c.consentType == status.consentType) updated = c;
      }
      if (!mounted) return;
      widget.onChanged(updated);
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : "Couldn't save that. Try again."),
      ));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final on = status?.satisfiesCalculation ?? false;
    // Genuinely GRANTED, just not under the policy currently in effect — a
    // distinct state from "never asked," worth explaining rather than just
    // silently showing the switch off.
    final outdated = status != null && status.granted && !status.isCurrentPolicy;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.gold700),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(widget.title, style: display(17, color: AppColors.forest900))),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.description, style: body(13, color: AppColors.textMuted, height: 1.45)),
          const SizedBox(height: 14),
          if (outdated) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.gold700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Our consent policy was updated since you last agreed - '
                      'switch this back on to confirm again.',
                      style: body(11, color: AppColors.gold700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  on ? 'Allowed' : 'Not allowed',
                  style: body(14, weight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
              _saving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.forest700),
                      ),
                    )
                  : Switch(
                      value: on,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.forest700,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: AppColors.border,
                      onChanged: status == null ? null : _toggle,
                    ),
            ],
          ),
          if (on && status?.grantedAt != null) ...[
            const SizedBox(height: 8),
            Text('Granted ${_formatDate(status!.grantedAt!)}',
                style: body(11, color: AppColors.hint)),
          ],
        ],
      ),
    );
  }
}
