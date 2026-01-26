import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.getHistory();
  }

  // Helper untuk mengubah skor angka jadi Label Teks
  String _getLabel(int score) {
    switch (score) {
      case 0: return "Normal";
      case 1: return "Mild Inflammation";
      case 2: return "Moderate Inflammation";
      case 3: return "Severe Inflammation";
      default: return "Unknown";
    }
  }

  // Helper untuk warna status
  Color _getStatusColor(int score) {
    if (score == 0) return Colors.green;
    if (score == 1) return Colors.amber.shade700;
    if (score >= 2) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analysis History", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No history yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final history = snapshot.data!;
          
          // --- LIST VIEW ---
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              // Balik urutan biar yang terbaru di atas (history.length - 1 - index)
              // Atau sorting di backend. Kita anggap backend kirim urut.
              // Kita pakai reversed index manual kalau backend append ke bawah:
              final item = history[history.length - 1 - index]; 
              
              final int score = item['score'] is int ? item['score'] : int.tryParse(item['score'].toString()) ?? 0;
              final String imageUrl = item['image_url'];
              
              // Formatting Tanggal Sederhana (String slicing)
              // backend kirim: "2026-01-26 10:00:00.123" -> ambil 16 karakter awal
              String dateStr = item['date'].toString();
              if (dateStr.length > 16) dateStr = dateStr.substring(0, 16);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    // --- 1. GAMBAR (Thumbnail) ---
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100, height: 100, color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    
                    // --- 2. INFO TEXT ---
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(score).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "MES $score",
                                    style: TextStyle(
                                      color: _getStatusColor(score),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                    ),
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getLabel(score),
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Confidence: High", // Nanti bisa ambil dari DB kalau disimpan
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}