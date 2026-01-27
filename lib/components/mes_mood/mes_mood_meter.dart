import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class MesMoodMeter extends StatelessWidget {
  final int score;
  final double size;

  const MesMoodMeter({super.key, required this.score, this.size = 60});

  // 1. CONFIG WARNA KARTU
  Color _getCardColor() {
    switch (score) {
      case 0: return Colors.green;
      case 1: return Colors.amber.shade700;
      case 2: return Colors.orange.shade800;
      case 3: return Colors.red.shade700;
      default: return Colors.grey;
    }
  }

  // 2. CONFIG ICON
  IconData _getMoodIcon() {
    switch (score) {
      case 0: return Icons.sentiment_very_satisfied_rounded; // 😄
      case 1: return Icons.sentiment_neutral_rounded;        // 😐
      case 2: return Icons.sentiment_dissatisfied_rounded;   // 😣
      case 3: return Icons.sentiment_very_dissatisfied;      // 😭
      default: return Icons.help_outline_rounded;
    }
  }

  // 3. TEXT STATUS
  String _getStatusText() {
    switch (score) {
      case 0: return "Normal (Healthy)";
      case 1: return "Mild Inflammation";
      case 2: return "Moderate Inflammation";
      case 3: return "Severe Inflammation";
      default: return "Unknown Status";
    }
  }

  // 4. POSISI INDICATOR
  Alignment _getAlignment() {
    switch (score) {
      case 0: return const Alignment(-0.95, 0.0);
      case 1: return const Alignment(-0.35, 0.0);
      case 2: return const Alignment(0.35, 0.0);
      case 3: return const Alignment(0.95, 0.0);
      default: return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = _getCardColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ===============================================
        // BAGIAN 1: KARTU UTAMA (ICON + TEXT)
        // ===============================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [mainColor.withOpacity(0.85), mainColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: mainColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              // --- ICON EMOTICON (BOUNCING) ---
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white, // Lingkaran Putih
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                        ],
                      ),
                      child: Icon(
                        _getMoodIcon(),
                        color: mainColor,
                        size: size,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // --- TITLE & SUBTITLE ---
              Text(
                "MES Score: $score",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getStatusText(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24), // Jarak Pemisah antara Kartu dan Barometer

        // ===============================================
        // BAGIAN 2: BAROMETER (DILUAR CONTAINER KARTU)
        // ===============================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              // Label Judul Kecil
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Severity Level", 
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, 
                    color: Colors.black54
                  )
                ),
              ),
              const SizedBox(height: 8),

              // BATANG METERAN
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade300, // Background abu buat track
                  gradient: const LinearGradient(
                    colors: [
                      Colors.green,    // 0
                      Colors.amber,    // 1
                      Colors.orange,   // 2
                      Colors.red,      // 3
                    ],
                    stops: [0.1, 0.4, 0.7, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // INDIKATOR GESER (DOT)
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      alignment: _getAlignment(),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: mainColor, width: 3), // Border ikut warna status
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 6),

              // Label Kiri Kanan (Warna Gelap karena di background putih)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Healthy", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Text("Severe", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}