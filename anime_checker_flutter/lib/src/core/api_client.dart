import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'sample_data.dart';

class AnimeApiClient {
  AnimeApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment('ANIME_CHECKER_API_BASE');
  final http.Client _client;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Future<List<Anime>> search(String query) async {
    if (!isConfigured || query.trim().isEmpty) {
      return sampleAnimeList()
          .where((anime) => anime.title.contains(query.trim()))
          .toList();
    }
    final json = await _get(
      '/search?q=${Uri.encodeQueryComponent(query.trim())}',
    );
    return _animeListFrom(json);
  }

  Future<Anime?> fetchAnime(String tmdbId) async {
    if (!isConfigured) {
      for (final item in sampleAnimeList()) {
        if (item.id == tmdbId) return item;
      }
      return null;
    }
    final json = await _get('/anime/$tmdbId');
    return Anime.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Anime>> fetchNewAnime() async {
    if (!isConfigured) return sampleNewAnime();
    final today = DateTime.now();
    final until =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final json = await _get('/new-anime?region=KR&until=$until');
    return _animeListFrom(json);
  }

  Future<List<NewsArticle>> fetchNews() async {
    if (!isConfigured) return sampleNews();
    final json = await _get('/news');
    final rawList = json is Map ? json['items'] : json;
    return (rawList as List? ?? const [])
        .whereType<Map>()
        .map((item) => NewsArticle.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> submitFeedback({
    required String category,
    required String title,
    required String body,
    String email = '',
  }) async {
    if (!isConfigured) throw Exception('피드백 서버가 설정되지 않았습니다.');
    await _post('/feedback', {
      'category': category,
      'title': title,
      'body': body,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0+1',
    });
  }

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json; charset=utf-8'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API ${response.statusCode}');
    }
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  List<Anime> _animeListFrom(dynamic json) {
    final rawList = json is Map ? (json['items'] ?? json['results']) : json;
    return (rawList as List? ?? const [])
        .whereType<Map>()
        .map((item) => Anime.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
