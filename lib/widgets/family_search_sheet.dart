import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import 'pexels_image.dart';

/// Bottom sheet that searches family-tree members via `GET /api/family/search`.
/// [multi] true → multi-select with a Done button (returns the chosen members);
/// false → tap a member to pick it and close immediately. Returns the selected
/// members (`[{_id, name, ...}]`) or null if dismissed.
Future<List<Map<String, dynamic>>?> showFamilySearchSheet(
  BuildContext context, {
  required String title,
  bool multi = false,
  Set<String> selectedIds = const {},
}) {
  return showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _FamilySearchSheet(
      title: title,
      multi: multi,
      selectedIds: selectedIds,
    ),
  );
}

class _FamilySearchSheet extends StatefulWidget {
  const _FamilySearchSheet({
    required this.title,
    required this.multi,
    required this.selectedIds,
  });
  final String title;
  final bool multi;
  final Set<String> selectedIds;

  @override
  State<_FamilySearchSheet> createState() => _FamilySearchSheetState();
}

class _FamilySearchSheetState extends State<_FamilySearchSheet> {
  final _ctrl = TextEditingController();
  final Map<String, Map<String, dynamic>> _picked = {};
  List<Map<String, dynamic>> _results = const [];
  bool _loading = true;
  Timer? _debounce;
  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    final id = ++_reqId;
    setState(() => _loading = true);
    try {
      final res = await Repository.instance.familySearch(q, limit: 25);
      if (!mounted || id != _reqId) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _reqId) return;
      setState(() {
        _results = const [];
        _loading = false;
      });
    }
  }

  void _toggle(Map<String, dynamic> m) {
    final id = (m['_id'] ?? '').toString();
    if (!widget.multi) {
      Navigator.of(context).pop(<Map<String, dynamic>>[m]);
      return;
    }
    setState(() {
      if (_picked.containsKey(id)) {
        _picked.remove(id);
      } else {
        _picked[id] = m;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (context, scroll) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(widget.title,
                      style: display(17, color: AppColors.forest900)),
                  const Spacer(),
                  if (widget.multi)
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pop(_picked.values.toList()),
                      child: Text('Done (${_picked.length})',
                          style: body(14,
                              weight: FontWeight.w700,
                              color: AppColors.forest700)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                style: body(14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search by name…',
                  prefixIcon: const Icon(Icons.search, color: AppColors.hint),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.forest700, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.forest700, strokeWidth: 2))
                  : _results.isEmpty
                      ? Center(
                          child: Text('No members found',
                              style: body(13, color: AppColors.textMuted)))
                      : ListView.builder(
                          controller: scroll,
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final m = _results[i];
                            final id = (m['_id'] ?? '').toString();
                            final name = (m['name'] ?? '').toString();
                            final gotra = (m['gotra'] ?? '').toString();
                            final branch = (m['branch'] ?? '').toString();
                            final sub = [gotra, branch]
                                .where((s) => s.isNotEmpty)
                                .join(' · ');
                            final selected = _picked.containsKey(id) ||
                                widget.selectedIds.contains(id);
                            return ListTile(
                              leading: PexelsImage(
                                  url: (m['photoUrl'] ?? '').toString(),
                                  name: name,
                                  size: 42),
                              title: Text(name,
                                  style: body(14,
                                      weight: FontWeight.w600,
                                      color: AppColors.ink)),
                              subtitle: sub.isEmpty
                                  ? null
                                  : Text(sub,
                                      style: body(12,
                                          color: AppColors.textMuted)),
                              trailing: widget.multi
                                  ? Icon(
                                      selected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: selected
                                          ? AppColors.forest700
                                          : AppColors.hint,
                                    )
                                  : const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.hint),
                              onTap: () => _toggle(m),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
