import 'package:flutter/material.dart';
import 'package:marketplace_app/widgets/screen_status_bar.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();

  bool isLoading = false;
  bool isResending = false;

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await ApiService().verifyCode(widget.email, codeController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konto zostało zweryfikowane. Możesz się zalogować.'),
        ),
      );

      // wracamy do ekranu poczatkowego i otwieramy LoginScreen zamiast czyscic caly stos
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => isResending = true);

    try {
      await ApiService().sendVerificationCode(widget.email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nowy kod weryfikacyjny został wysłany na Twój adres e-mail.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenStatusBar(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.onSurface,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weryfikacja Email',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wysłaliśmy 6-cyfrowy kod weryfikacyjny na adres:\n${widget.email}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: codeController,
                    label: 'Kod weryfikacyjny',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Podaj kod weryfikacyjny';
                      }
                      if (v.length != 6) {
                        return 'Kod musi składać się z 6 cyfr';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Zweryfikuj',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: (isLoading || isResending)
                          ? null
                          : _resendCode,
                      child: isResending
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : RichText(
                              text: TextSpan(
                                text: 'Nie otrzymałeś kodu? ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Wyślij ponownie',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          style: TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: AppColors.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.accent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }
}
