import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets/auth_scaffold.dart';
//import '../../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      //final api = ApiService();

      // await api.changePassword(
      //   oldPassword: oldPasswordController.text,
      //   newPassword: newPasswordController.text,
      // );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasło zostało zmienione'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              "Zmień hasło",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Wprowadź nowe dane logowania",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 32),

            _buildTextField(
              oldPasswordController,
              'Aktualne hasło',
              obscureText: true,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              newPasswordController,
              'Nowe hasło',
              obscureText: true,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              repeatPasswordController,
              'Powtórz nowe hasło',
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Pole wymagane';
                }

                if (v != newPasswordController.text) {
                  return 'Hasła nie są identyczne';
                }

                return null;
              },
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: 250,
              height: 53,
              child: ElevatedButton(
                onPressed:
                    isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor:
                      AppColors.livingColor10,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Zapisz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType =
        TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator ??
          (v) => v == null || v.isEmpty
              ? 'Pole wymagane'
              : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 16),
        filled: true,
        fillColor: AppColors.onPrimary,
        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    repeatPasswordController.dispose();

    super.dispose();
  }
}