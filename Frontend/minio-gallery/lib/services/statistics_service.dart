import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/public_statistics.dart';

class StatisticsService {
  static const String baseUrl = 'http://localhost:8080/api/statistics';

  /// Ottiene le statistiche pubbliche per la home screen
  /// Non richiede autenticazione
  Future<PublicStatistics> getPublicStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/public'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return PublicStatistics.fromJson(data);
      } else {
        throw Exception('Failed to load public statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
