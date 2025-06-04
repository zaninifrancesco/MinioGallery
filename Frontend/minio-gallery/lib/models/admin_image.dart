class AdminImage {
  final String id;
  final String fileName;
  final String title;
  final String? description;
  final String contentType;
  final int fileSize;
  final DateTime uploadedAt;
  final String username; // Owner username
  final int likes;

  AdminImage({
    required this.id,
    required this.fileName,
    required this.title,
    this.description,
    required this.contentType,
    required this.fileSize,
    required this.uploadedAt,
    required this.username,
    required this.likes,
  });

  factory AdminImage.fromJson(Map<String, dynamic> json) {
    return AdminImage(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      contentType: json['contentType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      uploadedAt: DateTime.parse(
        json['uploadedAt'] ?? DateTime.now().toIso8601String(),
      ),
      username: json['username'] ?? '',
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'title': title,
      'description': description,
      'contentType': contentType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
      'username': username,
      'likes': likes,
    };
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    if (fileSize < 1024 * 1024 * 1024)
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminImage &&
        other.id == id &&
        other.fileName == fileName &&
        other.title == title &&
        other.username == username;
  }

  @override
  int get hashCode =>
      id.hashCode ^ fileName.hashCode ^ title.hashCode ^ username.hashCode;

  @override
  String toString() {
    return 'AdminImage(id: $id, fileName: $fileName, title: $title, username: $username, fileSize: $fileSizeFormatted)';
  }
}
