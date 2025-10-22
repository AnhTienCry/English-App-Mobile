import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🆕 Add provider import
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/progress_notifier.dart'; // 🆕 Import progress notifier
import 'utils/auth_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupInterceptors();
  runApp(const EnglishApp());
}

class EnglishApp extends StatelessWidget {
  const EnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProgressNotifier>( // 🆕 Wrap with Provider
      create: (_) => progressNotifier,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'English Learning App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isLoading = true;
  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      // Nếu có token thì cho vào home, không thì login
      setState(() {
        isAuthenticated = accessToken != null && accessToken.isNotEmpty;
      });
    } catch (e) {
      print('Error checking auth status: $e');
      setState(() {
        isAuthenticated = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}