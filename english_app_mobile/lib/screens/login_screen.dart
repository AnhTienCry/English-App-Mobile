import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController(text: 'admin@example.com');
  final passCtrl = TextEditingController(text: 'admin123');
  bool loading = false;
  String? message;

  Future<void> login() async {
    setState(() {
      loading = true;
      message = null;
    });

    try {
      final res = await dio.post('/auth/login', data: {
        'email': emailCtrl.text,
        'password': passCtrl.text,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', res.data['accessToken']);
      await prefs.setString('refreshToken', res.data['refreshToken']);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } catch (e) {
      setState(() {
        message = 'Login failed';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : login,
              child: loading ? const CircularProgressIndicator() : const Text('Sign in'),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(message!, style: const TextStyle(color: Colors.red)),
              )
          ],
        ),
      ),
    );
  }
}
