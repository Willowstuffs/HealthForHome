import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'login_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;
  bool canResend = false;
  int secondsLeft = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    secondsLeft = 60;
    canResend = false;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft == 0) {
        setState(() {
          canResend = true;
        });
        t.cancel();
      } else {
        setState(() {
          secondsLeft--;
        });
      }
    });
  }

  Future<void> _verify() async {
    if (codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kod musi mieć 6 cyfr")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final api = ApiService();

      await api.verifyCode(
        email: widget.email,
        code: codeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konto zostało aktywowane")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resend() async {
    try {
      final api = ApiService();
      await api.sendVerificationCode(widget.email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nowy kod został wysłany")),
      );

      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // blokada cofania
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Weryfikacja konta"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Wpisz 6-cyfrowy kod wysłany na email:",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verify,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Zweryfikuj"),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  canResend
                      ? "Wyślij kod ponownie"
                      : "Wyślij ponownie za $secondsLeft s",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}