const _hiddenGenres = {'애니메이션', 'animation'};
const _unknownValues = {'???', '??', '?', '정보 없음', 'unknown', 'null'};
const _genreLabels = {
  'action': '액션',
  'adventure': '모험',
  'action & adventure': '액션/모험',
  'animation': '애니메이션',
  'comedy': '코미디',
  'crime': '범죄',
  'drama': '드라마',
  'family': '가족',
  'fantasy': '판타지',
  'kids': '키즈',
  'mystery': '미스터리',
  'romance': '로맨스',
  'sci-fi': '공상과학',
  'sci-fi & fantasy': '공상과학/판타지',
  'science fiction': '공상과학',
  'sf': '공상과학',
  'supernatural': '초자연',
  'thriller': '스릴러',
  'war & politics': '전쟁/정치',
};

List<String> visibleGenres(List<String> genres) {
  return genres
      .map(_genreLabel)
      .where(
        (genre) =>
            genre.isNotEmpty && !_hiddenGenres.contains(genre.toLowerCase()),
      )
      .toSet()
      .toList();
}

String _genreLabel(String value) {
  final genre = value.trim();
  return _genreLabels[genre.toLowerCase()] ?? genre;
}

bool hasUsefulText(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty && !_unknownValues.contains(normalized);
}
