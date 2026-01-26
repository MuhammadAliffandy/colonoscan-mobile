import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './view/login/login_view.dart';
import './view/dashboard/dashboard_view.dart';

void main() {
  runApp(const ColonoMindApp());
}

class ColonoMindApp extends StatelessWidget {
  const ColonoMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ColonoMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      // Panggil widget Wrapper khusus untuk cek status login
      home: const AuthCheckWrapper(),
    );
  }
}

// Widget untuk mengecek Token saat aplikasi start
class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({super.key});

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    // Kasih delay dikit biar berasa "loading app" (opsional)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoggedIn = (token != null && token.isNotEmpty);
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Tampilan Splash Screen Sederhana
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Logic Penentuan Halaman
    if (_isLoggedIn) {
      return const DashboardView();
    } else {
      return const LoginView();
    }
  }
}