class ImageMetadata {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime uploadTimestamp;
  final List<String> tags;
  final String? presignedUrl; // Changed to nullable String

  ImageMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.uploadTimestamp,
    required this.tags,
    this.presignedUrl, // Changed to optional
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      uploadTimestamp: DateTime.parse(json['uploadTimestamp'] as String),
      tags: List<String>.from(json['tags'] as List),
      presignedUrl: json['presignedUrl'] as String?, // Changed to nullable cast
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'uploadTimestamp': uploadTimestamp.toIso8601String(),
      'tags': tags,
      'presignedUrl': presignedUrl,
    };
  }
}
