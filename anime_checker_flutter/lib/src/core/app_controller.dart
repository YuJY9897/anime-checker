import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';

import 'api_client.dart';
import 'date_text.dart';
import 'local_repository.dart';
import 'models.dart';

final localRepositoryProvider = Provider<LocalRepository>(
  (ref) => LocalRepository(),
);
final apiClientProvider = Provider<AnimeApiClient>((ref) => AnimeApiClient());

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController(
    ref.read(localRepositoryProvider),
    ref.read(apiClientProvider),
  );
});

class BackupSummary {
  const BackupSummary({
    required this.total,
    required this.dropped,
    required this.wish,
    required this.watched,
  });

  final int total;
  final int dropped;
  final int wish;
  final int watched;
}

class DataDiagnostics {
  const DataDiagnostics({
    required this.total,
    required this.noPoster,
    required this.noSeason,
    required this.noGenre,
    required this.dropped,
    required this.notes,
  });

  final int total;
  final int noPoster;
  final int noSeason;
  final int noGenre;
  final int dropped;
  final int notes;
}

class EpisodeTarget {
  const EpisodeTarget({
    required this.anime,
    required this.season,
    required this.episode,
  });

  final Anime anime;
  final AnimeSeason season;
  final Episode episode;
}

class AppController extends ChangeNotifier {
  AppController(this._localRepository, this._apiClient);

  final LocalRepository _localRepository;
  final AnimeApiClient _apiClient;

  AppData data = AppData.empty();
  List<Anime> searchResults = const [];
  List<Anime> newAnime = const [];
  List<NewsArticle> news = const [];
  bool ready = false;
  bool busy = false;
  String? error;
  String newAnimeBasis = '';
  String newsBasis = '';

  bool get apiConfigured => _apiClient.isConfigured;

  Future<void> load() async {
    busy = true;
    notifyListeners();
    try {
      data = await _localRepository.load();
      ready = true;
      newAnime = await _apiClient.fetchNewAnime();
      news = await _apiClient.fetchNews();
      newAnimeBasis = nowBasisText();
      newsBasis = nowBasisText();
      error = null;
    } catch (e) {
      error = '$e';
      ready = true;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  List<Anime> get allAnime =>
      data.animeList.values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));

  List<Anime> get libraryAnime =>
      allAnime.where((anime) => !isDropped(anime.id)).toList();

  List<Anime> get droppedAnime =>
      allAnime.where((anime) => isDropped(anime.id)).toList();

  List<WishItem> get wishItems =>
      data.wishList.values.toList()..sort((a, b) => a.title.compareTo(b.title));

