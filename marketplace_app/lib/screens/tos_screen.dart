import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_status_bar.dart';

class TosScreen extends StatefulWidget {
  const TosScreen({super.key});

  @override
  State<TosScreen> createState() => _TosScreenState();
}

class _TosScreenState extends State<TosScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://admin.makolino.com/legal/terms-user'));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenStatusBar(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.onSurface),
          title: Text(
            'Warunki korzystania',
            style: TextStyle(color: AppColors.onSurface),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
