import 'package:flutter/foundation.dart';
import '../models/public_statistics.dart';
import '../services/statistics_service.dart';

class StatisticsProvider extends ChangeNotifier {
  final StatisticsService _statisticsService = StatisticsService();

  PublicStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;

  // Cache duration - 5 minutes
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Getters
  PublicStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasStatistics => _statistics != null;

  // Get formatted statistics strings
  String get totalPhotosText => _statistics?.totalPhotos.toString() ?? '0';
  String get totalLikesText => _statistics?.totalLikes.toString() ?? '0';
  String get totalParticipantsText =>
      _statistics?.totalParticipants.toString() ?? '0';

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Check if cached data is still valid
  bool _isCacheValid() {
    if (_lastFetchTime == null || _statistics == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheTimeout;
  }

  // Fetch public statistics
  Future<void> fetchStatistics({bool forceRefresh = false}) async {
    // Use cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid()) {
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      final statistics = await _statisticsService.getPublicStatistics();
      _statistics = statistics;
      _lastFetchTime = DateTime.now();
      _setError(null);
    } catch (e) {
      _setError('Failed to load statistics: ${e.toString()}');
      debugPrint('Error fetching statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh statistics manually
  Future<void> refreshStatistics() async {
    await fetchStatistics(forceRefresh: true);
  }

  // Clear cached data
  void clearCache() {
    _statistics = null;
    _lastFetchTime = null;
    _setError(null);
    notifyListeners();
  }
}
