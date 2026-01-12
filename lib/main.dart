import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Disiapkan untuk nanti
import 'package:flutter_markdown/flutter_markdown.dart';

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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  // Konfigurasi URL (Tidak dipakai di Mode Dummy, tapi disiapkan)
  final String baseUrl = "http://10.0.2.2:8000"; 

  // --- FUNGSI PICK IMAGE ---
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _analysisResult = null; // Reset hasil lama saat ganti foto
        _chatMessages.clear();
      });
    }
  }

  // --- FUNGSI ANALYZE (MODE DUMMY) ---
  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    // [DUMMY] Simulasi loading network 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // [DUMMY] Data palsu seolah-olah dari Python API
    String dummyResponse = '''
    {
      "prediction": 2,
      "top5": [
        ["Vascular Pattern Loss", 0.89],
        ["Erythema Intensity", 0.76],
        ["Surface Granularity", 0.65],
        ["Mucosal Friability", 0.45],
        ["Vessel Tortuosity", 0.32]
      ],
      "all_features": {
        "Vascular Pattern Loss": 0.89,
        "Erythema Intensity": 0.76,
        "Surface Granularity": 0.65,
        "Mucosal Friability": 0.45,
        "Vessel Tortuosity": 0.32,
        "Texture Entropy": 0.25,
        "Color Saturation": 0.41,
        "Contrast": 0.12
      }
    }
    ''';

    try {
      setState(() {
        _analysisResult = json.decode(dummyResponse);
        
        // Pesan sambutan otomatis
        _chatMessages.add({
          'role': 'assistant',
          'content': '🎉 **Analysis Complete!**\n\nSaya mendeteksi skor **MES 2 (Moderate Inflammation)**.\n\nFitur dominan terlihat pada hilangnya pola vaskular dan intensitas eritema. Ada yang ingin ditanyakan?'
        });
      });
    } catch (e) {
      _showError("Error parsing dummy data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI CHAT (MODE DUMMY) ---
  Future<void> _sendMessage() async {
    if (_chatController.text.isEmpty) return;

    String userText = _chatController.text;
    
    setState(() {
      _chatMessages.add({'role': 'user', 'content': userText});
      _chatController.clear();
      _isLoading = true; // Loading kecil di chat
    });

    // [DUMMY] Simulasi mikir 1 detik
    await Future.delayed(const Duration(seconds: 1));

    String dummyAnswer = "";
    String lowerText = userText.toLowerCase();

    // Logika chatbot sederhana untuk testing
    if (lowerText.contains("score") || lowerText.contains("skor") || lowerText.contains("mes")) {
      dummyAnswer = "📊 **Skor MES: 2**\n\nIni menunjukkan peradangan tingkat sedang (Moderate). Ditandai dengan kemerahan yang nyata (erythema) dan hilangnya pola pembuluh darah.";
    } else if (lowerText.contains("fitur") || lowerText.contains("feature")) {
      dummyAnswer = "🔍 **Fitur Utama:**\n\nSistem mendeteksi **Vascular Pattern Loss (0.89)** sebagai fitur paling dominan, diikuti oleh **Erythema Intensity (0.76)**.";
    } else if (lowerText.contains("halo") || lowerText.contains("hi")) {
      dummyAnswer = "Halo! 👋 Saya ColonoTalk (Mode Demo). Silakan tanya tentang hasil analisis di atas.";
    } else {
      dummyAnswer = "Ini adalah respon simulasi. Pertanyaan Anda: _\"$userText\"_ akan dijawab oleh Llama-2 dengan konteks medis di versi Live nanti. 👍";
    }

    setState(() {
      _chatMessages.add({'role': 'assistant', 'content': dummyAnswer});
      _isLoading = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI WIDGETS ---

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
                    _buildUploadSection(),
                    
                    // Loading Spinner Utama
                    if (_isLoading && _analysisResult == null) 
                      const Padding(
                        padding: EdgeInsets.all(40), 
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text("Analyzing image...", style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      ),
                    
                    // Hasil Analisis
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)]
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ColonoMind", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("AI-Powered Analysis", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_image != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(_image!, height: 220, width: double.infinity, fit: BoxFit.cover),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _image = null),
                    icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.close, color: Colors.red)),
                  )
                ],
              )
            else
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100, 
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text("Gallery"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100, 
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
              ],
            ),
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
                      elevation: 5,
                      shadowColor: const Color(0xFF667eea).withOpacity(0.5)
                    ),
                    child: const Text("🚀 START ANALYSIS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    int score = _analysisResult!['prediction'];
    Color cardColor;
    String status;
    String emoji;

    switch (score) {
      case 0:
        cardColor = Colors.green;
        status = "Normal";
        emoji = "🟢";
        break;
      case 1:
        cardColor = Colors.amber.shade700;
        status = "Mild Inflammation";
        emoji = "🟡";
        break;
      case 2:
        cardColor = Colors.orange.shade800;
        status = "Moderate Inflammation";
        emoji = "🟠";
        break;
      case 3:
        cardColor = Colors.red.shade700;
        status = "Severe Inflammation";
        emoji = "🔴";
        break;
      default:
        cardColor = Colors.grey;
        status = "Unknown";
        emoji = "❓";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.withOpacity(0.85), cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cardColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 10),
          Text("MES Score: $score", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(status, style: GoogleFonts.inter(fontSize: 16, color: Colors.white.withOpacity(0.9), letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    Map<String, dynamic> features = _analysisResult!['all_features'];
    var topFeatures = features.entries.toList()..sort((a, b) => (b.value as double).abs().compareTo((a.value as double).abs()));
    var displayFeatures = topFeatures.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text("🔬 Key Features Detected", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: displayFeatures.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayFeatures[index].key, 
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (displayFeatures[index].value as double).toStringAsFixed(3),
                    style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF667eea), fontWeight: FontWeight.bold)
                  ),
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
      height: 450,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF667eea)),
              const SizedBox(width: 8),
              Text("ColonoTalk", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF667eea) : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: MarkdownBody(
                      data: msg['content']!,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(color: isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.4),
                        strong: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isUser ? Colors.white : Colors.black)
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: LinearProgressIndicator(minHeight: 2, color: Color(0xFF667eea), backgroundColor: Colors.white),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: "Ask about findings...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14)
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF667eea)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}