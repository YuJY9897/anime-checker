class Episode {
  const Episode({
    required this.number,
    required this.title,
    required this.airDate,
    this.sourceSeason = 0,
    this.sourceEpisode = 0,
  });

  final int number;
  final String title;
  final String airDate;

  /// 시즌을 나누기 전 원래 좌표. 기수가 재편되어도 시청 기록을 옮길 수 있게 들고 다닌다.
  /// 0이면 원본 좌표를 모른다는 뜻이다.
  final int sourceSeason;
  final int sourceEpisode;

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    number: (json['number'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    airDate: json['airDate'] as String? ?? '',
    sourceSeason: (json['sourceSeason'] as num?)?.toInt() ?? 0,
    sourceEpisode: (json['sourceEpisode'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'airDate': airDate,
    if (sourceSeason > 0) 'sourceSeason': sourceSeason,
    if (sourceEpisode > 0) 'sourceEpisode': sourceEpisode,
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
