import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Forest-gradient primary button (web `.btn-forest`).
class ForestButton extends StatelessWidget {
  const ForestButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient = AppGradients.forest,
    this.shadow,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final List<BoxShadow>? shadow;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: shadow ?? AppShadows.forestGlow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else ...[
                  Text(label,
                      style: body(14,
                          weight: FontWeight.w600, color: Colors.white)),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 16, color: Colors.white),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return button;
  }
}

/// Gold variant of [ForestButton].
class GoldButton extends StatelessWidget {
  const GoldButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.icon,
      this.expand = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) => ForestButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
        gradient: AppGradients.gold,
        shadow: AppShadows.goldGlow,
      );
}

/// Outlined secondary button.
class OutlineButtonX extends StatelessWidget {
  const OutlineButtonX(
      {super.key,
      required this.label,
      this.onPressed,
      this.color = AppColors.forest800,
      this.expand = false});
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        minimumSize: expand ? const Size.fromHeight(48) : null,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: body(14, weight: FontWeight.w600, color: color)),
    );
  }
}

/// White rounded card with soft shadow + gold-tint border (web cards).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 18,
    this.color = Colors.white,
    this.border = true,
    this.shadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final bool border;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: AppColors.border) : null,
        boxShadow: shadow ?? AppShadows.soft,
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Small pill badge.
class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.bg,
    this.fg = AppColors.forest800,
    this.icon,
    this.fontSize = 11,
  });
  final String label;
  final Color? bg;
  final Color fg;
  final IconData? icon;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: body(fontSize, weight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

/// Section eyebrow + title (web pattern: small gold label over a serif heading).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.center = false,
    this.titleSize = 28,
  });
  final String? eyebrow;
  final String title;
  final String? subtitle;
  final bool center;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(),
              style: body(12,
                  weight: FontWeight.w700,
                  color: AppColors.gold700,
                  letterSpacing: 1.4)),
          const SizedBox(height: 6),
        ],
        Text(title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: display(titleSize, color: AppColors.forest900)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: body(14, color: AppColors.textMuted, height: 1.5)),
        ],
      ],
    );
  }
}

/// Gradient progress bar (welfare campaigns).
class ProgressBar extends StatelessWidget {
  const ProgressBar(
      {super.key,
      required this.value,
      this.height = 8,
      this.gradient = AppGradients.forest,
      this.background = const Color(0xFFEDE6D8)});
  final double value; // 0..1
  final double height;
  final Gradient gradient;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: height, color: background),
          FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(
                height: height,
                decoration: BoxDecoration(gradient: gradient)),
          ),
        ],
      ),
    );
  }
}

/// Currency formatting used throughout (₹4.25L, ₹50,00,000).
String formatLakh(num n) {
  if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)}Cr';
  if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
  return '₹${n.toStringAsFixed(0)}';
}

/// Indian digit grouping: 5000000 -> "50,00,000".
String formatIndian(num n) {
  final s = n.round().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}
