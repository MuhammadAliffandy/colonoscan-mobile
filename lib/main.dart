import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Library HTTP aktif
import 'package:image/image.dart' as img;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

// --- KONFIGURASI URL API ---
// GANTI INI SESUAI DEVICE KAMU:
// 1. Android Emulator: Gunakan "http://10.0.2.2:8000"
// 2. HP Fisik / iOS Simulator: Gunakan IP Laptop, misal "http://192.168.1.15:8000"
const String baseUrl = "http://10.0.2.2:8000"; 

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

  // --- FUNGSI PICK IMAGE ---
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

    if (pickedFile != null) {
      // 1. Kasih loading sebentar biar user tau ada proses
      setState(() => _isLoading = true);

      // 2. PROSES GAMBAR (CROP & ZOOM)
      // Ini langkah yang sebelumnya hilang!
      File original = File(pickedFile.path);
      File processed = await preprocessImage(original); 

      // 3. Masukkan gambar yang SUDAH DI-PROCESS ke state
      setState(() {
        _image = processed; // Pakai file yang sudah di-zoom
        _analysisResult = null; 
        _chatMessages.clear();
        _isLoading = false; // Matikan loading
      });
    }
  }

  Future<File> preprocessImage(File originalFile) async {
    // 1. Baca bytes dari file asli
    final bytes = await originalFile.readAsBytes();
    
    // 2. Decode gambar menjadi objek yang bisa diedit
    img.Image? src = img.decodeImage(bytes);
    
    if (src == null) return originalFile; // Safety check

    // --- LOGIKA PYTHON: crop_center_zoom (ZOOM_LEVEL = 0.75) ---
    double zoomFactor = 0.75;
    
    // Hitung dimensi terkecil (min_dim)
    int minDim = min(src.width, src.height);
    
    // Hitung ukuran crop (crop_size)
    int cropSize = (minDim * zoomFactor).toInt();
    
    // Hitung titik tengah (left, top)
    int x = (src.width - cropSize) ~/ 2;
    int y = (src.height - cropSize) ~/ 2;

    // Lakukan Cropping
    img.Image cropped = img.copyCrop(
      src, 
      x: x, 
      y: y, 
      width: cropSize, 
      height: cropSize
    );

    // 3. Resize kembali ke ukuran standar (opsional, misal 256x256 agar ringan)
    // Kalau mau persis pixelnya, bisa skip resize ini. 
    // Tapi biar upload cepat, kita resize ke 256x256 (sesuai IMG_SIZE python kamu).
    img.Image resized = img.copyResize(cropped, width: 256, height: 256);

    // 4. Simpan hasil crop ke file baru (Format JPG/PNG)
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final processedFile = File(savePath);
    
    // Encode ke JPG (kualitas 90)
    await processedFile.writeAsBytes(img.encodeJpg(resized, quality: 90));

    return processedFile;
  }

  // --- FUNGSI ANALYZE (REAL API CONNECT) ---
  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Buat Request Multipart
      var uri = Uri.parse("$baseUrl/predict");
      var request = http.MultipartRequest('POST', uri);

      // 2. Attach File Gambar
      var pic = await http.MultipartFile.fromPath(
                                                  "file", 
                                                  _image!.path,
                                                  contentType: MediaType('image', 'jpeg') // <--- KITA PAKSA LABELNYA
                                                );
      request.files.add(pic);

      // 3. Kirim ke Server
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 4. Cek Status Code
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          _analysisResult = data;
          
          // Ambil data real dari response untuk pesan pembuka
          int score = data['prediction'];
          String msg = "🎉 **Analysis Complete!**\n\nI detected an **MES Score of $score** from this image.";
          
          if (data['top5'] != null && (data['top5'] as List).isNotEmpty) {
            var topFeature = data['top5'][0][0];
            msg += "\n\nThe most dominant feature is **$topFeature**.";
          }

          _chatMessages.add({
            'role': 'assistant',
            'content': msg
          });
        });
      } else {
        // Error dari Server (misal 400 atau 500)
        var errorData = json.decode(response.body);
        _showError("Server Error: ${errorData['detail'] ?? 'Unknown error'}");
      }

    } catch (e) {
      // Error Koneksi (misal server mati atau beda wifi)
      _showError("Connection Error: Pastikan Server Nyala & IP Benar.\nError: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI CHAT (LOGIKA LOKAL - SEMENTARA) ---
  // Karena API kamu belum punya endpoint /chat, kita pakai logika di HP dulu
  // tapi berdasarkan DATA ASLI hasil analisis API.
  // --- FUNGSI CHAT (CONNECTED TO API /chat) ---
  Future<void> _sendMessage() async {
    if (_chatController.text.isEmpty) return;

    String userText = _chatController.text;
    
    // 1. Tampilkan pesan User dulu di layar (biar responsif)
    setState(() {
      _chatMessages.add({'role': 'user', 'content': userText});
      _chatController.clear();
      _isLoading = true; // Munculkan loading chat
    });

    try {
      // 2. Siapkan Konteks Data
      // Kita kirim hasil analisis (_analysisResult) ke API
      // supaya AI tau "Gambar apa yang sedang dibahas?"
      Map<String, dynamic> contextData = _analysisResult ?? {};

      // 3. Kirim Request ke API
      // LLM butuh mikir, jadi timeout kita set agak lama (misal 30-60 detik)
      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "message": userText,
          "context_data": contextData
        }),
      ).timeout(const Duration(seconds: 60)); 

      // 4. Proses Jawaban Server
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String aiReply = data['reply']; // Ambil jawaban dari API

        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': aiReply});
        });
      } else {
        // Kalau server error (misal model belum load)
        setState(() {
          _chatMessages.add({
            'role': 'assistant', 
            'content': "⚠️ **Server Error:** Failed get response from ColonoTalk."
          });
        });
      }

    } catch (e) {
      // Kalau koneksi putus
      setState(() {
        _chatMessages.add({
          'role': 'assistant', 
          'content': "⚠️ **Connection Error:** Cant connect the server.\n\nDetail: $e"
        });
      });
    } finally {
      // Matikan loading apapun hasilnya
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      )
    );
  }

  // --- UI WIDGETS (SAMA SEPERTI SEBELUMNYA) ---

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
                    
                    if (_isLoading && _analysisResult == null) 
                      const Padding(
                        padding: EdgeInsets.all(40), 
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text("Uploading & Analyzing...", style: TextStyle(color: Colors.grey)),
                          ],
                        )
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
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/images/colon.png', // Sesuai nama file
              width: 50,
              height: 50,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("ColonoMind", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("AI-Powered Analysis (Local)", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const SizedBox(width: 15),
                   Container(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/images/endoscope.png', // Sesuai nama file
              width: 50,
              height: 50,
            ),
          ),
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
            // --- LOGIKA UTAMA: JIKA ADA GAMBAR TAMPILKAN BULAT, JIKA TIDAK TAMPILKAN PLACEHOLDER ---
            if (_image != null)
              // --- TAMPILAN BULAT (ENDOSKOPI STYLE) ---
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1), // Background hitam ala medis
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: ClipOval( // Masking Lingkaran
                        child: Image.file(
                          _image!, 
                          height: 220, 
                          width: 220, 
                          fit: BoxFit.cover, 
                        ),
                      ),
                    ),
                  ),
                  // Tombol Hapus (X)
                  IconButton(
                    onPressed: () => setState(() => _image = null),
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
            
            // --- TOMBOL PILIHAN (KAMERA / GALERI) ---
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
            
            // --- TOMBOL START ANALYSIS ---
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
    // Handling null safety, default to 0
    int score = _analysisResult?['prediction'] ?? 0;
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
    if (_analysisResult == null || _analysisResult!['all_features'] == null) return const SizedBox();

    Map<String, dynamic> features = _analysisResult!['all_features'];
    var topFeatures = features.entries.toList()..sort((a, b) => (b.value as double).abs().compareTo((a.value as double).abs()));
    var displayFeatures = topFeatures.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text("🔬 Key Features Detected (Real Data)", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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