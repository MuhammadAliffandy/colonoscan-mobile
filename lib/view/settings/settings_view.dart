import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_view.dart';
import '../privacy/privacy_view.dart'; // 1. PASTIKAN IMPORT FILE INI

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _name = "Loading...";
  String _email = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Ambil data dari memori HP
  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('full_name') ?? "Guest User";
      _email = prefs.getString('email') ?? "guest@colonomind.com";
    });
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus Token & Data User
    
    // Kembali ke Login dan hapus semua history halaman sebelumnya
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const LoginView()), 
      (route) => false 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- PROFILE SECTION ---
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF667eea), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFf0f2f5),
                      child: Icon(Icons.person, size: 50, color: Color(0xFF667eea)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _email,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // --- MENU SETTINGS ---
            
            // 1. Change Password
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Change Password"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {}, 
            ),
            const Divider(),

            // 2. Language
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Language"),
              trailing: const Text("English (US)", style: TextStyle(color: Colors.grey)),
              onTap: () {},
            ),
            const Divider(),

            // 3. Privacy Policy (BARU DITAMBAHKAN)
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined), // Icon Privacy
              title: const Text("Privacy Policy"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigasi ke halaman Privacy Policy resmi
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyView()),
                );
              },
            ),
            const Divider(),

            // 4. App Version
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("App Version"),
              trailing: const Text("v1.0.0", style: TextStyle(color: Colors.grey)),
            ),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}