
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
static const String _buildTimeUrl =
String.fromEnvironment('API_URL', defaultValue: '');

static const String _fallbackUrl =
'https://ai-farmer-backend-jhsy.vercel.app';

static String? _overrideUrl;
static bool _overrideLoaded = false;
static String? _token;

static const Duration _timeout = Duration(seconds: 120);

// ---------------------------------------------------------
// BASE URL
// ---------------------------------------------------------

static String get baseUrl {
final url = (_overrideUrl != null && _overrideUrl!.isNotEmpty)
? _overrideUrl!
    : (_buildTimeUrl.isNotEmpty ? _buildTimeUrl : _fallbackUrl);

return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}

// ---------------------------------------------------------
// SET API URL
// ---------------------------------------------------------

static Future<void> setBaseUrl(String url) async {
final cleaned = url.trim();
_overrideUrl = cleaned.isEmpty ? null : cleaned;
_overrideLoaded = true;

final prefs = await SharedPreferences.getInstance();

if (cleaned.isEmpty) {
await prefs.remove('api_base_url');
} else {
await prefs.setString('api_base_url', cleaned);
}
}

// ---------------------------------------------------------
// INITIALIZE
// ---------------------------------------------------------

static Future<void> init() async {
final prefs = await SharedPreferences.getInstance();

_token = prefs.getString('jwt_token');

if (!_overrideLoaded) {
_overrideUrl = prefs.getString('api_base_url');
_overrideLoaded = true;
}
}

// ---------------------------------------------------------
// TOKEN
// ---------------------------------------------------------

static String? get token => _token;

static Future<void> saveToken(String token) async {
_token = token;

final prefs = await SharedPreferences.getInstance();
await prefs.setString('jwt_token', token);
}

static Future<void> clearToken() async {
_token = null;

final prefs = await SharedPreferences.getInstance();
await prefs.remove('jwt_token');
}

// ---------------------------------------------------------
// HEADERS
// ---------------------------------------------------------

static Map<String, String> _headers(bool useAuth) {
final headers = <String, String>{
'Content-Type': 'application/json',
'Accept': 'application/json',
};

if (useAuth && _token != null) {
headers['Authorization'] = 'Bearer $_token';
}

return headers;
}

// ---------------------------------------------------------
// FRIENDLY ERROR
// ---------------------------------------------------------

static String friendlyError(Object e) {
final text = e.toString();

if (text.contains('TimeoutException') ||
text.contains('TimeoutException:') ||
text.contains('Connection timed out')) {
return 'Plant analysis is taking longer than expected. '
'Please try again. If this keeps happening, check the backend logs.';
}

if (text.contains('SocketException') ||
text.contains('Connection refused') ||
text.contains('Failed host lookup') ||
text.contains('Failed to fetch')) {
final isLocal = baseUrl.contains('localhost') ||
baseUrl.contains('127.0.0.1') ||
baseUrl.contains('10.0.2.2');

if (isLocal) {
return 'Cannot reach your local backend.\n\n'
'1. Make sure it is running on port 8000.\n'
'2. For a USB device, run:\n'
'   adb reverse tcp:8000 tcp:8000';
}

return 'Cannot reach $baseUrl\n\n'
'Check your internet connection and try again.';
}

return text;
}

// ---------------------------------------------------------
// SAFE JSON DECODE
// ---------------------------------------------------------

static Map<String, dynamic> safeJsonDecode(http.Response response) {
try {
final decoded = jsonDecode(response.body);

if (decoded is Map<String, dynamic>) {
return decoded;
}

return {'detail': 'Unexpected response from server.'};
} catch (_) {
return {
'detail': 'Server error (${response.statusCode}). Please try again.',
};
}
}

// ---------------------------------------------------------
// POST REQUEST
// ---------------------------------------------------------

