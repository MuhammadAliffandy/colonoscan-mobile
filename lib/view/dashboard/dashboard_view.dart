import 'dart:io';
import 'dart:math';
import 'package:ColonoMind/view/admin/admin_user_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../history/history_view.dart';
import '../settings/settings_view.dart';
import '../../api.dart';


class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  File? _image;          
  File? _originalImage;  
  String _userRole = 'user'; 
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'user';
    });
  }

  // --- FUNGSI PICK IMAGE ---
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

    if (pickedFile != null) {
      setState(() => _isLoading = true);

      File original = File(pickedFile.path);
      File processed = await preprocessImage(original);

      setState(() {
        _originalImage = original; // 1. Simpan Original untuk Upload
        _image = processed;        // 2. Simpan Processed untuk Tampilan UI
        
        _analysisResult = null;
        _chatMessages.clear();
        _isLoading = false;
      });
    }
  }

  Future<File> preprocessImage(File originalFile) async {
    final bytes = await originalFile.readAsBytes();
    img.Image? src = img.decodeImage(bytes);
    
    if (src == null) return originalFile;

    double zoomFactor = 0.75;
    int minDim = min(src.width, src.height);
    int cropSize = (minDim * zoomFactor).toInt();
    int x = (src.width - cropSize) ~/ 2;
    int y = (src.height - cropSize) ~/ 2;

    img.Image cropped = img.copyCrop(src, x: x, y: y, width: cropSize, height: cropSize);
    img.Image resized = img.copyResize(cropped, width: 256, height: 256);

    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final processedFile = File(savePath);
    
    await processedFile.writeAsBytes(img.encodeJpg(resized, quality: 90));

    return processedFile;
  }

  Future<void> _analyzeImage() async {
    if (_originalImage == null) return; // Pakai Original Image

    setState(() => _isLoading = true);

    try {
      // Panggil API Service (Cuma 1 Baris!)
      final resultData = await ApiService.predictImage(_originalImage!);

      // Update UI dengan Data Sukses
      setState(() {
        _analysisResult = resultData;
        
        int score = resultData['prediction'];
        String label = resultData['label'] ?? 'Unknown';
        
        String msg = "🎉 **Analysis Complete!**\n\nI detected an **MES Score of $score** ($label).";
        msg += "\n\nThe original image has been saved to your history.";

        _chatMessages.add({
          'role': 'assistant',
          'content': msg
        });
      });

    } catch (e) {
      // Handle Error dari Service
      // Kita hapus prefix "Exception:" biar rapi
      String errorMsg = e.toString().replaceAll("Exception: ", "");
      _showError(errorMsg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI CHAT (VERSI RINGKAS) ---
  Future<void> _sendMessage() async {
    if (_chatController.text.isEmpty) return;
    String userText = _chatController.text;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': userText});
      _chatController.clear();
      _isLoading = true;
    });

    try {
      Map<String, dynamic> contextData = _analysisResult ?? {};
      
      // Panggil API Service
      String reply = await ApiService.chatWithBot(userText, contextData);

      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': reply});
      });

    } catch (e) {
      String errorMsg = e.toString().replaceAll("Exception: ", "");
      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': "⚠️ $errorMsg"});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onNavBarTapped(int index) {
     if (index == 0) return; 
     if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryView()));
     if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsView()));
     
     if (index == 3 && _userRole == 'admin') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserListView()));
     }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUploadSection(), // UI Lingkaran ada di sini
                    if (_isLoading && _analysisResult == null) 
                      const Padding(
                        padding: EdgeInsets.all(40), 
                        child: CircularProgressIndicator()
                      ),
                    if (_analysisResult != null) ...[
                      const SizedBox(height: 20),
                      _buildPredictionCard(),
                      const SizedBox(height: 16),
                      _buildFeatureGrid(),
                      const SizedBox(height: 16),
                      _buildChatSection(),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, 
        onTap: _onNavBarTapped,
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "History"),
          const BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
          if (_userRole == 'admin')
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined), 
              label: "Admin"
          ),
        ],
      ),
    );
  }

  // --- WIDGET HEADER (SAMA) ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/colon.png', width: 50, height: 50),
          const SizedBox(width: 15),
          Column(
            children: [
              Text("ColonoMind", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("AI-Powered Analysis", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const SizedBox(width: 15),
          Image.asset('assets/images/endoscope.png', width: 50, height: 50),
        ],
      ),
    );
  }

  // --- WIDGET UPLOAD SECTION (UI LINGKARAN DIKEMBALIKAN) ---
  Widget _buildUploadSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- UI LINGKARAN (Endoscopy View) ---
            if (_image != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  // Container Background Hitam ala Medis
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                          ]
                        ),
                        // 🟢 Ganti ClipRRect jadi ClipOval untuk Lingkaran
                        child: ClipOval( 
                          child: Image.file(
                            _image!, // Tetap tampilkan yang processed (zoom) biar user enak lihatnya
                            height: 220, 
                            width: 220, 
                            fit: BoxFit.cover, 
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tombol X
                  IconButton(
                    onPressed: () => setState(() { _image = null; _originalImage = null; }),
                    icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.close, color: Colors.red)),
                  )
                ],
              )
            else
              // --- TAMPILAN PLACEHOLDER (TAP TO UPLOAD) ---
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3), style: BorderStyle.solid, width: 2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, size: 50, color: Color(0xFF667eea)),
                      SizedBox(height: 10),
                      Text("Tap to Upload Image", style: TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // TOMBOL PILIHAN
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text("Camera"))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text("Gallery"))),
              ],
            ),
            
            // TOMBOL START
            if (_image != null && _analysisResult == null && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _analyzeImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea), 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("🚀 START ANALYSIS", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ... (Sisa Widget Helper: _buildPredictionCard, _buildFeatureGrid, _buildChatSection SAMA SAJA) ...
  Widget _buildPredictionCard() {
    int score = _analysisResult?['prediction'] ?? 0;
    Color cardColor; String status; String emoji;
    switch (score) {
      case 0: cardColor = Colors.green; status = "Normal"; emoji = "🟢"; break;
      case 1: cardColor = Colors.amber.shade700; status = "Mild Inflammation"; emoji = "🟡"; break;
      case 2: cardColor = Colors.orange.shade800; status = "Moderate Inflammation"; emoji = "🟠"; break;
      case 3: cardColor = Colors.red.shade700; status = "Severe Inflammation"; emoji = "🔴"; break;
      default: cardColor = Colors.grey; status = "Unknown"; emoji = "❓";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cardColor.withOpacity(0.85), cardColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cardColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Text(emoji, style: const TextStyle(fontSize: 40))),
          const SizedBox(height: 10),
          Text("MES Score: $score", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(status, style: GoogleFonts.inter(fontSize: 16, color: Colors.white.withOpacity(0.9), letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    if (_analysisResult == null || _analysisResult!['all_features'] == null) return const SizedBox();
    Map<String, dynamic> features = _analysisResult!['all_features'];
    var topFeatures = features.entries.toList()..sort((a, b) => (b.value as double).abs().compareTo((a.value as double).abs()));
    var displayFeatures = topFeatures.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text("🔬 Key Features Detected (Real Data)", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87))),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: displayFeatures.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(displayFeatures[index].key, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text((displayFeatures[index].value as double).toStringAsFixed(3), style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF667eea), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChatSection() {
    return Container(
      height: 450, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF667eea)), const SizedBox(width: 8), Text("ColonoTalk", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold))]),
          const Divider(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index]; final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(color: isUser ? const Color(0xFF667eea) : Colors.grey[100], borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: isUser ? const Radius.circular(16) : Radius.zero, bottomRight: isUser ? Radius.zero : const Radius.circular(16))),
                    child: MarkdownBody(data: msg['content']!, styleSheet: MarkdownStyleSheet(p: GoogleFonts.inter(color: isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.4), strong: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isUser ? Colors.white : Colors.black))),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator(minHeight: 2, color: Color(0xFF667eea), backgroundColor: Colors.white)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
            child: Row(children: [Expanded(child: TextField(controller: _chatController, decoration: const InputDecoration(hintText: "Ask about findings...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)), onSubmitted: (_) => _sendMessage())), IconButton(icon: const Icon(Icons.send_rounded, color: Color(0xFF667eea)), onPressed: _sendMessage)]),
          ),
        ],
      ),
    );
  }
}