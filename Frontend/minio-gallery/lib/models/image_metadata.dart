class ImageMetadata {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime uploadedAt; // Changed from uploadTimestamp
  final List<String> tags;
  final String? presignedUrl; // Optional, for backward compatibility
  final String? fileName; // Added to match backend
  final String? uploaderUsername; // Added to match backend

  ImageMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.uploadedAt, // Changed from uploadTimestamp
    required this.tags,
    this.presignedUrl,
    this.fileName,
    this.uploaderUsername,
  });
  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    print('ImageMetadata.fromJson received: $json');

    // Handle date parsing more robustly
    DateTime parsedDate;
    try {
      String dateStr = json['uploadedAt'] as String;
      print('Parsing date: $dateStr');

      // Try ISO format first
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (e) {
        // If that fails, try the backend format "yyyy-MM-dd HH:mm:ss"
        parsedDate = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      }
    } catch (e) {
      print('Error parsing date: $e');
      parsedDate = DateTime.now(); // Fallback
    }

    return ImageMetadata(
      id: json['id'].toString(), // Convert UUID to String
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String,
      uploadedAt: parsedDate,
      tags: List<String>.from(json['tags'] as List? ?? []),
      presignedUrl: json['presignedUrl'] as String?,
      fileName: json['fileName'] as String?,
      uploaderUsername: json['uploaderUsername'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'uploadedAt':
          uploadedAt.toIso8601String(), // Changed from uploadTimestamp
      'tags': tags,
      'presignedUrl': presignedUrl,
      'fileName': fileName,
      'uploaderUsername': uploaderUsername,
    };
  }
}
