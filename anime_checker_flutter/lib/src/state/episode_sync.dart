// 방영 중인 작품의 회차를 다시 받아올 때 쓰는 판단·병합 규칙.
import '../data/models/models.dart';

/// 마지막 갱신에서 12시간이 지났으면 다시 받아온다.
bool needsEpisodeSync(AppData data, String animeId, DateTime now) {
  final last = DateTime.tryParse(data.animeSyncedAt[animeId] ?? '');
  if (last == null) return true;
  return now.difference(last) >= const Duration(hours: 12);
}

/// 마지막 갱신 시각. 기록이 없으면 가장 오래된 것으로 취급한다.
DateTime lastSyncedAt(AppData data, String animeId) {
  return DateTime.tryParse(data.animeSyncedAt[animeId] ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

/// 받아온 상세로 회차를 갱신하되, 아직 제목이 안 나온 화는 기존 제목을 지킨다.
Anime mergeEpisodes(Anime current, Anime fetched) {
  if (fetched.seasons.isEmpty) return current;
  final seasons = fetched.seasons.map((season) {
    final previous = current.seasons
        .where((item) => item.number == season.number)
        .toList();
    if (previous.isEmpty) return season;
    final oldTitles = {
      for (final episode in previous.first.episodes)
        episode.number: episode.title,
    };
    return AnimeSeason(
      number: season.number,
      name: season.name,
      subtitle: season.subtitle,
      posterUrl: season.posterUrl,
      episodes: season.episodes.map((episode) {
        if (!isPlaceholderEpisodeTitle(episode.title, episode.number)) {
          return episode;
        }
        final old = oldTitles[episode.number] ?? '';
        return Episode(
          number: episode.number,
          title: isPlaceholderEpisodeTitle(old, episode.number)
              ? '${episode.number}화'
              : old,
          airDate: episode.airDate,
        );
      }).toList(),
    );
  }).toList();
  return Anime(
    id: current.id,
    title: fetched.title.trim().isEmpty ? current.title : fetched.title,
    originalTitle: fetched.originalTitle,
    posterUrl: fetched.posterUrl.trim().isEmpty
        ? current.posterUrl
        : fetched.posterUrl,
    genres: fetched.genres.isEmpty ? current.genres : fetched.genres,
    status: fetched.status,
    weekday: fetched.weekday.trim().isEmpty ? current.weekday : fetched.weekday,
    firstAirDate: fetched.firstAirDate,
    seasons: seasons,
    movies: fetched.movies.isEmpty ? current.movies : fetched.movies,
    dropped: current.dropped,
    isMovie: current.isMovie,
  );
}
