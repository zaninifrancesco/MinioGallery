class PublicStatistics {
  final int totalPhotos;
  final int totalLikes;
  final int totalParticipants;

  PublicStatistics({
    required this.totalPhotos,
    required this.totalLikes,
    required this.totalParticipants,
  });

  factory PublicStatistics.fromJson(Map<String, dynamic> json) {
    return PublicStatistics(
      totalPhotos: json['totalPhotos'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      totalParticipants: json['totalParticipants'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPhotos': totalPhotos,
      'totalLikes': totalLikes,
      'totalParticipants': totalParticipants,
    };
  }

  @override
  String toString() {
    return 'PublicStatistics(totalPhotos: $totalPhotos, totalLikes: $totalLikes, totalParticipants: $totalParticipants)';
  }
}
