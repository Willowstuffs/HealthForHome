import 'package:flutter/material.dart';
import '../app_theme.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface,
              AppColors.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isKeyboardOpen ? 80 : 160,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isKeyboardOpen ? 0.3 : 1,
                  child: Image.asset('lib/images/aaa.png'),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}