// 저장된 데이터에서 값을 읽어 계산하는 순수 함수 모음.
// 상태를 바꾸지 않으므로 컨트롤러 없이도 그대로 테스트할 수 있다.
import '../core/format/date_text.dart';
import '../data/models/models.dart';

List<Anime> allAnime(AppData data) =>
    data.animeList.values.toList()..sort((a, b) => a.title.compareTo(b.title));

bool isDropped(AppData data, String animeId) =>
    data.dropped[animeId] == true || data.animeList[animeId]?.dropped == true;

List<Anime> libraryAnime(AppData data) =>
    allAnime(data).where((anime) => !isDropped(data, anime.id)).toList();

List<Anime> droppedAnime(AppData data) =>
    allAnime(data).where((anime) => isDropped(data, anime.id)).toList();

List<WishItem> wishItems(AppData data) =>
    data.wishList.values.toList()..sort((a, b) => a.title.compareTo(b.title));

bool isWished(AppData data, String animeId) =>
    data.wishList.containsKey(animeId);

bool isInLibrary(AppData data, String animeId) =>
    data.animeList.containsKey(animeId);

String episodeKey(String animeId, int seasonNumber, int episodeNumber) =>
    '$animeId:s$seasonNumber:e$episodeNumber';

bool isEpisodeWatched(
  AppData data,
  String animeId,
  int seasonNumber,
  int episodeNumber,
) {
  return data.watchedEpisodes[episodeKey(
        animeId,
        seasonNumber,
        episodeNumber,
      )] ==
      true;
}

bool isMovieWatched(AppData data, String movieId) =>
    data.watchedMovies[movieId] == true;

int watchedCount(AppData data, Anime anime) {
  var count = 0;
  for (final season in anime.seasons) {
    for (final episode in season.episodes) {
      if (isEpisodeWatched(data, anime.id, season.number, episode.number)) {
        count++;
      }
    }
  }
  return count;
}

int watchedCountForSeason(AppData data, Anime anime, AnimeSeason season) {
  var count = 0;
  for (final episode in season.episodes) {
    if (isEpisodeWatched(data, anime.id, season.number, episode.number)) {
      count++;
    }
  }
  return count;
}

int totalEpisodeCount(Anime anime) =>
    anime.seasons.fold(0, (sum, season) => sum + season.episodes.length);

String progressLabel(AppData data, Anime anime) {
  final total = totalEpisodeCount(anime);
  final watched = watchedCount(data, anime);
  if (total == 0) return '정보 확인 중';
  if (watched >= total) return '$watched/$total화 완료';
  final percent = ((watched / total) * 100).round();
  return '$watched/$total화 · $percent%';
}

String latestWatchLabel(AppData data, Anime anime) {
  var latestSeason = 0;
  var latestEpisode = 0;
  for (final season in anime.seasons) {
    for (final episode in season.episodes) {
      if (isEpisodeWatched(data, anime.id, season.number, episode.number)) {
        latestSeason = season.number;
        latestEpisode = episode.number;
      }
    }
  }
  if (latestEpisode == 0) return '아직 시청 기록 없음';
  return '최근 $latestSeason기 $latestEpisode화';
}

double progressRatio(AppData data, Anime anime) {
  final total = totalEpisodeCount(anime);
  if (total == 0) return 0;
  return watchedCount(data, anime) / total;
}

String animeNote(AppData data, String animeId) =>
    data.animeNotes[animeId]?.trim() ?? '';

String droppedReason(AppData data, String animeId) =>
    data.droppedReasons[animeId]?.trim() ?? '';

/// 보관함에서 오늘 이어볼 화를 작품마다 하나씩 골라 방영일 순으로 정렬한다.
List<EpisodeTarget> todayTargets(AppData data) {
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final targets = <EpisodeTarget>[];
  for (final anime in libraryAnime(data)) {
    EpisodeTarget? nextTarget;
    for (final season in anime.seasons) {
      for (final episode in season.episodes) {
        final date = parseDate(episode.airDate);
        if (date != null) {
          final airDay = DateTime(date.year, date.month, date.day);
          if (airDay.isAfter(todayOnly)) continue;
        }
        if (!isEpisodeWatched(data, anime.id, season.number, episode.number)) {
          nextTarget = EpisodeTarget(
            anime: anime,
            season: season,
            episode: episode,
          );
          break;
        }
      }
      if (nextTarget != null) break;
    }
    if (nextTarget != null) targets.add(nextTarget);
  }
  targets.sort(_compareEpisodeTargets);
  return targets;
}

