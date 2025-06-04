import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class LikeService {
  static const String baseUrl = 'http://localhost:8080/api';
  final TokenService _tokenService = TokenService();

  Future<String?> _getAuthToken() async {
    return await _tokenService.getToken();
  }

  Map<String, String> _getHeaders([String? token]) {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Toggle like/unlike su un'immagine
  Future<bool> toggleLike(String imageId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse('$baseUrl/images/$imageId/likes');
      final response = await http.post(uri, headers: _getHeaders(token));

      print('Toggle like response status: ${response.statusCode}');
      print('Toggle like response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Ottieni il conteggio di like di un'immagine
  Future<int> getLikeCount(String imageId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse('$baseUrl/images/$imageId/likes/count');
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        return int.parse(response.body);
      } else {
        print('Failed to get like count: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Error getting like count: $e');
      return 0;
    }
  }

  // Verifica se l'utente corrente ha messo like a un'immagine
  Future<bool> isLikedByCurrentUser(String imageId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse('$baseUrl/images/$imageId/likes/status');
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['liked'] as bool? ?? false;
      } else {
        print('Failed to get like status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error getting like status: $e');
      return false;
    }
  }
}
