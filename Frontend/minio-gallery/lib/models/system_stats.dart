class SystemStats {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int totalAdmins;
  final int totalImages;
  final String totalStorageUsed; // Formatted string like "125.5 MB"
  final int totalLikes;

  SystemStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.totalAdmins,
    required this.totalImages,
    required this.totalStorageUsed,
    required this.totalLikes,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>? ?? {};
    final images = json['images'] as Map<String, dynamic>? ?? {};
    final likes = json['likes'] as Map<String, dynamic>? ?? {};

    // Calcola storage formattato
    final totalSizeMB = images['totalSizeMB'] ?? 0.0;
    String formattedStorage;
    if (totalSizeMB >= 1024) {
      formattedStorage = '${(totalSizeMB / 1024).toStringAsFixed(1)} GB';
    } else if (totalSizeMB >= 1) {
      formattedStorage = '${totalSizeMB.toStringAsFixed(1)} MB';
    } else {
      final totalSizeKB = (images['totalSizeBytes'] ?? 0) / 1024;
      formattedStorage = '${totalSizeKB.toStringAsFixed(1)} KB';
    }

    return SystemStats(
      totalUsers: users['total'] ?? 0,
      activeUsers: users['enabled'] ?? 0,
      inactiveUsers: users['disabled'] ?? 0,
      totalAdmins: users['admins'] ?? 0,
      totalImages: images['total'] ?? 0,
      totalStorageUsed: formattedStorage,
      totalLikes: likes['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'inactiveUsers': inactiveUsers,
      'totalAdmins': totalAdmins,
      'totalImages': totalImages,
      'totalStorageUsed': totalStorageUsed,
      'totalLikes': totalLikes,
    };
  }

  @override
  String toString() {
    return 'SystemStats(totalUsers: $totalUsers, activeUsers: $activeUsers, totalImages: $totalImages, storage: $totalStorageUsed)';
  }
}
