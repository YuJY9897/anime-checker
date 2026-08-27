import 'episode.dart';

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
