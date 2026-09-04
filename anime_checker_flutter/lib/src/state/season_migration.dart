// 시즌 구성이 바뀐 작품의 시청 기록을 새 좌표로 옮긴다.
//
// TMDB가 여러 기수를 한 시즌에 몰아넣은 작품(블리치 366화 등)을 기수별로 나누면
// 시즌/화 번호가 전부 달라진다. 기록 키는 "작품id:s시즌:e화" 라서 그대로 두면 어긋난다.
// 프록시가 각 화에 원본 좌표(sourceSeason/sourceEpisode)를 실어 주므로 그걸로 짝을 맞춘다.
import '../data/models/models.dart';

String episodeKey(String animeId, int seasonNumber, int episodeNumber) =>
    '$animeId:s$seasonNumber:e$episodeNumber';

/// 새 시즌 구성에서 쓰이는 기록 키 전체.
Set<String> _keysOf(String animeId, List<AnimeSeason> seasons) {
  return {
    for (final season in seasons)
      for (final episode in season.episodes)
        episodeKey(animeId, season.number, episode.number),
  };
}

/// 시즌 구성이 실제로 바뀌었는지. 시즌 수나 각 시즌의 화수가 다르면 바뀐 것으로 본다.
bool seasonsChanged(List<AnimeSeason> before, List<AnimeSeason> after) {
  if (before.length != after.length) return true;
  for (var i = 0; i < before.length; i++) {
    if (before[i].episodes.length != after[i].episodes.length) return true;
    if (before[i].number != after[i].number) return true;
  }
  return false;
}

/// 옛 구성의 시청 기록을 새 구성으로 옮긴 결과를 돌려준다.
///
/// - 옛 구성에서 각 화의 원본 좌표를 찾아 "무엇을 봤는지"를 원본 기준으로 모은다.
/// - 새 구성의 각 화에 같은 원본 좌표가 있으면 시청 표시를 옮긴다.
/// - 원본 좌표가 없는 옛 데이터는 시즌/화 번호 자체를 원본으로 간주한다.
/// - 좌표로 못 찾으면 "작품에서 몇 번째 화인지"로 맞춘다.
///   TMDB가 시즌 구조를 바꾸면 옛 좌표(s2:e1)가 새 좌표계에 아예 없을 수 있는데,
///   순서는 그대로라서 순번으로는 정확히 짝이 맞는다.
/// - 이 작품의 옛 키는 지우고 새 키만 남긴다(중복 집계 방지).
Map<String, bool> migrateWatchedEpisodes({
  required String animeId,
  required Map<String, bool> watchedEpisodes,
  required List<AnimeSeason> before,
  required List<AnimeSeason> after,
}) {
  if (!seasonsChanged(before, after)) return watchedEpisodes;

  // 원본 좌표와 순번, 두 기준으로 시청한 화를 모은다.
  final watchedSources = <String>{};
  final watchedOrdinals = <int>{};
  var ordinal = 0;
  for (final season in before) {
    for (final episode in season.episodes) {
      ordinal += 1;
      final key = episodeKey(animeId, season.number, episode.number);
      if (watchedEpisodes[key] != true) continue;
      final sourceSeason = episode.sourceSeason > 0
          ? episode.sourceSeason
          : season.number;
      final sourceEpisode = episode.sourceEpisode > 0
          ? episode.sourceEpisode
          : episode.number;
      watchedSources.add('$sourceSeason:$sourceEpisode');
      watchedOrdinals.add(ordinal);
    }
  }
  // 순번으로 대신 맞춰도 될 만큼 화수가 비슷한지 본다.
  final beforeCount = before.fold<int>(0, (sum, s) => sum + s.episodes.length);
  final afterCount = after.fold<int>(0, (sum, s) => sum + s.episodes.length);
  final ordinalUsable = beforeCount > 0 && afterCount >= beforeCount;

  final next = Map<String, bool>.from(watchedEpisodes);
  // 이 작품의 기록을 일단 비우고 새 구성으로 다시 채운다.
  next.removeWhere((key, value) => key.startsWith('$animeId:'));

  var newOrdinal = 0;
  for (final season in after) {
    for (final episode in season.episodes) {
      newOrdinal += 1;
      final sourceSeason = episode.sourceSeason > 0
          ? episode.sourceSeason
          : season.number;
      final sourceEpisode = episode.sourceEpisode > 0
          ? episode.sourceEpisode
          : episode.number;
      final bySource = watchedSources.contains('$sourceSeason:$sourceEpisode');
      final byOrdinal = ordinalUsable && watchedOrdinals.contains(newOrdinal);
      if (!bySource && !byOrdinal) continue;
      next[episodeKey(animeId, season.number, episode.number)] = true;
    }
  }
  return next;
}

/// 옮기는 과정에서 잃은 기록 수. 새 구성에 자리가 없는 화는 사라진다.
int lostWatchedCount({
  required String animeId,
  required Map<String, bool> beforeWatched,
  required Map<String, bool> afterWatched,
}) {
  final before = beforeWatched.entries
      .where((e) => e.value && e.key.startsWith('$animeId:'))
      .length;
  final after = afterWatched.entries
      .where((e) => e.value && e.key.startsWith('$animeId:'))
      .length;
  final lost = before - after;
  return lost > 0 ? lost : 0;
}

/// 새 구성에 남지 않는 기록 키 목록(진단용).
Set<String> orphanKeys({
  required String animeId,
  required Map<String, bool> watchedEpisodes,
  required List<AnimeSeason> seasons,
}) {
  final valid = _keysOf(animeId, seasons);
  return watchedEpisodes.keys
      .where((key) => key.startsWith('$animeId:') && !valid.contains(key))
      .toSet();
}
