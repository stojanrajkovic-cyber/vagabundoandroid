import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/theme/app_theme.dart';

/// Ekvivalent SafariSheet / WidgetFullScreenContainer (iOS) — ugrađeni
/// WebView kao pun ekran (.fullScreenCover), ne bottom sheet. Koristi se za
/// Stay22 (smještaj, loadRequest) i DiscoverCars (rent-a-car, loadHtmlString
/// — JS widget embed, nema svoj URL).
class InAppWebViewScreen extends StatefulWidget {
  const InAppWebViewScreen({super.key, required this.url, this.title})
      : html = null,
        baseUrl = null;

  const InAppWebViewScreen.html(
      {super.key, required String this.html, this.title, this.baseUrl})
      : url = null;

  final Uri? url;
  final String? html;
  final String? title;

  /// Origin za loadHtmlString — bez ovoga stranica dobije null/opaque
  /// origin, pa affiliate embed skripte (npr. DiscoverCars) koje provjere
  /// Cross-Origin-Resource-Policy na svojim iframe pozivima padaju sa
  /// net::ERR_BLOCKED_BY_RESPONSE.
  final String? baseUrl;

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      );
    if (widget.html != null) {
      _controller.loadHtmlString(widget.html!, baseUrl: widget.baseUrl);
    } else if (widget.url != null) {
      _controller.loadRequest(widget.url!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? ''),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(color: context.accent),
        ],
      ),
    );
  }
}
