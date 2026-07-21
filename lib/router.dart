import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';

import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/family_tree_screen.dart';
import 'screens/directory_screen.dart';
import 'screens/invitations_screen.dart';
import 'screens/matrimonial_edit_screen.dart';
import 'screens/matrimonial_gate_screen.dart';
import 'screens/matrimonial_detail_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/welfare_list_screen.dart';
import 'screens/welfare_detail_screen.dart';
import 'screens/welfare_impact_screen.dart';
import 'screens/welfare_new_campaign_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_verify_screen.dart';
import 'screens/onboarding_identity_screen.dart';
import 'screens/onboarding_lineage_screen.dart';
import 'screens/onboarding_heritage_screen.dart';
import 'screens/elder_home_screen.dart';
import 'screens/elder_verifications_screen.dart';
import 'screens/elder_verification_detail_screen.dart';
import 'screens/elder_members_screen.dart';
import 'screens/elder_conflict_screen.dart';
import 'screens/elder_archive_screen.dart';
import 'screens/elder_events_screen.dart';

const _publicPaths = {'/', '/login', '/register'};

GoRouter buildRouter(AuthService auth) {
  return GoRouter(
    // App opens on the login page when signed out (not the marketing landing).
    // The landing/about page stays reachable at '/' via the "About the Samaja"
    // link on login, and logged-in users are redirected on to their dashboard.
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.loaded) return null;
      final loggedIn = auth.isLoggedIn;
      final user = auth.user;
      final path = state.uri.path;
      final inOnboarding = path.startsWith('/onboarding');
      final isPublic = _publicPaths.contains(path) || inOnboarding;
      final needsOnboarding = loggedIn && !(user?.onboardingComplete ?? true);

      if (!loggedIn && !isPublic) return '/login';

      // A freshly-registered user must finish onboarding before anything else.
      if (needsOnboarding && !inOnboarding) return '/onboarding/identity';

      if (loggedIn && (path == '/login' || path == '/register')) {
        if (needsOnboarding) return '/onboarding/identity';
        return user!.isElder ? '/elder' : '/dashboard';
      }
      // Elder-only area: send members back to their dashboard.
      if (loggedIn &&
          path.startsWith('/elder') &&
          !(user?.isElder ?? false)) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Member area
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/family-tree', builder: (_, __) => const FamilyTreeScreen()),
      GoRoute(path: '/directory', builder: (_, __) => const DirectoryScreen()),
      GoRoute(path: '/invitations', builder: (_, __) => const InvitationsScreen()),
      // The gate, not the hub directly: it checks the age window, profile
      // completeness and elder approval, and only then renders the list.
      GoRoute(path: '/matrimonial', builder: (_, __) => const MatrimonialGateScreen()),
      // Declared before '/matrimonial/:id' so "edit" is never read as a
      // profile id.
      GoRoute(path: '/matrimonial/edit', builder: (_, __) => const MatrimonialEditScreen()),
      GoRoute(
        path: '/matrimonial/:id',
        builder: (_, s) => MatrimonialDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/welfare', builder: (_, __) => const WelfareListScreen()),
      GoRoute(path: '/welfare/impact', builder: (_, __) => const WelfareImpactScreen()),
      GoRoute(path: '/welfare/new', builder: (_, __) => const NewCampaignScreen()),
      GoRoute(
        path: '/welfare/donate/:id',
        builder: (_, s) => WelfareDonateScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/verify',
        builder: (_, __) => const ProfileVerifyScreen(),
      ),
      // Before '/profile/:id' so "edit" is not taken for a member id.
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (_, s) => ProfileScreen(id: s.pathParameters['id']!),
      ),

      // Onboarding
      GoRoute(path: '/onboarding/identity', builder: (_, __) => const OnboardingIdentityScreen()),
      GoRoute(path: '/onboarding/lineage', builder: (_, __) => const OnboardingLineageScreen()),
      GoRoute(path: '/onboarding/heritage', builder: (_, __) => const OnboardingHeritageScreen()),

      // Elder area
      GoRoute(path: '/elder', builder: (_, __) => const ElderHomeScreen()),
      GoRoute(path: '/elder/verifications', builder: (_, __) => const ElderVerificationsScreen()),
      GoRoute(
        path: '/elder/verifications/:id',
        builder: (_, s) =>
            ElderVerificationDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/elder/members', builder: (_, __) => const ElderMembersScreen()),
      GoRoute(
        path: '/elder/conflict/:id',
        builder: (_, s) => ElderConflictScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(path: '/elder/archive', builder: (_, __) => const ElderArchiveScreen()),
      GoRoute(path: '/elder/events', builder: (_, __) => const ElderEventsScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
