import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api.dart';
import '../../view/dashboard/dashboard_view.dart';
import '../../view/regis/regis_view.dart';
import '../../services/smart_auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize SMART Deep Link listener
    SmartAuthService.initDeepLinkListener((result) async {
      if (result != null && result.containsKey('access_token')) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['access_token']);
        
        if (result.containsKey('patient')) {
          await prefs.setString('full_name', 'Patient: ${result['patient']}');
          await prefs.setString('role', 'smart_user');
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const DashboardView())
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['error'] ?? "SMART Login Failed !!"), 
              backgroundColor: Colors.red
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    SmartAuthService.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _doLogin() async {
   setState(() => _isLoading = true);
    
    final result = await ApiService.login(_emailController.text, _passController.text);
    
    setState(() => _isLoading = false);

    if (result.containsKey('token')) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('token', result['token']);

      await prefs.setString('role', result['user']['role'] ?? 'user');
      
      if (result.containsKey('user')) {
        await prefs.setString('full_name', result['user']['full_name'] ?? 'User');
        await prefs.setString('email', result['user']['email'] ?? 'user@email.com');
      }
      
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const DashboardView())
      );
    }else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['msg'] ?? "Login Failed !!"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/images/colonomind-logo-new.png',
              width: 180,
              height: 180,
              fit: BoxFit.cover,
            ),
          
            Text(
              "Welcome Back!", 
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _doLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 95, 159, 211),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  child: const Text("LOGIN"),
                ),
            const SizedBox(height: 16),
            if (!_isLoading) 
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    await SmartAuthService.login();
                    // Result will be handled by initDeepLinkListener
                  } catch (e) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                },
                icon: const Icon(Icons.local_hospital),
                label: const Text("Login via Hospital System (SMART)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  RegisterView()));
              },
              child: const Text("Don't have an account? Register"),
            )
          ],
        ),
      ),
    );
  }
}