static Future<http.Response> post(
String endpoint,
Map<String, dynamic> body, {
bool useAuth = true,
}) async {
final url = Uri.parse('$baseUrl$endpoint');

return await http
    .post(
url,
headers: _headers(useAuth),
body: jsonEncode(body),
)
    .timeout(_timeout);
}

// ---------------------------------------------------------
// GET REQUEST
// ---------------------------------------------------------

static Future<http.Response> get(
String endpoint, {
bool useAuth = true,
}) async {
final url = Uri.parse('$baseUrl$endpoint');

return await http
    .get(
url,
headers: _headers(useAuth),
)
    .timeout(_timeout);
}

// ---------------------------------------------------------
// IMAGE CONTENT TYPE
// ---------------------------------------------------------

static MediaType _getImageContentType(String filename) {
final lower = filename.toLowerCase();

if (lower.endsWith('.png')) {
return MediaType('image', 'png');
}

if (lower.endsWith('.webp')) {
return MediaType('image', 'webp');
}

if (lower.endsWith('.jpeg') || lower.endsWith('.jpg')) {
return MediaType('image', 'jpeg');
}

return MediaType('image', 'jpeg');
}

// ---------------------------------------------------------
// IMAGE UPLOAD
// ---------------------------------------------------------

static Future<http.Response> uploadFile(
String endpoint,
XFile file, {
bool useAuth = true,
}) async {
final url = Uri.parse('$baseUrl$endpoint');
final request = http.MultipartRequest('POST', url);

if (useAuth && _token != null) {
request.headers['Authorization'] = 'Bearer $_token';
}

request.headers['Accept'] = 'application/json';

late List<int> bytes;
late String filename;
late MediaType contentType;

// WEB: preserve the original supported image format.
if (kIsWeb) {
bytes = await file.readAsBytes();

final originalName = file.name.toLowerCase();

if (originalName.endsWith('.png')) {
filename = 'plant_photo.png';
contentType = MediaType('image', 'png');
} else if (originalName.endsWith('.webp')) {
filename = 'plant_photo.webp';
contentType = MediaType('image', 'webp');
} else if (originalName.endsWith('.jpeg')) {
filename = 'plant_photo.jpeg';
contentType = MediaType('image', 'jpeg');
} else {
filename = 'plant_photo.jpg';
contentType = MediaType('image', 'jpeg');
}
} else {
// MOBILE/DESKTOP: compress and convert to JPEG.
final originalBytes = await file.readAsBytes();

try {
final compressed = await FlutterImageCompress.compressWithList(
originalBytes,
minWidth: 1280,
minHeight: 1280,
quality: 70,
format: CompressFormat.jpeg,
);

if (compressed.isEmpty) {
throw Exception('Image compression returned empty data.');
}

bytes = compressed;
filename = 'plant_photo.jpg';
contentType = MediaType('image', 'jpeg');
} catch (_) {
// If compression fails, preserve the original bytes and type.
bytes = originalBytes;

final originalName = file.name.toLowerCase();
final isSupported = originalName.endsWith('.jpg') ||
originalName.endsWith('.jpeg') ||
originalName.endsWith('.png') ||
originalName.endsWith('.webp');

if (!isSupported) {
throw Exception(
'Unsupported image format. Please choose JPG, PNG, or WEBP.',
);
}

filename = originalName.endsWith('.png')
? 'plant_photo.png'
    : originalName.endsWith('.webp')
? 'plant_photo.webp'
    : 'plant_photo.jpg';

contentType = _getImageContentType(originalName);
}
}

if (bytes.isEmpty) {
throw Exception('Selected image is empty. Please choose another image.');
}

request.files.add(
http.MultipartFile.fromBytes(
'file',
bytes,
filename: filename,
contentType: contentType,
),
);

// Timeout covers sending the upload and waiting for the response.
final streamedResponse = await request.send().timeout(_timeout);

// Reading the response body also gets a timeout.
return await http.Response.fromStream(streamedResponse).timeout(_timeout);
}
}

