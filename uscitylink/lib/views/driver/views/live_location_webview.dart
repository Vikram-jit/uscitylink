import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/theme/app_text.dart';

/// Loads a Samsara live-share URL in-app rather than handing off to an
/// external browser, so the driver stays inside the app's own navigation.
class LiveLocationWebView extends StatefulWidget {
  final String url;
  final String title;

  const LiveLocationWebView({
    super.key,
    required this.url,
    this.title = 'Live Location',
  });

  @override
  State<LiveLocationWebView> createState() => _LiveLocationWebViewState();
}

class _LiveLocationWebViewState extends State<LiveLocationWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          backgroundColor: TColors.navyHeader,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          title: Text(widget.title,
              style: AppText.titleLg.copyWith(color: Colors.white)),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: TColors.navyHeader),
              ),
          ],
        ),
      ),
    );
  }
}
