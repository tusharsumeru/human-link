import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/generated/app_localizations.dart';
import 'router.dart';
import 'screens/permissions_intro_screen.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'theme/app_theme.dart';

/// Set once the member has been through [PermissionsIntroScreen] — that
/// screen is then never shown again, on this device, for this install.
const _permissionsIntroDoneKey = 'permissions_intro_done';

class DaivajnaApp extends StatefulWidget {
  const DaivajnaApp({super.key});

  @override
  State<DaivajnaApp> createState() => _DaivajnaAppState();
}

class _DaivajnaAppState extends State<DaivajnaApp> {
  late final AuthService _auth;
  late final LocaleService _locale;
  late final dynamic _router;

  // null while the SharedPreferences flag hasn't loaded yet (a blank frame,
  // effectively instant); true shows the one-time permissions screen on top
  // of everything else; false lets the router's own content through.
  bool? _showPermissionsIntro;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _locale = LocaleService();
    _router = buildRouter(_auth);
    _auth.load();
    _locale.load();
    _loadPermissionsIntroFlag();
  }

  Future<void> _loadPermissionsIntroFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_permissionsIntroDoneKey) ?? false;
    if (mounted) setState(() => _showPermissionsIntro = !done);
  }

  Future<void> _dismissPermissionsIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsIntroDoneKey, true);
    if (mounted) setState(() => _showPermissionsIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _locale),
      ],
      child: Consumer<LocaleService>(
        builder: (context, locale, _) => MaterialApp.router(
          title: 'Daivajna Samaja',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: locale.locale,
          supportedLocales: LocaleService.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
          // Overlays the one-time permissions screen above the router's own
          // content (login/dashboard/etc. keep building underneath, just
          // hidden) rather than gating navigation itself — so the flag check
          // never races the router's own redirect logic.
          builder: (context, child) {
            if (_showPermissionsIntro == null) return const SizedBox.shrink();
            if (_showPermissionsIntro == true) {
              return PermissionsIntroScreen(onDone: _dismissPermissionsIntro);
            }
            return child!;
          },
        ),
      ),
    );
  }
}
