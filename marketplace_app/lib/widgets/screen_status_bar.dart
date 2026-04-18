import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const SystemUiOverlayStyle kLightScreenStatusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

class ScreenStatusBar extends StatelessWidget {
  final Widget child;

  const ScreenStatusBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kLightScreenStatusBarStyle,
      child: child,
    );
  }
}
