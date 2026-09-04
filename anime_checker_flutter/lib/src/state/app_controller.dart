import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';

import '../core/format/date_text.dart';
import '../data/local/local_repository.dart';
import '../data/models/models.dart';
import '../data/remote/api_client.dart';
import 'anime_mutation.dart' as mutate;
import 'anime_query.dart' as query;
import 'episode_sync.dart' as sync;
import 'season_migration.dart' as migration;

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

/// 앱 전체가 공유하는 상태를 들고, 저장과 화면 갱신을 맡는다.
/// 계산은 anime_query, 데이터 변경은 anime_mutation, 회차 갱신 규칙은
/// episode_sync에 있고 여기서는 그 결과를 저장하고 알리는 일만 한다.
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
  bool newAnimeLoading = false;
  bool newsLoading = false;
  bool episodeSyncing = false;

  /// 보관함 전체 다시 받기 진행 상태.
  bool refreshingAll = false;
  int refreshAllDone = 0;
  int refreshAllTotal = 0;
  bool _cancelRefreshAll = false;
  String newAnimeBasis = '';
  String newsBasis = '';

  bool get apiConfigured => _apiClient.isConfigured;

  AppSettings get settings => data.settings;

  Future<void> load() async {
    busy = true;
    notifyListeners();
    try {
      data = await _localRepository.load();
      ready = true;
      error = null;
    } catch (e) {
      error = '$e';
      ready = true;
    } finally {
      busy = false;
      notifyListeners();
    }
    // 회차 갱신은 네트워크를 여러 번 타므로 앱 진입을 막지 않고 뒤에서 돌린다.
    _episodeSyncTask = syncAiringEpisodes();
    unawaited(_episodeSyncTask!);
  }

  // --- 조회 -----------------------------------------------------------------

  List<Anime> get allAnime => query.allAnime(data);

  List<Anime> get libraryAnime => query.libraryAnime(data);

  List<Anime> get droppedAnime => query.droppedAnime(data);

  List<WishItem> get wishItems => query.wishItems(data);

  List<EpisodeTarget> get todayTargets => query.todayTargets(data);

  Map<String, List<Anime>> get scheduleByWeekday => query.scheduleByWeekday(data);

  bool isCurrentlyAiring(Anime anime) => query.isCurrentlyAiring(anime);

  String normalizedWeekday(String value) => query.normalizedWeekday(value);

  String inferredCurrentWeekday(Anime anime) =>
      query.inferredCurrentWeekday(anime);

  bool isDropped(String animeId) => query.isDropped(data, animeId);

  bool isWished(String animeId) => query.isWished(data, animeId);

  bool isInLibrary(String animeId) => query.isInLibrary(data, animeId);

  String episodeKey(String animeId, int seasonNumber, int episodeNumber) =>
      query.episodeKey(animeId, seasonNumber, episodeNumber);

  bool isEpisodeWatched(String animeId, int seasonNumber, int episodeNumber) =>
      query.isEpisodeWatched(data, animeId, seasonNumber, episodeNumber);

  bool isMovieWatched(String movieId) => query.isMovieWatched(data, movieId);

  int watchedCount(Anime anime) => query.watchedCount(data, anime);

  int watchedCountForSeason(Anime anime, AnimeSeason season) =>
      query.watchedCountForSeason(data, anime, season);

  int totalEpisodeCount(Anime anime) => query.totalEpisodeCount(anime);

  String progressLabel(Anime anime) => query.progressLabel(data, anime);

  String latestWatchLabel(Anime anime) => query.latestWatchLabel(data, anime);

  double progressRatio(Anime anime) => query.progressRatio(data, anime);

  String animeNote(String animeId) => query.animeNote(data, animeId);

  String droppedReason(String animeId) => query.droppedReason(data, animeId);

  BackupSummary summarize(AppData target) => query.summarize(target);

  DataDiagnostics diagnostics() => query.diagnostics(data);

  // --- 회차 갱신 ------------------------------------------------------------

  Future<void>? _episodeSyncTask;

  /// 뒤에서 돌고 있는 회차 갱신이 끝날 때까지 기다린다(없으면 즉시 완료).
  Future<void> get pendingEpisodeSync async => _episodeSyncTask;

  /// 보관함의 모든 작품 정보를 처음부터 다시 받는다.
  ///
  /// 완결작은 자동 갱신 대상이 아니라서, 기수가 뭉쳐 있던 작품을 나누려면
  /// 이렇게 한 번 훑어야 한다. 시청 기록은 새 좌표로 옮겨진다.
  Future<void> refreshAllAnimeDetails() async {
    if (!_apiClient.isConfigured || refreshingAll || episodeSyncing) return;
    final targets = allAnime
        .where((anime) => !anime.isMovie && !anime.id.startsWith('movie-'))
        .toList();
    if (targets.isEmpty) return;

    refreshingAll = true;
    _cancelRefreshAll = false;
    refreshAllDone = 0;
    refreshAllTotal = targets.length;
    notifyListeners();

    final now = DateTime.now();
    final list = Map<String, Anime>.from(data.animeList);
    final syncedAt = Map<String, String>.from(data.animeSyncedAt);
    var watched = data.watchedEpisodes;
    var changed = false;
    try {
      for (final anime in targets) {
        if (_cancelRefreshAll) break;
        try {
          final fetched = await _apiClient.fetchAnime(anime.id);
          if (fetched != null && fetched.seasons.isNotEmpty) {
            final merged = sync.mergeEpisodes(anime, fetched);
            watched = migration.migrateWatchedEpisodes(
              animeId: anime.id,
              watchedEpisodes: watched,
              before: anime.seasons,
              after: merged.seasons,
            );
            list[anime.id] = merged;
            syncedAt[anime.id] = now.toIso8601String();
            changed = true;
          }
        } catch (_) {
          // 한 작품이 실패해도 나머지는 계속 받는다.
        }
        refreshAllDone += 1;
        notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      if (changed) {
        await _commit(
          mutate
              .withSyncedAnime(data, list, syncedAt)
              .copyWith(watchedEpisodes: watched),
        );
      }
    } finally {
      refreshingAll = false;
      notifyListeners();
    }
  }

  /// 진행 중인 전체 다시 받기를 멈춘다. 지금까지 받은 내용은 그대로 저장된다.
  void cancelRefreshAll() {
    _cancelRefreshAll = true;
  }

  /// 방영 중인 작품의 새 화(제목/방영일)를 프록시에서 다시 받아온다.
  /// 새 화는 매주 나오는데 저장된 상세는 추가 시점에서 멈춰 있어 갱신이 필요하다.
  Future<void> syncAiringEpisodes({bool force = false}) async {
    if (!_apiClient.isConfigured || episodeSyncing) return;
    final now = DateTime.now();
    final targets = libraryAnime
        .where((anime) => !anime.isMovie && !anime.id.startsWith('movie-'))
        .where(query.isCurrentlyAiring)
        .where((anime) => force || sync.needsEpisodeSync(data, anime.id, now))
        .toList()
      // 오래 갱신되지 않은 작품부터 처리해 특정 작품만 계속 밀리지 않게 한다.
      ..sort((a, b) => sync.lastSyncedAt(data, a.id).compareTo(
            sync.lastSyncedAt(data, b.id),
          ));
    final batch = targets.take(12).toList();
    if (batch.isEmpty) return;

    episodeSyncing = true;
    notifyListeners();
    final list = Map<String, Anime>.from(data.animeList);
    final syncedAt = Map<String, String>.from(data.animeSyncedAt);
    var watched = data.watchedEpisodes;
    var changed = false;
    try {
      for (final anime in batch) {
        try {
          final fetched = await _apiClient.fetchAnime(anime.id);
          if (fetched != null) {
            final merged = sync.mergeEpisodes(anime, fetched);
            // 기수가 재편됐으면 시청 기록도 새 좌표로 옮긴다.
            watched = migration.migrateWatchedEpisodes(
              animeId: anime.id,
              watchedEpisodes: watched,
              before: anime.seasons,
              after: merged.seasons,
            );
            list[anime.id] = merged;
            syncedAt[anime.id] = now.toIso8601String();
            changed = true;
          }
        } catch (_) {
          // 한 작품이 실패해도 나머지는 계속 갱신한다.
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      if (changed) {
        await _commit(
          mutate
              .withSyncedAnime(data, list, syncedAt)
              .copyWith(watchedEpisodes: watched),
        );
      }
    } finally {
      episodeSyncing = false;
      notifyListeners();
    }
  }

  Future<void> refreshAnimeDetail(String animeId) async {
    final current = data.animeList[animeId];
    if (current == null || current.id.startsWith('movie-')) return;
    final fetched = await _apiClient.fetchAnime(animeId);
    if (fetched == null) return;
    final next = current.seasons.isEmpty
        ? fetched.copyWith(dropped: current.dropped)
        : sync.mergeEpisodes(current, fetched);
    final migrated = migration.migrateWatchedEpisodes(
      animeId: animeId,
      watchedEpisodes: data.watchedEpisodes,
      before: current.seasons,
      after: next.seasons,
    );
    await _commit(
      mutate
          .withAnimeDetail(data, animeId, next)
          .copyWith(watchedEpisodes: migrated),
    );
  }

  /// 상세 화면을 열기 전에 보여줄 정보를 준비한다. 저장본이 있으면 그대로 쓴다.
  Future<Anime> previewAnimeDetail(Anime anime) async {
    final stored = data.animeList[anime.id];
    if (stored != null &&
        (stored.seasons.isNotEmpty || stored.movies.isNotEmpty)) {
      return stored;
    }
    if (anime.id.startsWith('movie-') ||
        anime.seasons.isNotEmpty ||
        anime.movies.isNotEmpty) {
      return anime;
    }
    try {
      return await _apiClient.fetchAnime(anime.id) ?? anime;
    } catch (_) {
      return anime;
    }
  }

  // --- 검색·신작·소식 --------------------------------------------------------

  Future<void> search(String text) async {
    final keyword = text.trim();
    if (keyword.isEmpty) {
      searchResults = const [];
      error = null;
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final localResults = query.searchLocal(data, keyword);
      if (_apiClient.isConfigured) {
        final remoteResults = await _apiClient.search(keyword);
        searchResults = query.mergeAnimeResults(localResults, remoteResults);
      } else {
        searchResults = localResults;
      }
      error = null;
    } catch (e) {
      error = '$e';
      searchResults = query.searchLocal(data, keyword);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> ensureNewAnimeLoaded() async {
    if (newAnime.isNotEmpty || newAnimeLoading) return;
    await refreshNewAnime();
  }

  Future<void> refreshNewAnime() async {
    newAnimeLoading = true;
    notifyListeners();
    try {
      newAnime = await _apiClient.fetchNewAnime();
      newAnimeBasis = nowBasisText();
      error = null;
    } catch (e) {
      error = '$e';
    } finally {
      newAnimeLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureNewsLoaded() async {
    if (news.isNotEmpty || newsLoading) return;
    await refreshNews();
  }

  Future<void> refreshNews() async {
    newsLoading = true;
    notifyListeners();
    try {
      news = await _apiClient.fetchNews();
      newsBasis = nowBasisText();
      error = null;
    } catch (e) {
      error = '$e';
    } finally {
      newsLoading = false;
      notifyListeners();
    }
  }

  // --- 보관함 ---------------------------------------------------------------

  /// 회차 정보가 없는 작품은 추가하면서 상세를 한 번 받아온다.
  Future<void> addAnime(Anime anime) async {
    var stored = anime.copyWith(dropped: false);
    if (anime.seasons.isEmpty && !anime.id.startsWith('movie-')) {
      try {
        stored =
            (await _apiClient.fetchAnime(anime.id))?.copyWith(dropped: false) ??
            stored;
      } catch (_) {
        stored = anime.copyWith(dropped: false);
      }
    }
    await _commit(mutate.withAnimeAdded(data, anime.id, stored));
  }

  Future<void> deleteAnime(String animeId) async {
    await _commit(mutate.withAnimeRemoved(data, animeId));
  }

  Future<void> toggleDropped(String animeId) async {
    final anime = data.animeList[animeId];
    if (anime == null) return;
    await _commit(mutate.withDroppedToggled(data, animeId, anime));
  }

  Future<void> setAnimeNote(String animeId, String note) async {
    if (!data.animeList.containsKey(animeId)) return;
    await _commit(mutate.withAnimeNote(data, animeId, note));
  }

  Future<void> setDroppedReason(String animeId, String reason) async {
    if (!data.animeList.containsKey(animeId)) return;
    await _commit(mutate.withDroppedReason(data, animeId, reason));
  }

  Future<void> setEpisodeWatched(
    Anime anime,
    AnimeSeason season,
    Episode episode,
    bool watched,
  ) async {
    await _commit(
      mutate.withEpisodeWatched(data, anime, season, episode, watched),
    );
  }

  Future<void> toggleMovieWatched(AnimeMovie movie) async {
    await _commit(mutate.withMovieWatchedToggled(data, movie));
  }

  // --- 찜 -------------------------------------------------------------------

  Future<void> addWish(Anime anime) async {
    if (isInLibrary(anime.id)) return;
    await _commit(mutate.withWishAdded(data, anime));
  }

  Future<void> toggleWish(Anime anime) async {
    if (isWished(anime.id)) {
      await removeWish(anime.id);
    } else {
      await addWish(anime);
    }
  }

  Future<void> removeWish(String animeId) async {
    await _commit(mutate.withWishRemoved(data, animeId));
  }

  Future<void> addWishToLibrary(WishItem item) async {
    await addAnime(
      Anime(
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
      ),
    );
  }

  // --- 설정·백업 ------------------------------------------------------------

  Future<void> updateSettings(AppSettings settings) async {
    await _commit(data.copyWith(settings: settings));
  }

  Future<void> resetAllData() async {
    await _commit(AppData.empty().copyWith(settings: settings));
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
