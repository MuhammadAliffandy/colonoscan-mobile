import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../api.dart';

class SmartAuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static late AppLinks _appLinks;
  static StreamSubscription<Uri>? _linkSubscription;

  static const String clientId = 'cc344727-6f90-496c-94fd-c7829aa9a51d';
  static const String redirectUri = 'https://colonomind-335955344592.asia-southeast1.run.app/smart/callback';
  static const List<String> scopes = ['launch', 'openid', 'fhirUser', 'patient/*.read'];
  static const String backendBaseUrl = ApiService.baseUrl;

  /// Initializes deep link listener to catch the SMART on FHIR callback.
  static void initDeepLinkListener(Function(Map<String, dynamic>?) onLoginResult) {
    _appLinks = AppLinks();
    
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      if (uri.path == '/smart/callback' && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code']!;
        // Exchange the code with our backend
        try {
          final result = await _exchangeCodeWithBackend(code);
          onLoginResult(result);
        } catch (e) {
          onLoginResult({'error': e.toString()});
        }
      }
    }, onError: (err) {
      print("Deep Link Error: $err");
      onLoginResult({'error': err.toString()});
    });
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }

  static const String authUrl = "https://fhir.onerecord.tw/oauth/authorize";

  /// Starts the SMART on FHIR OAuth2 flow by opening the browser.
  static Future<void> login() async {
    try {
      // We initiate the authorization by opening the browser
      // Using url_launcher to open the FHIR server authorization directly.
      
      final String scopes = Uri.encodeComponent(SmartAuthService.scopes.join(" "));
      
      final String authorizeUrl = "$authUrl?response_type=code&client_id=$clientId&redirect_uri=${Uri.encodeComponent(redirectUri)}&scope=$scopes&state=mobile_flow";

      final Uri launchUri = Uri.parse(authorizeUrl);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open browser to authenticate');
      }
    } catch (e) {
      print('SMART Auth Error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _exchangeCodeWithBackend(String code) async {
    // Send the code to the backend.
    final uri = Uri.parse('$backendBaseUrl/smart/callback?code=$code&mobile_app=true');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final accessToken = jsonResponse['access_token'];
      final patient = jsonResponse['patient'];

      if (accessToken != null) {
        await _secureStorage.write(key: 'smart_access_token', value: accessToken);
      }
      if (patient != null) {
        await _secureStorage.write(key: 'smart_patient', value: patient);
      }

      return jsonResponse;
    } else {
      throw Exception('Backend code exchange failed: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String?> getSmartAccessToken() async {
    return await _secureStorage.read(key: 'smart_access_token');
  }

  static Future<void> logout() async {
    await _secureStorage.delete(key: 'smart_access_token');
    await _secureStorage.delete(key: 'smart_patient');
  }
}
