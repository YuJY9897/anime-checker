import 'anime_movie.dart';
import 'anime_season.dart';

class Anime {
  const Anime({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.posterUrl,
    required this.genres,
    required this.status,
    required this.weekday,
    required this.firstAirDate,
    required this.seasons,
    required this.movies,
    required this.dropped,
    this.isMovie = false,
  });

  final String id;
  final String title;
  final String originalTitle;
  final String posterUrl;
  final List<String> genres;
  final String status;
  final String weekday;
  final String firstAirDate;
  final List<AnimeSeason> seasons;
  final List<AnimeMovie> movies;
  final bool dropped;

  /// 극장판/영화 여부 (Jikan type: Movie).
  final bool isMovie;

  Anime copyWith({bool? dropped}) => Anime(
    id: id,
    title: title,
    originalTitle: originalTitle,
    posterUrl: posterUrl,
    genres: genres,
    status: status,
    weekday: weekday,
    firstAirDate: firstAirDate,
    seasons: seasons,
    movies: movies,
    dropped: dropped ?? this.dropped,
    isMovie: isMovie,
  );

  factory Anime.fromJson(Map<String, dynamic> json) => Anime(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    originalTitle: json['originalTitle'] as String? ?? '',
    posterUrl: json['posterUrl'] as String? ?? '',
    genres: (json['genres'] as List? ?? const [])
        .map((item) => '$item')
        .toList(),
    status: json['status'] as String? ?? '',
    weekday: json['weekday'] as String? ?? '',
    firstAirDate: json['firstAirDate'] as String? ?? '',
    seasons: (json['seasons'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AnimeSeason.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    movies: (json['movies'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => AnimeMovie.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    dropped: json['dropped'] == true,
    isMovie:
        json['isMovie'] == true ||
        json['id']?.toString().startsWith('movie-') == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'originalTitle': originalTitle,
    'posterUrl': posterUrl,
    'genres': genres,
    'status': status,
    'weekday': weekday,
    'firstAirDate': firstAirDate,
    'seasons': seasons.map((item) => item.toJson()).toList(),
    'movies': movies.map((item) => item.toJson()).toList(),
    'dropped': dropped,
    'isMovie': isMovie,
  };
}
