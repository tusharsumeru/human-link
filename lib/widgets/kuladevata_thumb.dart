import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small tappable thumbnail for a Kuladevata photo — shown inline right
/// before the name, sized to match the surrounding text rather than the
/// text being sized to it. Tapping it opens the full photo.
///
/// [source] is either a bundled asset path (`kKuladevataImages` in
/// `lib/data/kuladevatas.dart`) or an `http(s)` URL uploaded through the admin
/// panel's Dropdown Options screen. Which one it is is decided per call rather
/// than per widget, so a list can mix the two — the admin gives a picture to
/// some entries and the app still ships assets for the rest.
class KuladevataThumb extends StatelessWidget {
  const KuladevataThumb({
    super.key,
    required this.source,
    required this.name,
    this.size = 16,
  });

  final String source;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => _KuladevataImageModal(source: source, name: name),
      ),
      child: ClipOval(
        child: _KuladevataImage(
          source: source,
          width: size,
          height: size,
          // A missing picture leaves the space it would have taken, so the
          // names in a list stay aligned whether or not they have one.
          fallback: SizedBox(width: size, height: size),
        ),
      ),
    );
  }
}

/// Dialog shown when tapping a [KuladevataThumb] — a round, zoomable photo
/// over a dark scrim, dismissed by tapping outside it or the close button.
class _KuladevataImageModal extends StatelessWidget {
  const _KuladevataImageModal({required this.source, required this.name});

  final String source;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipOval(
              child: InteractiveViewer(
                child: _KuladevataImage(source: source, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: body(14, weight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 14),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Draws [source] from wherever it lives: `Image.network` for an http(s) URL,
/// `Image.asset` for anything else.
class _KuladevataImage extends StatelessWidget {
  const _KuladevataImage({
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback = const SizedBox.shrink(),
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final remote =
        source.startsWith('http://') || source.startsWith('https://');
    Widget errorBuilder(BuildContext _, Object __, StackTrace? ___) => fallback;
    return remote
        ? Image.network(
            source,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: errorBuilder,
          )
        : Image.asset(
            source,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: errorBuilder,
          );
  }
}
