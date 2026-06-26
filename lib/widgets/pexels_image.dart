import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/avatars.dart';
import '../theme/app_theme.dart';

/// Network photo with a graceful initials fallback while loading / on error.
class PexelsImage extends StatelessWidget {
  const PexelsImage({
    super.key,
    required this.url,
    this.name = '',
    this.size = 48,
    this.radius,
    this.fit = BoxFit.cover,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String? url;
  final String name;
  final double size;
  final BorderRadius? radius;
  final BoxFit fit;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final br = radius ?? BorderRadius.circular(size);
    Widget child;
    if (url == null || url!.isEmpty) {
      child = _fallback();
    } else {
      child = CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: fit,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: br,
        border: borderWidth > 0
            ? Border.all(color: borderColor ?? AppColors.forest700, width: borderWidth)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(gradient: AppGradients.forest),
        alignment: Alignment.center,
        child: Text(
          name.isEmpty ? '·' : initialsOf(name),
          style: body(size * 0.34, weight: FontWeight.w700, color: Colors.white),
        ),
      );
}

/// Convenience for avatar-key based portraits (e.g. "6", "elder").
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.avatarKey,
    this.name = '',
    this.size = 40,
    this.borderColor,
    this.borderWidth = 0,
  });
  final String? avatarKey;
  final String name;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) => PexelsImage(
        url: avatarUrl(avatarKey),
        name: name,
        size: size,
        borderColor: borderColor,
        borderWidth: borderWidth,
      );
}
