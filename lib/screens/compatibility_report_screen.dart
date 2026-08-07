import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/models/compatibility_models.dart';
import '../data/repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/compatibility_report_view.dart';
import '../widgets/ui_kit.dart';

/// STEP 25D — reads a compatibility report purely by its `reportId` (what
/// `POST /api/v1/compatibility/calculate` hands back on success from
/// [CompatibilityCheckScreen]). No calculation happens here or anywhere in
/// this file; this only fetches the already-computed report
/// (`GET /api/v1/compatibility/reports/:reportId`) and renders it with the
/// same [CompatibilityReportView] the calculate flow itself uses.
class CompatibilityReportScreen extends StatefulWidget {
  const CompatibilityReportScreen({
    super.key,
    required this.reportId,
    this.otherName = '',
  });

  final String reportId;

  /// Convenience display name for the header — passed by the caller (who
  /// already has it loaded) so it renders immediately, without a second
  /// fetch just for a name.
  final String otherName;

  @override
  State<CompatibilityReportScreen> createState() => _CompatibilityReportScreenState();
}

class _CompatibilityReportScreenState extends State<CompatibilityReportScreen> {
  bool _loading = true;
  String? _error;
  CompatibilityReport? _report;

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
      final report = await Repository.instance.compatibilityReport(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'Could not load the compatibility report';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myName = context.watch<AuthService>().user?.name ?? 'You';
    final otherName =
        widget.otherName.trim().isNotEmpty ? widget.otherName.trim() : 'This member';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Compatibility Report', style: display(18, color: Colors.white)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorState(_error!)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                    children: [
                      _header(myName, otherName),
                      const SizedBox(height: 16),
                      CompatibilityReportView(report: _report!),
                    ],
                  ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.hint),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: body(14, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            OutlineButtonX(label: 'Try again', onPressed: _load),
          ],
        ),
      ),
    );
  }

  Widget _header(String myName, String otherName) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFCEBDD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, size: 26, color: AppColors.gold700),
          ),
          const SizedBox(height: 14),
          Text('Compatibility Report',
              style: display(20, color: AppColors.forest900),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('$myName × $otherName',
              style: body(14, weight: FontWeight.w600, color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
