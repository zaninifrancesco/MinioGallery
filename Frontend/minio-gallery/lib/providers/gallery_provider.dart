import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_metadata.dart';
import '../models/image_upload_request.dart';
import '../models/gallery_response.dart';
import '../services/image_service.dart';

class GalleryProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();

  List<ImageMetadata> _images = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMoreImages = true;
  int _totalImages = 0;

  // Getters
  List<ImageMetadata> get images => _images;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMoreImages => _hasMoreImages;
  int get totalImages => _totalImages;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Carica galleria (prima pagina)
  Future<void> loadGallery({bool refresh = false}) async {
    if (refresh) {
      _images.clear();
      _currentPage = 0;
      _hasMoreImages = true;
    }

    if (_isLoading || !_hasMoreImages) return;

    _setLoading(true);
    _setError(null);

    try {
      final response = await _imageService.getGallery(
        page: _currentPage,
        size: 12,
      );

      if (response != null) {
        if (_currentPage == 0) {
          _images = response.content;
        } else {
          _images.addAll(response.content);
        }

        _totalImages = response.totalElements;
        _hasMoreImages = !response.last;
        _currentPage++;
      } else {
        _setError('Failed to load gallery');
      }
    } catch (e) {
      _setError('Error loading gallery: $e');
    }

    _setLoading(false);
  }

  // Carica più immagini (paginazione)
  Future<void> loadMoreImages() async {
    if (!_hasMoreImages || _isLoading) return;
    await loadGallery();
  }

  // Upload immagine
  Future<bool> uploadImage({
    required XFile imageFile,
    required String title,
    required String description,
    required List<String> tags,
  }) async {
    _setUploading(true);
    _setError(null);

    try {
      final metadata = ImageUploadRequest(
        title: title,
        description: description,
        tags: tags,
      );

      final uploadedImage = await _imageService.uploadImage(
        imageFile: imageFile,
        metadata: metadata,
      );

      if (uploadedImage != null) {
        // Aggiungi l'immagine all'inizio della lista
        _images.insert(0, uploadedImage);
        _totalImages++;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to upload image');
        return false;
      }
    } catch (e) {
      _setError('Error uploading image: $e');
      return false;
    } finally {
      _setUploading(false);
    }
  }

  // Elimina immagine
  Future<bool> deleteImage(String imageId) async {
    try {
      final success = await _imageService.deleteImage(imageId);
      if (success) {
        _images.removeWhere((image) => image.id == imageId);
        _totalImages--;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete image');
        return false;
      }
    } catch (e) {
      _setError('Error deleting image: $e');
      return false;
    }
  }

  // Cerca per tag
  Future<void> searchByTags(List<String> tags) async {
    _setLoading(true);
    _setError(null);
    _images.clear();
    _currentPage = 0;

    try {
      final response = await _imageService.searchByTags(tags: tags);
      if (response != null) {
        _images = response.content;
        _totalImages = response.totalElements;
        _hasMoreImages = !response.last;
        _currentPage = 1;
      } else {
        _setError('Failed to search images');
      }
    } catch (e) {
      _setError('Error searching images: $e');
    }

    _setLoading(false);
  }

  // Pulisci errori
  void clearError() {
    _setError(null);
  }

  // Reset provider
  void reset() {
    _images.clear();
    _currentPage = 0;
    _hasMoreImages = true;
    _totalImages = 0;
    _isLoading = false;
    _isUploading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
