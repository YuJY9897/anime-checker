import 'anime.dart';

class WishItem {
  const WishItem({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.genres,
    required this.firstAirDate,
    this.isMovie = false,
  });

  final String id;
  final String title;
  final String posterUrl;
  final List<String> genres;
  final String firstAirDate;
  final bool isMovie;

  factory WishItem.fromAnime(Anime anime) => WishItem(
    id: anime.id,
    title: anime.title,
    posterUrl: anime.posterUrl,
    genres: anime.genres,
    firstAirDate: anime.firstAirDate,
    isMovie: anime.isMovie,
  );

  factory WishItem.fromJson(Map<String, dynamic> json) => WishItem(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    posterUrl: json['posterUrl'] as String? ?? '',
    genres: (json['genres'] as List? ?? const [])
        .map((item) => '$item')
        .toList(),
    firstAirDate: json['firstAirDate'] as String? ?? '',
    isMovie: json['isMovie'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'posterUrl': posterUrl,
    'genres': genres,
    'firstAirDate': firstAirDate,
    'isMovie': isMovie,
  };
}
