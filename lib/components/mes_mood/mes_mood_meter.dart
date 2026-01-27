import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MesMoodMeter extends StatelessWidget {
  final int score;
  final double size;

  const MesMoodMeter({super.key, required this.score, this.size = 350});

  IconData _getIconForValue(int value) {
    switch (value) {
      case 0: return Icons.sentiment_very_satisfied_rounded;
      case 1: return Icons.sentiment_neutral;
      case 2: return Icons.sentiment_dissatisfied;
      case 3: return Icons.sentiment_very_dissatisfied;
      default: return Icons.help;
    }
  }

  Color _getColorForValue(int value) {
    switch (value) {
      case 0: return Colors.green;
      case 1: return Colors.amber;
      case 2: return Colors.deepOrange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    double finalSize = MediaQuery.of(context).size.width - 40;

    return SizedBox(
      height: finalSize / 1.5,
      width: finalSize,
      child: SfRadialGauge(
        enableLoadingAnimation: true,
        animationDuration: 2000,
        axes: <RadialAxis>[
          RadialAxis(
            startAngle: 180,
            endAngle: 0,
            minimum: 0,
            maximum: 4,
            showLabels: false,
            showTicks: false,
            canScaleToFit: true,
            radiusFactor: 0.95,

            // 🔥 1. WARNA SOLID (DIGANTI DISINI) 🔥
            ranges: <GaugeRange>[
              // 0-1: Hijau
              GaugeRange(
                startValue: 0, endValue: 1,
                color: Colors.green,
                startWidth: 1, endWidth: 1, 
                sizeUnit: GaugeSizeUnit.factor, // Biar Full Fill
              ),
              // 1-2: Kuning/Amber
              GaugeRange(
                startValue: 1, endValue: 2,
                color: Colors.amber,
                startWidth: 1, endWidth: 1, 
                sizeUnit: GaugeSizeUnit.factor,
              ),
              // 2-3: Orange
              GaugeRange(
                startValue: 2, endValue: 3,
                color: Colors.deepOrange,
                startWidth: 1, endWidth: 1, 
                sizeUnit: GaugeSizeUnit.factor,
              ),
              // 3-4: Merah
              GaugeRange(
                startValue: 3, endValue: 4,
                color: Colors.red,
                startWidth: 1, endWidth: 1, 
                sizeUnit: GaugeSizeUnit.factor,
              ),
            ],

            // 2. POINTERS (JARUM UTAMA + GARIS PEMBATAS)
            pointers: <GaugePointer>[
              // --- A. GARIS PEMBATAS (DIVIDERS) ---
              // Tetap kita pakai biar antar warna ada garis putih tegasnya
              _buildDividerPointer(1),
              _buildDividerPointer(2),
              _buildDividerPointer(3),

              // --- B. JARUM PENUNJUK UTAMA (HITAM) ---
              NeedlePointer(
                value: score + 0.5,
                enableAnimation: true,
                animationDuration: 1200,
                animationType: AnimationType.elasticOut,
                needleStartWidth: 2,
                needleEndWidth: 6,
                needleLength: 0.7, 
                needleColor: Colors.black87,
                knobStyle: const KnobStyle(knobRadius: 0), // Knob Bawaan Hilang
                tailStyle: const TailStyle(width: 6, length: 0.0, color: Colors.transparent),
              )
            ],

            annotations: <GaugeAnnotation>[
              _buildIconAnnotation(0),
              _buildIconAnnotation(1),
              _buildIconAnnotation(2),
              _buildIconAnnotation(3),

              // 3. KNOB CUSTOM SETENGAH LINGKARAN
              GaugeAnnotation(
                angle: 90, 
                positionFactor: 0.0, 
                widget: Container(
                  width: 60, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(60)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    width: 10, height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4))
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- HELPER: MEMBUAT GARIS PEMBATAS PUTIH ---
  NeedlePointer _buildDividerPointer(double value) {
    return NeedlePointer(
      value: value,
      enableAnimation: false, 
      needleColor: Colors.white, // Putih Solid (Lebih tegas daripada transparan)
      needleStartWidth: 3, // Sedikit ditebalkan biar kelihatan misah
      needleEndWidth: 3,   
      needleLength: 1,    
      knobStyle: const KnobStyle(knobRadius: 0),
      tailStyle: const TailStyle(length: 0),
    );
  }

  GaugeAnnotation _buildIconAnnotation(int index) {
    bool isActive = index == score;
    return GaugeAnnotation(
      widget: AnimatedScale(
        scale: isActive ? 1.3 : 0.9,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)]
          ),
          padding: const EdgeInsets.all(2),
          child: Icon(
            _getIconForValue(index),
            color: _getColorForValue(index),
            size: 28,
          ),
        ),
      ),
      angle: 180 + (45 * index) + 22.5,
      positionFactor: 0.7,
    );
  }
}