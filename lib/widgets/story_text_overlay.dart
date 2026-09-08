import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';

/// Instagram-style "type on your photo" editor: shows the picked image and
/// lets the caller drop text anywhere on it, drag it around, pinch to resize/
/// rotate it, and tap it again to edit or remove it. [export] bakes every
/// text layer into the photo itself and hands back a new file to upload —
/// nothing in the backend or the story schema needs to know overlays exist,
/// they're just pixels in the final image.
///
/// Video stories don't get this — compositing text onto every frame of a
/// video is a different (encoding) problem, out of scope here. The caller is
/// expected to only mount this for an image story.
class StoryTextOverlayEditor extends StatefulWidget {
  const StoryTextOverlayEditor({super.key, required this.imagePath});
  final String imagePath;

  @override
  State<StoryTextOverlayEditor> createState() => StoryTextOverlayEditorState();
}

class _TextItem {
  _TextItem({
    required this.id,
    required this.text,
    required this.color,
    required this.background,
    required this.offset,
  });
  final int id;
  String text;
  Color color;
  bool background;
  Offset offset;
  double scale = 1;
  double rotation = 0;
  // Captured at the start of a scale gesture so onScaleUpdate (whose
  // `scale`/`rotation` are cumulative from gesture-start, not incremental)
  // can be applied on top of whatever the item already had.
  double _gestureBaseScale = 1;
  double _gestureBaseRotation = 0;
}

/// A handful of preset colors, Instagram-style — not app theme colors, these
/// are purely what a member might want their story text to look like.
const _textColors = <Color>[
  Colors.white,
  Colors.black,
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFFFDE047),
  Color(0xFF22C55E),
  Color(0xFF3B82F6),
  Color(0xFFA855F7),
  Color(0xFFEC4899),
];

class StoryTextOverlayEditorState extends State<StoryTextOverlayEditor> {
  final _boundaryKey = GlobalKey();
  final List<_TextItem> _items = [];
  int _seq = 0;
  Size? _naturalSize; // the photo's own pixel dimensions
  Size _layoutSize = Size.zero; // the editor's on-screen logical size

  @override
  void initState() {
    super.initState();
    final provider = FileImage(File(widget.imagePath));
    provider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            if (!mounted) return;
            setState(() {
              _naturalSize = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );
            });
          }),
        );
  }

  /// Bakes every text layer into the photo and returns a new file to upload.
  /// No layers → the original file, untouched (no needless recompression).
  /// Capped at 1600px on the long edge — plenty sharp for a phone-screen
  /// story and keeps the capture from ballooning in memory on a big source
  /// photo.
  Future<String> export() async {
    if (_items.isEmpty) return widget.imagePath;
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final natural = _naturalSize ?? boundary.size;
    final longEdge = natural.width > natural.height
        ? natural.width
        : natural.height;
    final cappedLongEdge = longEdge > 1600 ? 1600.0 : longEdge;
    final onScreenLongEdge = boundary.size.width > boundary.size.height
        ? boundary.size.width
        : boundary.size.height;
    final pixelRatio = onScreenLongEdge == 0
        ? 1.0
        : cappedLongEdge / onScreenLongEdge;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/story_text_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _addText() async {
    final result = await _showTextComposer(context);
    if (result == null || result.text.trim().isEmpty) return;
    final center = Offset(_layoutSize.width / 2, _layoutSize.height / 2);
    setState(() {
      _items.add(
        _TextItem(
          id: ++_seq,
          text: result.text.trim(),
          color: result.color,
          background: result.background,
          // Roughly centers the text block itself, not just its top-left.
          offset: center - const Offset(70, 16),
        ),
      );
    });
  }

  Future<void> _editText(_TextItem item) async {
    final result = await _showTextComposer(
      context,
      initialText: item.text,
      initialColor: item.color,
      initialBackground: item.background,
      allowRemove: true,
    );
    if (result == null) return;
    setState(() {
      if (result.removed) {
        _items.removeWhere((e) => e.id == item.id);
        return;
      }
      if (result.text.trim().isEmpty) {
        _items.removeWhere((e) => e.id == item.id);
        return;
      }
      item
        ..text = result.text.trim()
        ..color = result.color
        ..background = result.background;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_naturalSize == null) {
      return const AspectRatio(
        aspectRatio: 3 / 4,
        child: ColoredBox(
          color: AppColors.forest900,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: _naturalSize!.width / _naturalSize!.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(widget.imagePath), fit: BoxFit.cover),
                        for (final item in _items) _textLayer(item),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(top: 10, right: 10, child: _AaButton(onTap: _addText)),
              if (_items.isNotEmpty)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Drag to move · pinch to resize · tap to edit',
                        style: body(11, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _textLayer(_TextItem item) {
    return Positioned(
      left: item.offset.dx,
      top: item.offset.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _editText(item),
        onScaleStart: (_) {
          item._gestureBaseScale = item.scale;
          item._gestureBaseRotation = item.rotation;
        },
        onScaleUpdate: (d) {
          setState(() {
            item.offset += d.focalPointDelta;
            item.scale = (item._gestureBaseScale * d.scale).clamp(0.4, 4.0);
            item.rotation = item._gestureBaseRotation + d.rotation;
          });
        },
        child: Transform.rotate(
          angle: item.rotation,
          child: Transform.scale(
            scale: item.scale,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: item.background
                  ? BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item.color,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  shadows: item.background
                      ? null
                      : const [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AaButton extends StatelessWidget {
  const _AaButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            'Aa',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Text composer sheet ──────────────────────────────────────────────────

class _ComposerResult {
  const _ComposerResult({
    required this.text,
    required this.color,
    required this.background,
    this.removed = false,
  });
  final String text;
  final Color color;
  final bool background;
  final bool removed;
}

/// Full-screen text entry: live color preview, a swatch row, and a toggle for
/// the pill background — the same handful of controls Instagram's own text
/// tool offers, kept to just what's needed rather than a full rich-text
/// editor.
Future<_ComposerResult?> _showTextComposer(
  BuildContext context, {
  String initialText = '',
  Color initialColor = Colors.white,
  bool initialBackground = false,
  bool allowRemove = false,
}) {
  final controller = TextEditingController(text: initialText);
  Color color = initialColor;
  bool background = initialBackground;
  return showGeneralDialog<_ComposerResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add text',
    barrierColor: Colors.black87,
    pageBuilder: (context, _, __) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Text background',
                          onPressed: () =>
                              setSheetState(() => background = !background),
                          icon: Icon(
                            Icons.format_color_fill_rounded,
                            color: background
                                ? AppColors.gold500
                                : Colors.white70,
                          ),
                        ),
                        if (allowRemove)
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(
                              _ComposerResult(
                                text: '',
                                color: color,
                                background: background,
                                removed: true,
                              ),
                            ),
                            child: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(
                            _ComposerResult(
                              text: controller.text,
                              color: color,
                              background: background,
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          maxLines: null,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: color,
                          style: TextStyle(
                            color: color,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type something…',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _textColors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final c = _textColors[i];
                          final selected = c == color;
                          return GestureDetector(
                            onTap: () => setSheetState(() => color = c),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white24,
                                  width: selected ? 3 : 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
