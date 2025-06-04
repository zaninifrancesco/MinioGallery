import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_user.dart';
import '../models/admin_image.dart';
import '../models/system_stats.dart';
import 'token_service.dart';

class AdminService {
  static const String baseUrl = 'http://localhost:8080/api/admin';
  final TokenService _tokenService = TokenService();

  // Get authorization headers with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all users with pagination
  Future<Map<String, dynamic>> getAllUsers({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users?page=$page&size=$size'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> usersJson = data['content'] ?? [];
        final List<AdminUser> users =
            usersJson.map((json) => AdminUser.fromJson(json)).toList();

        return {
          'users': users,
          'totalElements': data['totalElements'] ?? 0,
          'totalPages': data['totalPages'] ?? 0,
          'currentPage': data['number'] ?? 0,
          'hasNext': !(data['last'] ?? true),
          'hasPrevious': !(data['first'] ?? true),
        };
      } else {
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get all images with pagination
  Future<Map<String, dynamic>> getAllImages({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/images?page=$page&size=$size'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> imagesJson = data['content'] ?? [];
        final List<AdminImage> images =
            imagesJson.map((json) => AdminImage.fromJson(json)).toList();

        return {
          'images': images,
          'totalElements': data['totalElements'] ?? 0,
          'totalPages': data['totalPages'] ?? 0,
          'currentPage': data['number'] ?? 0,
          'hasNext': !(data['last'] ?? true),
          'hasPrevious': !(data['first'] ?? true),
        };
      } else {
        throw Exception('Failed to load images: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete user
  Future<bool> deleteUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete image
  Future<bool> deleteImage(String imageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/images/$imageId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Change user role
  Future<bool> changeUserRole(int userId, String newRole) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/role'),
        headers: headers,
        body: jsonEncode({'role': newRole}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Toggle user status (enable/disable)
  Future<bool> toggleUserStatus(int userId, bool enabled) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/status'),
        headers: headers,
        body: jsonEncode({'enabled': enabled}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get system statistics
  Future<SystemStats> getSystemStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return SystemStats.fromJson(data);
      } else {
        throw Exception('Failed to load system stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
