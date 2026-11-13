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

/// 시즌 0은 OVA·특별편(외전)이라 본편 진행률과 "이어볼 화"에서 뺀다.
/// 섞으면 다 본 작품이 미완으로 바뀌고 보관함 정렬과 통계가 흔들린다.
List<AnimeSeason> mainSeasons(Anime anime) =>
    anime.seasons.where((season) => season.number != 0).toList();

int watchedCount(AppData data, Anime anime) {
  var count = 0;
  for (final season in mainSeasons(anime)) {
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
    mainSeasons(anime).fold(0, (sum, season) => sum + season.episodes.length);

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
  return '최근 시즌 $latestSeason · $latestEpisode화';
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
    for (final season in mainSeasons(anime)) {
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

/// 방영일을 아는 화가 하나라도 있는지.
bool hasEpisodeAirDates(Anime anime) {
  for (final season in mainSeasons(anime)) {
    for (final episode in season.episodes) {
      if (parseDate(episode.airDate) != null) return true;
    }
  }
  return false;
}

/// 최근 14일 안에 나왔거나 앞으로 나올 화가 있는지.
bool airsAroundNow(Anime anime, {DateTime? now}) {
  final base = now ?? DateTime.now();
  final today = DateTime(base.year, base.month, base.day);
  final from = today.subtract(const Duration(days: 14));
  for (final season in mainSeasons(anime)) {
    for (final episode in season.episodes) {
      final date = parseDate(episode.airDate);
      if (date == null) continue;
      if (!DateTime(date.year, date.month, date.day).isBefore(from)) return true;
    }
  }
  return false;
}

/// 이번 주에 실제로 새 화가 나오는 작품인지. 편성표에 넣는 기준과
/// 보관함·상세의 요일 표시가 같은 함수를 써야, 보관함엔 '방영중 · 금요일'인데
/// 편성표엔 없는 모순이 생기지 않는다.
bool isOnAirThisWeek(Anime anime, {DateTime? now}) {
  if (!isAnimeCurrentlyAiring(
    anime.firstAirDate,
    status: anime.status,
    now: now,
  )) {
    return false;
  }
  if (hasEpisodeAirDates(anime) && !airsAroundNow(anime, now: now)) {
    return false;
  }
  return true;
}

Map<String, List<Anime>> scheduleByWeekday(AppData data) {
  final map = <String, List<Anime>>{};
  for (final anime in allAnime(data)) {
    // TMDB는 완결작도 'Returning Series'로 두는 일이 많다. 상태만 믿으면
    // 다 끝난 작품이 편성표에 영영 남으므로, 회차 정보가 있으면
    // 최근에 나왔거나 앞으로 나올 화가 있는지 함께 본다.
    if (!isOnAirThisWeek(anime)) continue;
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
      // 바로 아래 14일 창이 이미 범위를 좁힌다.
      // 연도까지 보면 1월 초에 작년 12월 방영분이 전부 걸러져 편성표가 빈다.
      if (date == null) continue;
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
