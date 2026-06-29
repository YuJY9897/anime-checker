import 'dart:convert';

class Episode {
  const Episode({
    required this.number,
    required this.title,
    required this.airDate,
  });

  final int number;
  final String title;
  final String airDate;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    number: (json['number'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    airDate: json['airDate'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'airDate': airDate,
  };
}

class AnimeSeason {
  const AnimeSeason({
    required this.number,
    required this.name,
    required this.subtitle,
    required this.posterUrl,
    required this.episodes,
  });

  final int number;
  final String name;
  final String subtitle;
  final String posterUrl;
  final List<Episode> episodes;

  factory AnimeSeason.fromJson(Map<String, dynamic> json) => AnimeSeason(
    number: (json['number'] as num?)?.toInt() ?? 1,
    name: json['name'] as String? ?? '1기',
    subtitle: json['subtitle'] as String? ?? '',
    posterUrl: json['posterUrl'] as String? ?? '',
    episodes: (json['episodes'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Episode.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'subtitle': subtitle,
    'posterUrl': posterUrl,
    'episodes': episodes.map((item) => item.toJson()).toList(),
  };
}

class AnimeMovie {
  const AnimeMovie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.releaseDate,
    required this.runtime,
  });

  final String id;
  final String title;
  final String posterUrl;
  final String releaseDate;
  final int runtime;

  factory AnimeMovie.fromJson(Map<String, dynamic> json) => AnimeMovie(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    posterUrl: json['posterUrl'] as String? ?? '',
    releaseDate: json['releaseDate'] as String? ?? '',
    runtime: (json['runtime'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'posterUrl': posterUrl,
    'releaseDate': releaseDate,
    'runtime': runtime,
  };
}

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
  };
}

class WishItem {
  const WishItem({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.genres,
    required this.firstAirDate,
  });

  final String id;
  final String title;
  final String posterUrl;
  final List<String> genres;
  final String firstAirDate;

  factory WishItem.fromAnime(Anime anime) => WishItem(
    id: anime.id,
    title: anime.title,
    posterUrl: anime.posterUrl,
    genres: anime.genres,
    firstAirDate: anime.firstAirDate,
  );

  factory WishItem.fromJson(Map<String, dynamic> json) => WishItem(
    id: json['id']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    posterUrl: json['posterUrl'] as String? ?? '',
    genres: (json['genres'] as List? ?? const [])
        .map((item) => '$item')
        .toList(),
    firstAirDate: json['firstAirDate'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'posterUrl': posterUrl,
    'genres': genres,
    'firstAirDate': firstAirDate,
  };
}

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.date,
    required this.imageUrl,
    required this.url,
  });

  final String id;
  final String title;
  final String summary;
  final String source;
  final String date;
  final String imageUrl;
  final String url;

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
    id: json['id']?.toString() ?? json['url']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? json['content'] as String? ?? '',
    source: json['source'] as String? ?? '',
    date: json['date'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    url: json['url'] as String? ?? json['link'] as String? ?? '',
  );
}

class AppData {
  const AppData({
    required this.animeList,
    required this.watchedEpisodes,
    required this.watchedMovies,
    required this.wishList,
    required this.dropped,
    required this.animeNotes,
    required this.droppedReasons,
    required this.updatedAt,
    required this.backupVersion,
    required this.lastBackupAt,
  });

  factory AppData.empty() => AppData(
    animeList: const {},
    watchedEpisodes: const {},
    watchedMovies: const {},
    wishList: const {},
    dropped: const {},
    animeNotes: const {},
    droppedReasons: const {},
    updatedAt: DateTime.now(),
    backupVersion: 1,
    lastBackupAt: null,
  );

  final Map<String, Anime> animeList;
  final Map<String, bool> watchedEpisodes;
  final Map<String, bool> watchedMovies;
  final Map<String, WishItem> wishList;
  final Map<String, bool> dropped;
  final Map<String, String> animeNotes;
  final Map<String, String> droppedReasons;
  final DateTime updatedAt;
  final int backupVersion;
  final DateTime? lastBackupAt;

  AppData copyWith({
    Map<String, Anime>? animeList,
    Map<String, bool>? watchedEpisodes,
    Map<String, bool>? watchedMovies,
    Map<String, WishItem>? wishList,
    Map<String, bool>? dropped,
    Map<String, String>? animeNotes,
    Map<String, String>? droppedReasons,
    DateTime? updatedAt,
    int? backupVersion,
    DateTime? lastBackupAt,
  }) => AppData(
    animeList: animeList ?? this.animeList,
    watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
    watchedMovies: watchedMovies ?? this.watchedMovies,
    wishList: wishList ?? this.wishList,
    dropped: dropped ?? this.dropped,
    animeNotes: animeNotes ?? this.animeNotes,
    droppedReasons: droppedReasons ?? this.droppedReasons,
    updatedAt: updatedAt ?? this.updatedAt,
    backupVersion: backupVersion ?? this.backupVersion,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
  );

  factory AppData.fromJson(Map<String, dynamic> json) {
    Map<String, Anime> animeMapFrom(dynamic value) =>
        (value as Map? ?? const {}).map(
          (key, item) => MapEntry(
            '$key',
            Anime.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
    Map<String, bool> boolMapFrom(dynamic value) => (value as Map? ?? const {})
        .map((key, item) => MapEntry('$key', item == true));
    Map<String, String> stringMapFrom(dynamic value) =>
        (value as Map? ?? const {}).map(
          (key, item) => MapEntry('$key', '$item'),
        );
    Map<String, WishItem> wishMapFrom(dynamic value) =>
        (value as Map? ?? const {}).map(
          (key, item) => MapEntry(
            '$key',
            WishItem.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
    return AppData(
      animeList: animeMapFrom(json['animeList']),
      watchedEpisodes: boolMapFrom(json['watchedEpisodes']),
      watchedMovies: boolMapFrom(json['watchedMovies']),
      wishList: wishMapFrom(json['wishList']),
      dropped: boolMapFrom(json['dropped']),
      animeNotes: stringMapFrom(json['animeNotes']),
      droppedReasons: stringMapFrom(json['droppedReasons']),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      backupVersion: (json['backupVersion'] as num?)?.toInt() ?? 1,
      lastBackupAt: DateTime.tryParse(json['lastBackupAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'animeList': animeList.map((key, value) => MapEntry(key, value.toJson())),
    'watchedEpisodes': watchedEpisodes,
    'watchedMovies': watchedMovies,
    'wishList': wishList.map((key, value) => MapEntry(key, value.toJson())),
    'dropped': dropped,
    'animeNotes': animeNotes,
    'droppedReasons': droppedReasons,
    'updatedAt': updatedAt.toIso8601String(),
    'backupVersion': backupVersion,
    'lastBackupAt': lastBackupAt?.toIso8601String(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
