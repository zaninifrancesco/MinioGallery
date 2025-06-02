import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html' show File;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // Aggiunto per MediaType
import '../models/image_metadata.dart';
import '../models/image_upload_request.dart';
import '../models/gallery_response.dart';
import 'token_service.dart';

class ImageService {
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

  // Upload immagine
  Future<ImageMetadata?> uploadImage({
    required XFile imageFile,
    required ImageUploadRequest metadata,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse('$baseUrl/images');
      final request = http.MultipartRequest('POST', uri);

      // Aggiungi header Authorization
      request.headers['Authorization'] = 'Bearer $token';

      // Aggiungi file in modo condizionale per web/mobile
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: imageFile.name,
            contentType: MediaType.parse(
              imageFile.mimeType ?? 'application/octet-stream',
            ),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      // Aggiungi metadati come form-data (non JSON)
      request.fields['title'] = metadata.title;
      request.fields['description'] = metadata.description;
      request.fields['tags'] = metadata.tags.join(',');
      final response = await request.send();
      print('Upload response status code: ${response.statusCode}');

      final responseBody = await response.stream.bytesToString();
      print('Upload response body: $responseBody');

      if (response.statusCode == 201) {
        final jsonData = json.decode(responseBody);
        return ImageMetadata.fromJson(jsonData);
      } else {
        print('Upload failed: ${response.statusCode}');
        print('Response body: $responseBody');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Ottieni galleria con paginazione
  Future<GalleryResponse?> getGallery({int page = 0, int size = 12}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse('$baseUrl/images?page=$page&size=$size');
      print('Fetching gallery from: $uri');
      final response = await http.get(uri, headers: _getHeaders(token));

      print('Gallery response status: ${response.statusCode}');
      print('Gallery response body: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GalleryResponse.fromJson(jsonData);
      } else {
        print('Failed to load gallery: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading gallery: $e');
      return null;
    }
  }

  // Ottieni le immagini dell'utente corrente con paginazione
  Future<GalleryResponse?> getMyImages({int page = 0, int size = 12}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse('$baseUrl/images/my?page=$page&size=$size');
      print('Fetching my images from: $uri');
      final response = await http.get(uri, headers: _getHeaders(token));

      print('My images response status: ${response.statusCode}');
      print('My images response body: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GalleryResponse.fromJson(jsonData);
      } else {
        print('Failed to load my images: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading my images: $e');
      return null;
    }
  }

  // Ottieni singola immagine
  Future<ImageMetadata?> getImage(String imageId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse('$baseUrl/images/$imageId');
      final response = await http.get(uri, headers: _getHeaders(token));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ImageMetadata.fromJson(jsonData);
      } else {
        print('Failed to load image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  // Elimina immagine
  Future<bool> deleteImage(String imageId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse('$baseUrl/images/$imageId');
      final response = await http.delete(uri, headers: _getHeaders(token));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Cerca immagini per tag
  Future<GalleryResponse?> searchByTags({
    required List<String> tags,
    int page = 0,
    int size = 12,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final tagsParam = tags.join(',');
      final uri = Uri.parse(
        '$baseUrl/images/search/tags?tags=$tagsParam&page=$page&size=$size',
      );
      print('Searching by tags at: $uri');
      final response = await http.get(uri, headers: _getHeaders(token));

      print('Search response status: ${response.statusCode}');
      print('Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GalleryResponse.fromJson(jsonData);
      } else {
        print('Failed to search images: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error searching images: $e');
      return null;
    }
  }

  // Cerca immagini per testo (titolo o descrizione)
  Future<GalleryResponse?> searchByText({
    required String query,
    int page = 0,
    int size = 12,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse(
        '$baseUrl/images/search?query=$query&page=$page&size=$size',
      );
      print('Searching by text at: $uri');
      final response = await http.get(uri, headers: _getHeaders(token));

      print('Search response status: ${response.statusCode}');
      print('Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GalleryResponse.fromJson(jsonData);
      } else {
        print('Failed to search images: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error searching images: $e');
      return null;
    }
  }

  // Cerca le mie immagini per tag
  Future<GalleryResponse?> searchMyImagesByTags({
    required List<String> tags,
    int page = 0,
    int size = 12,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final tagsParam = tags.join(',');
      final uri = Uri.parse(
        '$baseUrl/images/my/search/tags?tags=$tagsParam&page=$page&size=$size',
      );
      print('Searching my images by tags at: $uri');
      final response = await http.get(uri, headers: _getHeaders(token));

      print('My search response status: ${response.statusCode}');
      print('My search response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GalleryResponse.fromJson(jsonData);
      } else {
        print('Failed to search my images: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error searching my images: $e');
      return null;
    }
  }

  // Cerca le mie immagini per testo (titolo o descrizione)
  Future<GalleryResponse?> searchMyImagesByText({
    required String query,
    int page = 0,
    int size = 12,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('No auth token');

      final uri = Uri.parse(
        '$baseUrl/images/my/search?query=$query&page=$page&size=$size',
      );
      print('Searching my images by text at: $uri');
      final response = await http.get(uri, headers: _getHeaders(token));

      print('My search response status: ${response.statusCode}');
      print('My search response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GalleryResponse.fromJson(jsonData);
      } else {
        print('Failed to search my images: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error searching my images: $e');
      return null;
    }
  }
}
