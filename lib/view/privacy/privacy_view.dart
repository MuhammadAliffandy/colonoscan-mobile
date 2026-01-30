import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  // --- Color Palette (Sesuai HTML) ---
  final Color _bgColor = const Color(0xFFF8F9FA);
  final Color _accentColor = const Color(0xFF667EEA); // ColonoMind Blue
  final Color _textColor = const Color(0xFF2C3E50);
  final Color _warningColor = const Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Back Button (Di luar kertas)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, size: 18, color: Colors.grey[600]),
                  label: Text(
                    "Return to Application",
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),

              // 2. Document Paper (Efek Kertas)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0), // Padding dalam kertas
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  // Border atas warna biru (Aksen)
                  border: Border(
                    top: BorderSide(color: _accentColor, width: 5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    Center(
                      child: Text(
                        "PRIVACY POLICY",
                        style: GoogleFonts.merriweather(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "EFFECTIVE DATE: JANUARY 28, 2026 | VERSION 1.0",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 30),

                    // --- CONTENT SECTIONS ---
                    
                    _buildSectionTitle("1. Introduction"),
                    _buildParagraph(
                      'This Privacy Policy ("Policy") governs the collection, use, and disclosure of personal data by ColonoMind ("Company," "we," "us," or "our") in connection with the use of our AI-powered clinical decision support system. We are committed to maintaining the confidentiality, integrity, and security of any medical information processed through our platform.',
                    ),
                    _buildParagraph(
                      'By accessing or using ColonoMind, you acknowledge that you have read, understood, and agree to be bound by the terms of this Policy.',
                    ),

                    _buildSectionTitle("2. Information Collection"),
                    _buildParagraph(
                      "We collect and process specific categories of data necessary for the operation of our diagnostic services and the improvement of our machine learning algorithms.",
                    ),
                    
                    _buildSubSectionTitle("2.1. Personal Health Information (PHI)"),
                    _buildBulletPoint("Medical Imagery", "We process endoscopic images uploaded by authorized users solely for the purpose of calculating the Mayo Endoscopic Score (MES)."),
                    _buildBulletPoint("Clinical Context", "We process textual input provided via the chat interface related to patient history or symptoms."),

                    _buildSubSectionTitle("2.2. Technical Usage Data"),
                    _buildBulletPoint("Log Data", "We automatically collect information regarding your interaction with the service, including Internet Protocol (IP) addresses, browser type, and timestamps."),
                    _buildBulletPoint("Session Identifiers", "We utilize session cookies to maintain application state and security during your analysis."),

                    _buildSectionTitle("3. Data Processing & Architecture"),
                    _buildParagraph("ColonoMind adheres to a Privacy by Design framework to minimize data exposure."),
                    _buildOrderedPoint("1", "AI Analysis Engine", "Uploaded images are processed in a transient state within our secure cloud infrastructure (AWS). Data is processed in volatile memory and is not permanently persisted in our databases unless explicit consent is granted for model calibration."),
                    _buildOrderedPoint("2", "Generative Reporting (LLM)", 'For the generation of clinical narratives ("ColonoTalk"), we utilize enterprise-grade endpoints from trusted third-party Large Language Model providers. Only anonymized feature vectors and numerical scores are transmitted; raw patient imagery is never shared with LLM providers.'),

                    _buildSectionTitle("4. Third-Party Disclosures"),
                    _buildParagraph("We do not sell, trade, or otherwise transfer your data to outside parties. Data is shared only with trusted infrastructure providers necessary for service delivery:"),
                    _buildBulletPoint("Amazon Web Services (AWS)", "Cloud hosting, GPU inference, and encrypted storage."),
                    _buildBulletPoint("LLM API Providers", "Text generation services (strictly under zero-retention enterprise agreements)."),

                    _buildSectionTitle("5. Data Retention"),
                    _buildParagraph("To ensure the continuous efficacy of the ColonoMind AI Engine, we may retain strictly anonymized data sets (stripped of all Direct Identifiers) for the purposes of:"),
                    _buildSimpleBullet("Retraining and fine-tuning hybrid Deep Learning models."),
                    _buildSimpleBullet("Calibrating safety thresholds and reducing false-negative rates."),
                    _buildSimpleBullet("Academic research and peer-reviewed validation."),

                    _buildSectionTitle("6. Security Protocols"),
                    _buildParagraph("We implement robust technical and organizational measures to protect data, including:"),
                    _buildBulletPoint("Encryption", "All data in transit is encrypted via TLS 1.2+ (Transport Layer Security)."),
                    _buildBulletPoint("Access Control", "Administrative access to backend systems is restricted to authorized engineering personnel via multi-factor authentication (MFA)."),

                    _buildSectionTitle("7. Legal Disclaimer"),
                    // Custom Warning Box Container
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFDFE),
                        border: Border(
                          left: BorderSide(color: _warningColor, width: 4),
                          top: BorderSide(color: Colors.grey.shade200),
                          right: BorderSide(color: Colors.grey.shade200),
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NOTICE: CLINICAL DECISION SUPPORT SYSTEM ONLY",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _warningColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ColonoMind is designed as an assistive tool for qualified healthcare professionals. It does not provide a definitive medical diagnosis. The generated analysis serves as a "Second Opinion" to support, not replace, the clinical judgment of a licensed physician. The user assumes full responsibility for all clinical decisions made based on the output of this system.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),

                    _buildSectionTitle("8. Contact Information"),
                    _buildParagraph(
                      "For inquiries regarding this Privacy Policy or to exercise your data rights, please contact the ColonoMind Compliance Team through the official application support portal.",
                    ),

                    const SizedBox(height: 40),
                    const Divider(color: Color(0xFFF1F1F1)),
                    const SizedBox(height: 20),
                    
                    // --- FOOTER ---
                    Center(
                      child: Text(
                        "© 2026 ColonoMind AI. All Rights Reserved.\nThis document is legally privileged and confidential.",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS (Supaya kode bersih) ---

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, bottom: 12.0),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.merriweather(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSubSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.merriweather(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF444444),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.6,
          color: const Color(0xFF333333),
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBulletPoint(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 6, color: Colors.black54),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.6,
                  color: const Color(0xFF333333),
                ),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBullet(String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 6, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.6,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedPoint(String number, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. ",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.6,
                  color: const Color(0xFF333333),
                ),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}