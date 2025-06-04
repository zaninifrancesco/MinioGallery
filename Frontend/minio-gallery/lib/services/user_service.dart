import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/token_service.dart';

class UserService {
  static const String baseUrl = 'http://localhost:8080/api/auth';
  final TokenService _tokenService = TokenService();

  Future<String?> _getAuthToken() async {
    return await _tokenService.getToken();
  }

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get all users
  Future<List<User>?> getAllUsers() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((userJson) => User.fromJson(userJson)).toList();
      } else {
        print('Failed to fetch users: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching users: $e');
      return null;
    }
  }
}
