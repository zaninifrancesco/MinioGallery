import 'image_metadata.dart';

class GalleryResponse {
  final List<ImageMetadata> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  GalleryResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory GalleryResponse.fromJson(Map<String, dynamic> json) {
    return GalleryResponse(
      content:
          (json['content'] as List)
              .map((item) => ImageMetadata.fromJson(item))
              .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
    );
  }
}
