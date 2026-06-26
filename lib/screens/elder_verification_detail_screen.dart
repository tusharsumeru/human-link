import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/pexels_image.dart';
import '../widgets/ui_kit.dart';

/// Elder verification detail — ported from
/// `src/app/elder/verifications/[id]/page.tsx`.
class ElderVerificationDetailScreen extends StatefulWidget {
  const ElderVerificationDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ElderVerificationDetailScreen> createState() =>
      _ElderVerificationDetailScreenState();
}

class _ElderVerificationDetailScreenState
    extends State<ElderVerificationDetailScreen> {
  static const Color _low = Color(0xFF16A34A);
  static const Color _medium = Color(0xFFD97706);
  static const Color _high = Color(0xFFDC2626);

  Color _riskColor(String level) {
    switch (level) {
      case 'high':
        return _high;
      case 'medium':
        return _medium;
      default:
        return _low;
    }
  }

  String _riskLabel(String level) {
    switch (level) {
      case 'high':
        return 'High Risk';
      case 'medium':
        return 'Medium Risk';
      default:
        return 'Low Risk';
    }
  }

  Color _aadhaarColor(String status) {
    switch (status) {
      case 'Verified':
        return _low;
      case 'Mismatch':
        return _high;
      default:
        return _medium;
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/elder/verifications');
    }
  }

  void _confirm(String title, String message, IconData icon, Color color) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: display(18, color: AppColors.forest900)),
            ),
          ],
        ),
        content: Text(message,
            style: body(13, color: AppColors.textMuted, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close',
                style: body(13,
                    weight: FontWeight.w600, color: AppColors.forest700)),
          ),
          ForestButton(
            label: 'Back to Queue',
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/elder/verifications');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = Repository.instance.verificationById(widget.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _back,
        ),
        title: Text('Verification Detail',
            style: display(18, color: Colors.white)),
      ),
      body: req == null ? _notFound() : _detail(req),
      bottomNavigationBar: req == null ? null : _footer(req),
    );
  }

  Widget _notFound() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 36, color: AppColors.hint),
          const SizedBox(height: 12),
          Text('Verification request not found',
              style: body(14, color: AppColors.hint)),
          const SizedBox(height: 16),
          OutlineButtonX(
            label: 'Back to Queue',
            onPressed: () => context.go('/elder/verifications'),
          ),
        ],
      ),
    );
  }

  Widget _detail(Map<String, dynamic> req) {
    final risk = req['riskLevel'] as String;
    final riskColor = _riskColor(risk);
    final aadhaar = req['aadhaarStatus'] as String;
    final aadhaarColor = _aadhaarColor(aadhaar);
    final vouches = (req['vouches'] as int?) ?? 0;
    final required = (req['vouchesRequired'] as int?) ?? 1;
    final genderLabel = req['gender'] == 'M' ? 'Male' : 'Female';
    final documents = (req['documents'] as List).cast<String>();
    final vouchDetails = (req['vouchDetails'] as List).cast<Map>();
    final notes = req['lineageNotes'] as String;
    final caution = risk == 'high' || notes.trimLeft().startsWith('⚠');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _header(req, riskColor, aadhaarColor, genderLabel),
        const SizedBox(height: 16),
        _riskBanner(risk, riskColor),
        const SizedBox(height: 16),
        // Claim
        _section(
          icon: Icons.shield_rounded,
          title: 'Lineage Claim',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Claiming From', req['claimingFrom'] as String),
              _row('Claiming Ancestor', req['claimingAncestor'] as String),
              _row('Stated Relation', req['relation'] as String),
              _row('Submitted On', req['submittedOn'] as String, last: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Identity
        _section(
          icon: Icons.badge_rounded,
          title: 'Identity',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Aadhaar Status',
                      style: body(12,
                          weight: FontWeight.w600,
                          color: AppColors.textMuted)),
                  const Spacer(),
                  Pill(aadhaar,
                      bg: aadhaarColor.withValues(alpha: 0.14),
                      fg: aadhaarColor),
                ],
              ),
              const SizedBox(height: 4),
              Text('Phone: ${req['phone']}',
                  style: body(12, color: AppColors.hint)),
              const SizedBox(height: 14),
              Text('SUBMITTED DOCUMENTS',
                  style: body(10,
                      weight: FontWeight.w700,
                      color: AppColors.hint,
                      letterSpacing: 0.8)),
              const SizedBox(height: 8),
              for (final doc in documents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F0E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: AppColors.forest700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(doc,
                              style: body(12,
                                  weight: FontWeight.w500,
                                  color: AppColors.label)),
                        ),
                        Pill('Received',
                            bg: _low.withValues(alpha: 0.14), fg: _low),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Peer Vouches
        _section(
          icon: Icons.verified_user_rounded,
          title: 'Peer Vouches ($vouches/$required confirmed)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressBar(value: required == 0 ? 0 : vouches / required),
              const SizedBox(height: 14),
              for (final v in vouchDetails) _vouchRow(v),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lineage Notes
        _notesCard(notes, caution),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _header(Map<String, dynamic> req, Color riskColor, Color aadhaarColor,
      String genderLabel) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              PexelsImage(
                url: req['photo'] as String?,
                name: req['name'] as String,
                size: double.infinity,
                radius: const BorderRadius.vertical(top: Radius.circular(18)),
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.forest900.withValues(alpha: 0.92),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Wrap(
                  spacing: 8,
                  children: [
                    Pill(_riskLabel(req['riskLevel'] as String),
                        bg: riskColor, fg: Colors.white),
                    Pill('Aadhaar: ${req['aadhaarStatus']}',
                        bg: aadhaarColor, fg: Colors.white),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req['name'] as String,
                        style: display(20, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                        '${req['age']} yrs · $genderLabel · ${req['gotra']} Gotra',
                        style: body(12, color: AppColors.forest300)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _factRow(Icons.work_outline_rounded, 'Occupation',
                    req['occupation'] as String),
                _factRow(Icons.location_on_outlined, 'Location',
                    req['location'] as String),
                _factRow(Icons.phone_outlined, 'Phone (masked)',
                    req['phone'] as String, last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _factRow(IconData icon, String label, String value,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.forest500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: AppColors.forest700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: body(11, color: AppColors.hint)),
                const SizedBox(height: 1),
                Text(value,
                    style: body(13,
                        weight: FontWeight.w600, color: AppColors.forest900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskBanner(String risk, Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, size: 20, color: riskColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Risk Assessment: ${_riskLabel(risk)}',
                style: body(13, weight: FontWeight.w700, color: riskColor)),
          ),
        ],
      ),
    );
  }

  Widget _section(
      {required IconData icon,
      required String title,
      required Widget child}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.forest700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: display(16, color: AppColors.forest900)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: body(11, color: AppColors.hint)),
          const SizedBox(height: 2),
          Text(value,
              style: body(13,
                  weight: FontWeight.w600,
                  color: AppColors.forest900,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _vouchRow(Map v) {
    final approved = v['status'] == 'Approved';
    final color = approved ? _low : AppColors.hint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: approved ? _low.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: approved
                  ? _low.withValues(alpha: 0.35)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(
                approved
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v['name'] as String,
                      style: body(13,
                          weight: FontWeight.w600,
                          color: AppColors.forest900)),
                  const SizedBox(height: 1),
                  Text(v['role'] as String,
                      style: body(11, color: AppColors.hint)),
                ],
              ),
            ),
            Pill(v['status'] as String,
                bg: approved
                    ? _low.withValues(alpha: 0.14)
                    : const Color(0xFFF3F4F6),
                fg: approved ? _low : AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _notesCard(String notes, bool caution) {
    final color = caution ? _high : AppColors.forest700;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: caution ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: caution
                ? _high.withValues(alpha: 0.4)
                : AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  caution
                      ? Icons.warning_amber_rounded
                      : Icons.sticky_note_2_outlined,
                  size: 18,
                  color: color),
              const SizedBox(width: 8),
              Text('Elder Committee Notes',
                  style: display(15, color: caution ? _high : AppColors.forest900)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: caution
                  ? _high.withValues(alpha: 0.06)
                  : const Color(0xFFF7F0E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(notes,
                style: body(13,
                    color: caution ? _high : AppColors.label, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _footer(Map<String, dynamic> req) {
    final name = req['name'] as String;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: ForestButton(
                  label: 'Approve',
                  icon: Icons.check_circle_outline_rounded,
                  expand: true,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF15803D), _low],
                  ),
                  onPressed: () => _confirm(
                    'Verification Approved',
                    '$name will be officially added to the Samaj registry. '
                        'A notification will be sent to the applicant.',
                    Icons.check_circle_rounded,
                    _low,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Request More Info',
                onPressed: () => _confirm(
                  'Information Requested',
                  'A query has been sent to $name requesting additional '
                      'documents or clarification. Case paused pending response.',
                  Icons.help_outline_rounded,
                  _medium,
                ),
                icon: const Icon(Icons.help_outline_rounded,
                    color: AppColors.gold700),
              ),
              const SizedBox(width: 4),
              OutlineButtonX(
                label: 'Reject',
                color: _high,
                onPressed: () => _confirm(
                  'Request Rejected',
                  'The verification request for $name has been rejected. '
                      'The applicant will be notified with a reason.',
                  Icons.cancel_outlined,
                  _high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