  List<EpisodeTarget> get todayTargets {
    final today = DateTime.now();
    final targets = <EpisodeTarget>[];
    for (final anime in libraryAnime) {
      EpisodeTarget? nextTarget;
      for (final season in anime.seasons) {
        for (final episode in season.episodes) {
          final date = parseDate(episode.airDate);
          if (date == null) continue;
          final isAired = !DateTime(
            date.year,
            date.month,
            date.day,
          ).isAfter(DateTime(today.year, today.month, today.day));
          if (isAired &&
              !isEpisodeWatched(anime.id, season.number, episode.number)) {
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
    targets.sort((a, b) => a.episode.airDate.compareTo(b.episode.airDate));
    return targets;
  }

  Map<String, List<Anime>> get scheduleByWeekday {
    final map = <String, List<Anime>>{};
    for (final anime in allAnime) {
      final storedWeekday = normalizedWeekday(anime.weekday);
      final weekday = storedWeekday.isNotEmpty
          ? storedWeekday
          : inferredCurrentWeekday(anime);
      if (weekday.isEmpty) continue;
      if (!isCurrentlyAiring(anime)) continue;
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
        status.contains('방영 종료') ||
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

  bool isDropped(String animeId) =>
      data.dropped[animeId] == true || data.animeList[animeId]?.dropped == true;

  bool isWished(String animeId) => data.wishList.containsKey(animeId);

  bool isInLibrary(String animeId) => data.animeList.containsKey(animeId);

  String episodeKey(String animeId, int seasonNumber, int episodeNumber) =>
      '$animeId:s$seasonNumber:e$episodeNumber';

  bool isEpisodeWatched(String animeId, int seasonNumber, int episodeNumber) {
    return data.watchedEpisodes[episodeKey(
          animeId,
          seasonNumber,
          episodeNumber,
        )] ==
        true;
  }

  bool isMovieWatched(String movieId) => data.watchedMovies[movieId] == true;

  int watchedCount(Anime anime) {
    var count = 0;
    for (final season in anime.seasons) {
      for (final episode in season.episodes) {
        if (isEpisodeWatched(anime.id, season.number, episode.number)) count++;
      }
    }
    return count;
  }

  int watchedCountForSeason(Anime anime, AnimeSeason season) {
    var count = 0;
    for (final episode in season.episodes) {
      if (isEpisodeWatched(anime.id, season.number, episode.number)) count++;
    }
    return count;
  }

  int totalEpisodeCount(Anime anime) =>
      anime.seasons.fold(0, (sum, season) => sum + season.episodes.length);

  String progressLabel(Anime anime) {
    final total = totalEpisodeCount(anime);
    final watched = watchedCount(anime);
    if (total == 0) return '정보 확인 중';
    if (watched >= total) return '$watched/$total화 완료';
    final percent = ((watched / total) * 100).round();
    return '$watched/$total화 · $percent%';
  }

  String latestWatchLabel(Anime anime) {
    var latestSeason = 0;
    var latestEpisode = 0;
    for (final season in anime.seasons) {
      for (final episode in season.episodes) {
        if (isEpisodeWatched(anime.id, season.number, episode.number)) {
          latestSeason = season.number;
          latestEpisode = episode.number;
        }
      }
    }
    if (latestEpisode == 0) return '아직 시청 기록 없음';
    return '최근 $latestSeason기 $latestEpisode화';
  }

  String animeNote(String animeId) => data.animeNotes[animeId]?.trim() ?? '';

  String droppedReason(String animeId) =>
      data.droppedReasons[animeId]?.trim() ?? '';

  double progressRatio(Anime anime) {
    final total = totalEpisodeCount(anime);
    if (total == 0) return 0;
    return watchedCount(anime) / total;
  }

  Future<void> search(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      searchResults = const [];
      error = null;
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final localResults = _searchLocal(keyword);
      if (_apiClient.isConfigured) {
        final remoteResults = await _apiClient.search(keyword);
        searchResults = _mergeAnimeResults(localResults, remoteResults);
      } else {
        searchResults = localResults;
      }
      error = null;
    } catch (e) {
      error = '$e';
      searchResults = _searchLocal(keyword);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshNewAnime() async {
    busy = true;
    notifyListeners();
    try {
      newAnime = await _apiClient.fetchNewAnime();
      newAnimeBasis = nowBasisText();
      error = null;
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshNews() async {
    busy = true;
    notifyListeners();
    try {
      news = await _apiClient.fetchNews();
      newsBasis = nowBasisText();
      error = null;
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  List<Anime> _searchLocal(String keyword) {
    final lowered = keyword.toLowerCase();
    return allAnime.where((anime) {
      return anime.id.toLowerCase().contains(lowered) ||
          anime.title.toLowerCase().contains(lowered) ||
          anime.originalTitle.toLowerCase().contains(lowered);
    }).toList();
  }

  List<Anime> _mergeAnimeResults(List<Anime> local, List<Anime> remote) {
    final merged = <String, Anime>{};
    for (final item in local) {
      merged[item.id] = item;
    }
    for (final item in remote) {
      merged.putIfAbsent(item.id, () => item);
    }
    return merged.values.toList();
  }

  Future<void> addAnime(Anime anime) async {
    final list = Map<String, Anime>.from(data.animeList)
      ..[anime.id] = anime.copyWith(dropped: false);
    final wish = Map<String, WishItem>.from(data.wishList)..remove(anime.id);
    final dropped = Map<String, bool>.from(data.dropped)..remove(anime.id);
    await _commit(
      data.copyWith(animeList: list, wishList: wish, dropped: dropped),
    );
  }

  Future<void> addWish(Anime anime) async {
    if (isInLibrary(anime.id)) return;
    final wish = Map<String, WishItem>.from(data.wishList)
      ..[anime.id] = WishItem.fromAnime(anime);
    await _commit(data.copyWith(wishList: wish));
  }

  Future<void> toggleWish(Anime anime) async {
    if (isWished(anime.id)) {
      await removeWish(anime.id);
    } else {
      await addWish(anime);
    }
  }

  Future<void> removeWish(String animeId) async {
    final wish = Map<String, WishItem>.from(data.wishList)..remove(animeId);
    await _commit(data.copyWith(wishList: wish));
  }

  Future<void> addWishToLibrary(WishItem item) async {
    final anime = Anime(
      id: item.id,
      title: item.title,
      originalTitle: '',
      posterUrl: item.posterUrl,
      genres: item.genres,
      status: '정보 확인 중',
      weekday: '',
      firstAirDate: item.firstAirDate,
      seasons: const [],
      movies: const [],
      dropped: false,
    );
    await addAnime(anime);
  }

  Future<void> toggleDropped(String animeId) async {
    final anime = data.animeList[animeId];
    if (anime == null) return;
    final next = !isDropped(animeId);
    final list = Map<String, Anime>.from(data.animeList)
      ..[animeId] = anime.copyWith(dropped: next);
    final dropped = Map<String, bool>.from(data.dropped);
    if (next) {
      dropped[animeId] = true;
    } else {
      dropped.remove(animeId);
    }
    final reasons = Map<String, String>.from(data.droppedReasons);
    if (!next) reasons.remove(animeId);
    await _commit(
      data.copyWith(animeList: list, dropped: dropped, droppedReasons: reasons),
    );
  }

  Future<void> deleteAnime(String animeId) async {
    final list = Map<String, Anime>.from(data.animeList)..remove(animeId);
    final dropped = Map<String, bool>.from(data.dropped)..remove(animeId);
    final notes = Map<String, String>.from(data.animeNotes)..remove(animeId);
    final reasons = Map<String, String>.from(data.droppedReasons)
      ..remove(animeId);
    final watched = Map<String, bool>.from(data.watchedEpisodes)
      ..removeWhere((key, value) => key.startsWith('$animeId:'));
    await _commit(
      data.copyWith(
        animeList: list,
        dropped: dropped,
        animeNotes: notes,
        droppedReasons: reasons,
        watchedEpisodes: watched,
      ),
    );
  }

  Future<void> setAnimeNote(String animeId, String note) async {
    if (!data.animeList.containsKey(animeId)) return;
    final notes = Map<String, String>.from(data.animeNotes);
    final value = note.trim();
    if (value.isEmpty) {
      notes.remove(animeId);
    } else {
      notes[animeId] = value;
    }
    await _commit(data.copyWith(animeNotes: notes));
  }

  Future<void> setDroppedReason(String animeId, String reason) async {
    if (!data.animeList.containsKey(animeId)) return;
    final reasons = Map<String, String>.from(data.droppedReasons);
    final value = reason.trim();
    if (value.isEmpty) {
      reasons.remove(animeId);
    } else {
      reasons[animeId] = value;
    }
    await _commit(data.copyWith(droppedReasons: reasons));
  }

  Future<void> setEpisodeWatched(
    Anime anime,
    AnimeSeason season,
    Episode episode,
    bool watched,
  ) async {
    final next = Map<String, bool>.from(data.watchedEpisodes);
    for (final item in season.episodes) {
      final key = episodeKey(anime.id, season.number, item.number);
      if (watched && item.number <= episode.number) {
        next[key] = true;
      } else if (!watched && item.number >= episode.number) {
        next.remove(key);
      }
    }
    await _commit(data.copyWith(watchedEpisodes: next));
  }

  Future<void> toggleMovieWatched(AnimeMovie movie) async {
    final next = Map<String, bool>.from(data.watchedMovies);
    if (next[movie.id] == true) {
      next.remove(movie.id);
    } else {
      next[movie.id] = true;
    }
    await _commit(data.copyWith(watchedMovies: next));
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

  DataDiagnostics diagnostics() {
    final items = data.animeList.values;
    return DataDiagnostics(
      total: items.length,
      noPoster: items.where((anime) => anime.posterUrl.trim().isEmpty).length,
      noSeason: items.where((anime) => anime.seasons.isEmpty).length,
      noGenre: items.where((anime) => anime.genres.isEmpty).length,
      dropped: droppedAnime.length,
      notes: data.animeNotes.length,
    );
  }

  Future<File> exportBackup() async {
    final now = DateTime.now();
    final next = data.copyWith(lastBackupAt: now);
    await _commit(next);
    return _localRepository.exportBackup(next);
  }

  Future<void> shareBackup() async {
    final file = await exportBackup();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: '애니 체크 백업'),
    );
  }

  Future<AppData?> pickBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return _localRepository.parseBackup(await File(path).readAsString());
  }

  Future<void> restoreBackup(AppData backup) async =>
      _commit(backup.copyWith(updatedAt: DateTime.now()));

  Future<void> _commit(AppData next) async {
    data = next.copyWith(updatedAt: DateTime.now());
    await _localRepository.save(data);
    notifyListeners();
  }
}
