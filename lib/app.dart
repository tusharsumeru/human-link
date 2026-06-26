import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

class DaivajnaApp extends StatefulWidget {
  const DaivajnaApp({super.key});

  @override
  State<DaivajnaApp> createState() => _DaivajnaAppState();
}

class _DaivajnaAppState extends State<DaivajnaApp> {
  late final AuthService _auth;
  late final dynamic _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _router = buildRouter(_auth);
    _auth.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _auth,
      child: MaterialApp.router(
        title: 'Daivajna Samaja',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
