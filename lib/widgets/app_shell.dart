import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../screens/conversations_screen.dart';
import '../screens/create_post_flow.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import 'pexels_image.dart';

/// Avatar for the logged-in user: prefers the uploaded photo (remote URL, then
/// local file), falling back to name initials.
Widget userAvatar(AppUser user,
    {double size = 40, Color? borderColor, double borderWidth = 0}) {
  if (user.photoUrl.isNotEmpty) {
    return PexelsImage(
        url: user.photoUrl,
        name: user.name,
        size: size,
        borderColor: borderColor,
        borderWidth: borderWidth);
  }
  if (user.photoPath.isNotEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? AppColors.forest700, width: borderWidth)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(File(user.photoPath), fit: BoxFit.cover),
    );
  }
  return AvatarImage(
      avatarKey: user.avatar,
      name: user.name,
      size: size,
      borderColor: borderColor,
      borderWidth: borderWidth);
}

class NavDest {
  final IconData icon;
  final String label;
  final String route;
  const NavDest(this.icon, this.label, this.route);
}

/// Member sidebar/nav items. Labels are localized at call time (not `const`)
/// since they depend on the active [AppLocalizations].
List<NavDest> memberNavOf(AppLocalizations t) => [
      NavDest(Icons.grid_view_rounded, t.navDashboard, '/dashboard'),
      NavDest(Icons.park_rounded, t.navFamilyTree, '/family-tree'),
      NavDest(Icons.navigation_rounded, t.navInvitations, '/invitations'),
      NavDest(Icons.map_rounded, t.navDirectory, '/directory'),
      NavDest(Icons.favorite_rounded, t.navMatrimonial, '/matrimonial'),
      NavDest(Icons.groups_rounded, t.navWelfare, '/welfare'),
      NavDest(Icons.temple_hindu_rounded, t.navPurohit, '/purohit'),
    ];

List<NavDest> elderNavOf(AppLocalizations t) => [
      NavDest(Icons.park_rounded, t.navLineageTree, '/elder'),
      NavDest(
          Icons.shield_rounded, t.navMemberRequests, '/elder/verifications'),
      NavDest(Icons.inventory_2_rounded, t.navArchives, '/elder/archive'),
      NavDest(Icons.groups_rounded, t.navCommunity, '/elder/members'),
      NavDest(
          Icons.forum_rounded, t.navModeration, '/elder/conflict/ck-1'),
      NavDest(Icons.settings_rounded, t.navSettings, '/elder/events'),
    ];

/// The authenticated app frame: a forest sidebar drawer, a translucent top bar
/// with bell + avatar, and a mobile bottom nav — ported from SidebarLayout +
/// BottomNav. Wrap any logged-in page body in this.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.currentRoute,
    this.scrollable = true,
    this.padding = const EdgeInsets.all(16),
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final String? currentRoute;
  final bool scrollable;
  final EdgeInsets padding;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final isElder = user?.isElder ?? false;
    final t = AppLocalizations.of(context);
    final nav = isElder ? elderNavOf(t) : memberNavOf(t);

    final body = Padding(padding: padding, child: child);

    // Device back-button policy: pop a drilled-in page if there is one; from a
    // non-home top-level tab, go back to the home tab; only on the home tab does
    // back exit the app.
    final homeRoute = isElder ? '/elder' : '/dashboard';
    final path = GoRouterState.of(context).uri.path;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else if (path != homeRoute) {
          context.go(homeRoute);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      drawer: _Sidebar(nav: nav, isElder: isElder),
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        centerTitle: true,
        title: Text(title,
            style: display(20, color: AppColors.forest700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: AppColors.forest700),
            tooltip: t.navMessages,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConversationsScreen()),
            ),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: GestureDetector(
                onTap: () => context.push('/profile/me'),
                child: userAvatar(
                  user,
                  size: 34,
                  borderColor:
                      isElder ? AppColors.gold500 : AppColors.forest700,
                  borderWidth: 2,
                ),
              ),
            ),
        ],
      ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: _BottomBar(isElder: isElder, current: currentRoute),
        body: scrollable ? SingleChildScrollView(child: body) : body,
      ),
    );
  }
}

