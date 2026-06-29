const _hiddenGenres = {'애니메이션', 'animation'};
const _unknownValues = {'???', '??', '?', '정보 없음', 'unknown', 'null'};

List<String> visibleGenres(List<String> genres) {
  return genres
      .map((genre) => genre.trim())
      .where(
        (genre) =>
            genre.isNotEmpty && !_hiddenGenres.contains(genre.toLowerCase()),
      )
      .toList();
}

bool hasUsefulText(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isNotEmpty && !_unknownValues.contains(normalized);
}
