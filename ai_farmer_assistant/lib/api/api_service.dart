import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // For Android Emulator: use 10.0.2.2:8000
  // For Physical Device (USB): use "http://localhost:8000" with: adb reverse tcp:8000 tcp:8000
  // For Physical Device (WiFi): use your PC's LAN IP, e.g. "http://192.168.1.5:8000"
static const String baseUrl = kIsWeb
    ? "https://ai-farmer-backend.vercel.app"
    : "https://ai-farmer-backend.vercel.app";
  
  static String? _token;

  // Initialize and load saved JWT token from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("jwt_token");
  }

  static String? get token => _token;

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_token", token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_token");
  }

  static Map<String, String> _headers(bool useAuth) {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (useAuth && _token != null) {
      headers["Authorization"] = "Bearer $_token";
    }
    return headers;
  }

  // Timeout duration for all requests (60s for uploads)
  static const Duration _timeout = Duration(seconds: 60);

  // Turn low-level network errors into a message the user can act on.
  static String friendlyError(Object e) {
    final text = e.toString();
    if (text.contains("SocketException") ||
        text.contains("Connection refused") ||
        text.contains("Failed host lookup")) {
      return "Cannot reach the server.\n\n"
          "Fix: make sure the backend is running on port 8000, then run:\n"
          "adb reverse tcp:8000 tcp:8000\n\n"
          "(This resets every time you unplug the USB cable.)";
    }
    if (text.contains("TimeoutException")) {
      return "The server took too long to respond. Please try again.";
    }
    return text;
  }

  /// Safely decode a JSON response body. If the body is not valid JSON
  /// (e.g. an HTML error page from Vercel), return a map with "detail"
  /// describing the problem instead of throwing a FormatException.
  static Map<String, dynamic> safeJsonDecode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // The server returned non-JSON (HTML error page, plain text, etc.)
      return {
        "detail": "Server error (${response.statusCode}). Please try again later.",
      };
    }
  }

  // POST Request
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool useAuth = true}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final response = await http.post(
      url,
      headers: _headers(useAuth),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return response;
  }

  // GET Request
  static Future<http.Response> get(String endpoint, {bool useAuth = true}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final response = await http.get(
      url,
      headers: _headers(useAuth),
    ).timeout(_timeout);
    return response;
  }

  // Multipart POST — compresses image before uploading so it always fits
  // within Vercel's 4.5 MB body limit, no matter how large the original photo is.
  static Future<http.Response> uploadFile(String endpoint, XFile file, {bool useAuth = true}) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final request = http.MultipartRequest("POST", url);

    // Add auth headers
    if (useAuth && _token != null) {
      request.headers["Authorization"] = "Bearer $_token";
    }
    // Tell the server we want JSON back, not HTML
    request.headers["Accept"] = "application/json";

    late List<int> bytes;

    if (kIsWeb) {
      // Web: no flutter_image_compress support — send raw bytes
      bytes = await file.readAsBytes();
    } else {
      // Mobile/Desktop: compress to JPEG, max 1280px, quality 70
      // This reliably keeps the upload under Vercel's 4.5 MB body limit,
      // even for 50MP+ phone cameras.
      final compressed = await FlutterImageCompress.compressWithList(
        await file.readAsBytes(),
        minWidth: 1280,
        minHeight: 1280,
        quality: 70,
        format: CompressFormat.jpeg,
      );
      bytes = compressed;
    }

    final multipartFile = http.MultipartFile.fromBytes(
      "file",
      bytes,
      filename: kIsWeb ? file.name : "${file.name.split('.').first}.jpg",
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send().timeout(_timeout);
    return await http.Response.fromStream(streamedResponse);
  }
}