/// English / Hindi / Kannada toggle, shown above Profile/Logout in the drawer.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  static const _options = [
    (Locale('en'), 'English'),
    (Locale('hi'), 'हिन्दी'),
    (Locale('kn'), 'ಕನ್ನಡ'),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(t.commonLanguage,
              style: body(12, color: Colors.white54)),
          const Spacer(),
          for (final (loc, label) in _options)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => locale.setLocale(loc),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: locale.locale == loc
                        ? AppColors.gold500.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: locale.locale == loc
                          ? AppColors.gold500
                          : Colors.white24,
                    ),
                  ),
                  child: Text(label,
                      style: body(11,
                          weight: FontWeight.w600,
                          color: locale.locale == loc
                              ? AppColors.gold500
                              : Colors.white70)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.nav, required this.isElder});
  final List<NavDest> nav;
  final bool isElder;

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.path;
    final t = AppLocalizations.of(context);

    return Drawer(
      backgroundColor: AppColors.forest900,
      child: Container(
        decoration: const BoxDecoration(gradient: AppGradients.sidebar),
        child: SafeArea(
          child: Column(
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.park_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.appName,
                            style: display(14, color: Colors.white)),
                        Text(t.appTagline,
                            style: body(11, color: AppColors.forest300)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Nav
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  children: [
                    for (final d in nav)
                      _NavTile(
                        dest: d,
                        active: current == d.route ||
                            (d.route != '/dashboard' &&
                                d.route != '/elder' &&
                                current.startsWith(d.route)),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Bottom: profile + logout
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    const _LanguagePicker(),
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded,
                          color: Colors.white70, size: 20),
                      title: Text(t.myProfile,
                          style: body(13, color: Colors.white70)),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile/me');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: Color(0xFFFCA5A5), size: 20),
                      title: Text(t.logout,
                          style: body(13, color: const Color(0xFFFCA5A5))),
                      onTap: () async {
                        final auth = context.read<AuthService>();
                        final router = GoRouter.of(context);
                        Navigator.pop(context); // close the drawer first
                        await auth.logout();
                        router.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.dest, required this.active});
  final NavDest dest;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active
            ? AppColors.gold500.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            context.go(dest.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(dest.icon,
                    size: 18,
                    color: active
                        ? AppColors.gold500
                        : Colors.white.withValues(alpha: 0.65)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(dest.label,
                      style: body(13,
                          weight: FontWeight.w600,
                          color: active
                              ? AppColors.gold500
                              : Colors.white.withValues(alpha: 0.65))),
                ),
                if (active)
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.gold500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.isElder, required this.current});
  final bool isElder;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final path = current ?? GoRouterState.of(context).uri.path;
    final t = AppLocalizations.of(context);

    // Tabs shown to the left of the center action, and to the right.
    final leftItems = isElder
        ? [
            NavDest(Icons.park_rounded, t.navTree, '/elder'),
            NavDest(Icons.shield_rounded, t.navRequests, '/elder/verifications'),
          ]
        : [
            NavDest(Icons.grid_view_rounded, t.navHome, '/dashboard'),
          ];
    final rightItems = isElder
        ? [
            NavDest(Icons.groups_rounded, t.navMembers, '/elder/members'),
            NavDest(Icons.inventory_2_rounded, t.navArchive, '/elder/archive'),
          ]
        : [
            NavDest(Icons.park_rounded, t.navTree, '/family-tree'),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0xFFE5DDD0))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final d in leftItems) _tab(context, d, path),
              // Center create button — members only.
              if (!isElder) _createButton(context),
              for (final d in rightItems) _tab(context, d, path),
              // Elders keep the drawer-opening "More" tab; members don't need
              // one (their nav is fully covered by leftItems/create/right).
              if (isElder) _moreTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, NavDest d, String path) {
    final active = path == d.route;
    return Expanded(
      child: InkWell(
        onTap: () => context.go(d.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(d.icon,
                size: 20,
                color: active ? AppColors.forest800 : const Color(0xFF9CA3AF)),
            const SizedBox(height: 3),
            Text(d.label,
                style: body(11,
                    color:
                        active ? AppColors.forest800 : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _moreTab(BuildContext context) {
    return Expanded(
      child: Builder(
        builder: (ctx) => InkWell(
          onTap: () => Scaffold.of(ctx).openDrawer(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_rounded,
                  size: 20, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 3),
              Text(AppLocalizations.of(context).navMore,
                  style: body(11, color: const Color(0xFF9CA3AF))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createButton(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => showCreateOptions(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 30,
              decoration: BoxDecoration(
                gradient: AppGradients.forest,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(Icons.add_rounded,
                  size: 22, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(AppLocalizations.of(context).navPost,
                style: body(11,
                    weight: FontWeight.w600, color: AppColors.forest800)),
          ],
        ),
      ),
    );
  }
}
