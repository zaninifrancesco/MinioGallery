class ImageUploadRequest {
  final String title;
  final String description;
  final List<String> tags;

  ImageUploadRequest({
    required this.title,
    required this.description,
    required this.tags,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'tags': tags};
  }
}
