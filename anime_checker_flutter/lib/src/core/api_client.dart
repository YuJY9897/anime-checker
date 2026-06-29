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
    final json = await _get('/new-anime?region=KR');
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

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API ${response.statusCode}');
    }
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