int _compareEpisodeTargets(EpisodeTarget a, EpisodeTarget b) {
  final aDate = parseDate(a.episode.airDate);
  final bDate = parseDate(b.episode.airDate);
  if (aDate != null && bDate != null) {
    final compared = aDate.compareTo(bDate);
    if (compared != 0) return compared;
  } else if (aDate != null) {
    return -1;
  } else if (bDate != null) {
    return 1;
  }
  return a.anime.title.compareTo(b.anime.title);
}

Map<String, List<Anime>> scheduleByWeekday(AppData data) {
  final map = <String, List<Anime>>{};
  for (final anime in allAnime(data)) {
    if (!isCurrentlyAiring(anime)) continue;
    final storedWeekday = normalizedWeekday(anime.weekday);
    final weekday = storedWeekday.isNotEmpty
        ? storedWeekday
        : inferredCurrentWeekday(anime);
    if (weekday.isEmpty) continue;
    map.putIfAbsent(weekday, () => []).add(anime);
  }
  for (final items in map.values) {
    items.sort((a, b) => a.title.compareTo(b.title));
  }
  return map;
}

bool isCurrentlyAiring(Anime anime) {
  final status = anime.status.trim().toLowerCase();
  final ended =
      status.contains('ended') ||
      status.contains('canceled') ||
      status.contains('cancelled') ||
      status.contains('종료') ||
      status.contains('완결') ||
      status.contains('종영') ||
      status.contains('취소');
  if (ended) return false;
  if (status.isNotEmpty) return true;
  return inferredCurrentWeekday(anime).isNotEmpty;
}

String normalizedWeekday(String value) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  final text = value.trim();
  for (final weekday in weekdays) {
    if (text.contains(weekday)) return weekday;
  }
  return '';
}

/// 편성 요일이 저장돼 있지 않으면 최근 방영일에서 요일을 추정한다.
String inferredCurrentWeekday(Anime anime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime? bestDate;
  for (final season in anime.seasons) {
    for (final episode in season.episodes) {
      final date = parseDate(episode.airDate);
      if (date == null || date.year != today.year) continue;
      final day = DateTime(date.year, date.month, date.day);
      if (day.isBefore(today.subtract(const Duration(days: 14)))) continue;
      if (bestDate == null || day.isBefore(bestDate)) bestDate = day;
    }
  }
  if (bestDate == null) return '';
  return weekdayLabel(bestDate);
}

List<Anime> searchLocal(AppData data, String keyword) {
  final lowered = keyword.toLowerCase();
  return allAnime(data).where((anime) {
    return anime.id.toLowerCase().contains(lowered) ||
        anime.title.toLowerCase().contains(lowered) ||
        anime.originalTitle.toLowerCase().contains(lowered);
  }).toList();
}

/// 저장된 작품을 앞세우고, 검색 결과에만 있는 작품을 뒤에 붙인다.
List<Anime> mergeAnimeResults(List<Anime> local, List<Anime> remote) {
  final merged = <String, Anime>{};
  for (final item in local) {
    merged[item.id] = item;
  }
  for (final item in remote) {
    merged.putIfAbsent(item.id, () => item);
  }
  return merged.values.toList();
}

BackupSummary summarize(AppData target) {
  return BackupSummary(
    total: target.animeList.length,
    dropped: target.dropped.values.where((value) => value).length,
    wish: target.wishList.length,
    watched:
        target.watchedEpisodes.values.where((value) => value).length +
        target.watchedMovies.values.where((value) => value).length,
  );
}

DataDiagnostics diagnostics(AppData data) {
  final items = data.animeList.values;
  return DataDiagnostics(
    total: items.length,
    noPoster: items.where((anime) => anime.posterUrl.trim().isEmpty).length,
    noSeason: items.where((anime) => anime.seasons.isEmpty).length,
    noGenre: items.where((anime) => anime.genres.isEmpty).length,
    dropped: droppedAnime(data).length,
    notes: data.animeNotes.length,
  );
}
