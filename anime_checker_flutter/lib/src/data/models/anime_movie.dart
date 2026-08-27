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
