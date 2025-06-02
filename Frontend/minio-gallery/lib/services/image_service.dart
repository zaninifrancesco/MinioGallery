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

      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final jsonData = json.decode(responseBody);
        return ImageMetadata.fromJson(jsonData);
      } else {
        print('Upload failed: ${response.statusCode}');
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
      final response = await http.get(uri, headers: _getHeaders(token));

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
        '$baseUrl/images/search?tags=$tagsParam&page=$page&size=$size',
      );
      final response = await http.get(uri, headers: _getHeaders(token));

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
}
