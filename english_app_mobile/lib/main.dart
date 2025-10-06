import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupInterceptors();
  runApp(const EnglishApp());
}

class EnglishApp extends StatelessWidget {
  const EnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
