import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One welfare campaign as `GET /api/welfare/campaigns` returns it.
///
/// Campaigns are created by the admin in the web admin panel; the app only
/// reads them and takes donations against them. `id` is the campaign slug —
/// the value donation orders carry as `campaignId`.
class WelfareCampaign {
  const WelfareCampaign({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.goal,
    required this.raised,
    required this.daysLeft,
    required this.backers,
    required this.image,
    required this.color,
    required this.status,
  });

  final String id;
  final String title;
  final String category;
  final String description;

  /// Target and running total, in whole rupees.
  final int goal;
  final int raised;

  /// Null when the campaign has no end date.
  final int? daysLeft;
  final int backers;

  /// Emoji or cover image URL chosen by the admin.
  final String image;

  /// Tailwind gradient the web app renders with, e.g. "from-green-800 to-green-600".
  final String color;

  /// active · completed · closed
  final String status;

  bool get isActive => status == 'active';
  bool get imageIsUrl =>
      image.startsWith('http://') || image.startsWith('https://');
  double get progress => goal <= 0 ? 0 : (raised / goal).clamp(0, 1).toDouble();
  int get percent => goal <= 0 ? 0 : ((raised / goal) * 100).round();

  /// Category keys are stored as the admin's enum values ("culturalHeritage");
  /// show them as words.
  String get categoryLabel {
    if (category.isEmpty) return 'General';
    final spaced = category
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  /// The two colours of the card gradient, mapped from the web app's
  /// Tailwind class pair. Unknown values fall back to the forest gradient.
  LinearGradient get gradient {
    final pair = _gradients[color] ?? _gradients.values.first;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [pair.$1, pair.$2],
    );
  }

  /// The darker/accent colour, for legends and chart slices.
  Color get accent => (_gradients[color] ?? _gradients.values.first).$2;

  static const Map<String, (Color, Color)> _gradients = {
    'from-green-800 to-green-600': (AppColors.forest800, AppColors.forest600),
    'from-amber-700 to-amber-500': (Color(0xFF8B5E3C), Color(0xFFC4823A)),
    'from-rose-700 to-rose-500': (Color(0xFF9F1239), Color(0xFFE11D48)),
    'from-sky-800 to-sky-600': (Color(0xFF075985), Color(0xFF0284C7)),
    'from-violet-800 to-violet-600': (Color(0xFF5B21B6), Color(0xFF7C3AED)),
    'from-slate-800 to-slate-600': (Color(0xFF1E293B), Color(0xFF475569)),
  };

  factory WelfareCampaign.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
    return WelfareCampaign(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      goal: asInt(j['goal']),
      raised: asInt(j['raised']),
      daysLeft: j['daysLeft'] == null ? null : asInt(j['daysLeft']),
      backers: asInt(j['backers']),
      image: (j['image'] ?? '').toString(),
      color: (j['color'] ?? '').toString(),
      status: (j['status'] ?? 'active').toString(),
    );
  }
}
