import 'dart:convert';
import 'dart:io'; // Untuk File
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; // Untuk MediaType

class ApiService {
  // Ganti sesuai IP
  static const String baseUrl = "http://127.0.0.1:8000"; 

  // --- HELPER: AMBIL TOKEN ---
  static Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // --- AUTH (SAMA SEPERTI SEBELUMNYA) ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"full_name": name, "email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getHistory() async {
    String? token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/history'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal load history');
    }
  }

  // --- NEW: PREDICT IMAGE (MOBILE) ---
  static Future<Map<String, dynamic>> predictImage(File imageFile) async {
    String? token = await _getToken();
    if (token == null) throw Exception("Token not found. Please login.");

    var uri = Uri.parse("$baseUrl/pred-mobile");
    var request = http.MultipartRequest('POST', uri);

    // Header Auth
    request.headers['Authorization'] = 'Bearer $token';

    // Attach File
    var pic = await http.MultipartFile.fromPath(
      "file", 
      imageFile.path,
      contentType: MediaType('image', 'jpeg')
    );
    request.files.add(pic);

    // Send
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      // Return bagian 'data' saja biar UI langsung pakai
      var json = jsonDecode(response.body);
      return json['data']; 
    } else {
      // Coba parsing error message dari server
      try {
        var errorJson = jsonDecode(response.body);
        throw Exception(errorJson['error'] ?? 'Upload Failed');
      } catch (_) {
        throw Exception('Server Error: ${response.statusCode}');
      }
    }
  }

  // --- NEW: CHATBOT ---
  static Future<String> chatWithBot(String message, Map<String, dynamic> contextData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": message,
          "context_data": contextData
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['reply'];
      } else {
        throw Exception("Gagal mendapatkan balasan chat.");
      }
    } catch (e) {
      throw Exception("Chat Error: $e");
    }
  }
}