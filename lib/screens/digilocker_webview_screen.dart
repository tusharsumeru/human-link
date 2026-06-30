import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

/// Hosts the Surepass DigiLocker "Via Link" page in an in-app WebView.
///
/// Loads [url]; when navigation reaches [redirectUrl] (the consent callback),
/// the flow is done — pops with `true`. The caller then fetches the verified
/// Aadhaar via `download-aadhaar`. Pops with `false` if the user backs out.
class DigilockerWebViewScreen extends StatefulWidget {
  const DigilockerWebViewScreen({
    super.key,
    required this.url,
    required this.redirectUrl,
  });

  final String url;
  final String redirectUrl;

  @override
  State<DigilockerWebViewScreen> createState() =>
      _DigilockerWebViewScreenState();
}

class _DigilockerWebViewScreenState extends State<DigilockerWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (u) {
            _maybeFinish(u);
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (req) {
            if (_maybeFinish(req.url)) return NavigationDecision.prevent;
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Returns true (and pops) if [u] is the post-consent redirect.
  bool _maybeFinish(String u) {
    if (_done) return true;
    final r = widget.redirectUrl;
    final hit = (r.isNotEmpty && u.startsWith(r)) ||
        u.contains('digilocker-callback') ||
        u.contains('status=success');
    if (hit) {
      _done = true;
      if (mounted) Navigator.of(context).pop(true);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.forest800,
        foregroundColor: Colors.white,
        title: Text('Verify with DigiLocker',
            style: display(17, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          // Fallback: if the SDK finishes in-page without redirecting, the user
          // taps Done to trigger the Aadhaar fetch.
          TextButton(
            onPressed: () {
              if (!_done) {
                _done = true;
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: AppColors.forest700)),
        ],
      ),
    );
  }
}
