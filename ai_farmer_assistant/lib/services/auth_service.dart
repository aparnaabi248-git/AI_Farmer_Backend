import 'dart:convert';
import '../api/api_service.dart';

class AuthService {
  // Check if user is logged in
  bool get isLoggedIn => ApiService.token != null;

  // ===========================
  // SIGN UP
  // ===========================
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        "/auth/signup",
        {
          "name": name.trim(),
          "email": email.trim(),
          "password": password,
        },
        useAuth: false,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data["access_token"];
        await ApiService.saveToken(token);
        return null; // success
      } else {
        final data = jsonDecode(response.body);
        return data["detail"] ?? "Sign up failed.";
      }
    } catch (e) {
      return e.toString();
    }
  }

  // ===========================
  // LOGIN
  // ===========================
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        "/auth/login",
        {
          "email": email.trim(),
          "password": password,
        },
        useAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["access_token"];
        await ApiService.saveToken(token);
        return null; // success
      } else {
        final data = jsonDecode(response.body);
        return data["detail"] ?? "Invalid email or password.";
      }
    } catch (e) {
      return e.toString();
    }
  }

  // ===========================
  // LOGOUT
  // ===========================
  Future<void> logout() async {
    await ApiService.clearToken();
  }

  // ===========================
  // RESET PASSWORD (MOCK/SIMULATED)
  // ===========================
  Future<String?> resetPassword(String email) async {
    // Return mock success as we've migrated authentication locally
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }
}