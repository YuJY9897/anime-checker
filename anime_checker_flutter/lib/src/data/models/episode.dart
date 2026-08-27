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

bool isPlaceholderEpisodeTitle(String title, int number) {
  final text = title.trim();
  if (text.isEmpty || text == '$number화') return true;
  return RegExp(
    '^(에피소드|episode|第)\\s*$number\\s*(화|話)?\$',
    caseSensitive: false,
  ).hasMatch(text);
}

/// 목록에 표시할 회차 라벨. 제목이 있으면 "12화 : 제목".
String episodeLabel(Episode episode) {
  if (isPlaceholderEpisodeTitle(episode.title, episode.number)) {
    return '${episode.number}화';
  }
  return '${episode.number}화 : ${episode.title.trim()}';
}
