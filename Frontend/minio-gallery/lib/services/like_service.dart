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
      print('LikeService: Toggling like for imageId: $imageId');
      print('LikeService: Token available: ${token != null}');

      if (token == null) {
        print('LikeService: No auth token available');
        return false;
      }

      final uri = Uri.parse('$baseUrl/likes/toggle/$imageId');
      final response = await http.post(uri, headers: _getHeaders(token));

      print('Toggle like response status: ${response.statusCode}');
      print('Toggle like response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Ottieni lo stato del like (conteggio e se l'utente corrente ha messo like)
  Future<Map<String, dynamic>> getLikeStatus(String imageId) async {
    try {
      final token = await _getAuthToken();
      print('LikeService: Getting like status for imageId: $imageId');
      print('LikeService: Token available: ${token != null}');

      final uri = Uri.parse('$baseUrl/likes/status/$imageId');
      final response = await http.get(uri, headers: _getHeaders(token));

      print('LikeService: Response status: ${response.statusCode}');
      print('LikeService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = {
          'liked': data['liked'] as bool? ?? false,
          'likeCount': data['likeCount'] as int? ?? 0,
        };
        print('LikeService: Parsed result: $result');
        return result;
      } else {
        print('Failed to get like status: ${response.statusCode}');
        return {'liked': false, 'likeCount': 0};
      }
    } catch (e) {
      print('Error getting like status: $e');
      return {'liked': false, 'likeCount': 0};
    }
  }

  // Ottieni il conteggio di like di un'immagine
  Future<int> getLikeCount(String imageId) async {
    final status = await getLikeStatus(imageId);
    return status['likeCount'] as int;
  }

  // Verifica se l'utente corrente ha messo like a un'immagine
  Future<bool> isLikedByCurrentUser(String imageId) async {
    final status = await getLikeStatus(imageId);
    return status['liked'] as bool;
  }
}
