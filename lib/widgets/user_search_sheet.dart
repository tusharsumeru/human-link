import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import 'pexels_image.dart';

/// Bottom sheet that searches all registered members via
/// `GET /api/user/directory` — used to "tag people" on a post, Instagram-style
/// (unlike [showFamilySearchSheet] in family_search_sheet.dart, which is
/// scoped to just the caller's own family tree). Multi-select with a Done
/// button; returns the chosen members (`[{id, userName, name, ...}]`) or null
/// if dismissed.
Future<List<Map<String, dynamic>>?> showUserSearchSheet(
  BuildContext context, {
  required String title,
  Set<String> selectedIds = const {},
}) {
  return showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.onBrightness(
      light: AppColors.cream,
      dark: AppColors.darkSurface,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _UserSearchSheet(title: title, selectedIds: selectedIds),
  );
}

class _UserSearchSheet extends StatefulWidget {
  const _UserSearchSheet({required this.title, required this.selectedIds});
  final String title;
  final Set<String> selectedIds;

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
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
      final res = await Repository.instance.usersDirectory(q: q, limit: 25);
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
    final id = (m['id'] ?? '').toString();
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
    final ink = context.onBrightness(
      light: AppColors.ink,
      dark: AppColors.darkText,
    );
    final hint = context.onBrightness(
      light: AppColors.hint,
      dark: AppColors.darkTextMuted,
    );
    final fieldFill = context.onBrightness(
      light: Colors.white,
      dark: AppColors.darkBg,
    );
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
                color: context.onBrightness(
                  light: AppColors.border,
                  dark: AppColors.darkBorder,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: display(
                      17,
                      color: context.onBrightness(
                        light: AppColors.forest900,
                        dark: AppColors.darkText,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_picked.values.toList()),
                    child: Text(
                      'Done (${_picked.length})',
                      style: body(
                        14,
                        weight: FontWeight.w700,
                        color: AppColors.forest700,
                      ),
                    ),
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
                style: body(14, color: ink),
                decoration: InputDecoration(
                  hintText: 'Search members by name…',
                  hintStyle: body(14, color: hint),
                  prefixIcon: Icon(Icons.search, color: hint),
                  filled: true,
                  fillColor: fieldFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.onBrightness(
                        light: AppColors.border,
                        dark: AppColors.darkBorder,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.forest700,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.forest700,
                        strokeWidth: 2,
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        'No members found',
                        style: body(13, color: hint),
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final m = _results[i];
                        final id = (m['id'] ?? '').toString();
                        final name = (m['name'] ?? m['userName'] ?? '')
                            .toString();
                        final userName = (m['userName'] ?? '').toString();
                        final selected =
                            _picked.containsKey(id) ||
                            widget.selectedIds.contains(id);
                        return ListTile(
                          leading: PexelsImage(
                            url: (m['profileUrl'] ?? '').toString(),
                            name: name,
                            size: 42,
                          ),
                          title: Text(
                            name,
                            style: body(
                              14,
                              weight: FontWeight.w600,
                              color: ink,
                            ),
                          ),
                          subtitle: userName.isEmpty
                              ? null
                              : Text(
                                  '@$userName',
                                  style: body(12, color: hint),
                                ),
                          trailing: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: selected ? AppColors.forest700 : hint,
                          ),
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
