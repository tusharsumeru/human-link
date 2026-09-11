import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small tappable thumbnail for a Kuladevata that has a bundled photo (see
/// `kKuladevataImages` in `lib/data/kuladevatas.dart`) — shown inline right
/// before the name, sized to match the surrounding text rather than the
/// text being sized to it. Tapping it opens the full photo.
class KuladevataThumb extends StatelessWidget {
  const KuladevataThumb({
    super.key,
    required this.assetPath,
    required this.name,
    this.size = 16,
  });

  final String assetPath;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => _KuladevataImageModal(assetPath: assetPath, name: name),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
        ),
      ),
    );
  }
}

/// Dialog shown when tapping a [KuladevataThumb] — a round, zoomable photo
/// over a dark scrim, dismissed by tapping outside it or the close button.
class _KuladevataImageModal extends StatelessWidget {
  const _KuladevataImageModal({required this.assetPath, required this.name});

  final String assetPath;
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
                child: Image.asset(assetPath, fit: BoxFit.cover),
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
