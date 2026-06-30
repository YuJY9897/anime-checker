import 'dart:io';

import 'package:anime_checker_flutter/src/core/api_client.dart';
import 'package:anime_checker_flutter/src/core/app_controller.dart';
import 'package:anime_checker_flutter/src/core/date_text.dart';
import 'package:anime_checker_flutter/src/core/genre_text.dart';
import 'package:anime_checker_flutter/src/core/local_repository.dart';
import 'package:anime_checker_flutter/src/core/models.dart';
import 'package:anime_checker_flutter/src/core/sample_data.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRepository extends LocalRepository {
  AppData saved = AppData.empty();

  @override
  Future<AppData> load() async => saved;

  @override
  Future<void> save(AppData data) async {
    saved = data;
  }

  @override
  Future<File> exportBackup(AppData data) async {
    saved = data;
    return File('backup.json');
  }
}

class FakeApiClient extends AnimeApiClient {
  @override
  Future<List<Anime>> search(String query) async => const [];

  @override
  Future<List<Anime>> fetchNewAnime() async => const [];

  @override
  Future<List<NewsArticle>> fetchNews() async => const [];
}

void main() {
  test('watching one episode completes previous episodes', () async {
    final repo = FakeRepository()..saved = sampleAppData();
    final controller = AppController(repo, FakeApiClient());
    await controller.load();
    final anime = controller.allAnime.first;
    final season = anime.seasons.first;

    await controller.setEpisodeWatched(anime, season, season.episodes[2], true);

    expect(controller.isEpisodeWatched(anime.id, season.number, 1), isTrue);
    expect(controller.isEpisodeWatched(anime.id, season.number, 2), isTrue);
    expect(controller.isEpisodeWatched(anime.id, season.number, 3), isTrue);
    expect(controller.isEpisodeWatched(anime.id, season.number, 4), isFalse);
  });

  test('unwatching one episode clears following episodes', () async {
    final repo = FakeRepository()..saved = sampleAppData();
    final controller = AppController(repo, FakeApiClient());
    await controller.load();
    final anime = controller.allAnime.first;
    final season = anime.seasons.first;

    await controller.setEpisodeWatched(anime, season, season.episodes[4], true);
    await controller.setEpisodeWatched(
      anime,
      season,
      season.episodes[2],
      false,
    );

    expect(controller.isEpisodeWatched(anime.id, season.number, 1), isTrue);
    expect(controller.isEpisodeWatched(anime.id, season.number, 2), isTrue);
    expect(controller.isEpisodeWatched(anime.id, season.number, 3), isFalse);
    expect(controller.isEpisodeWatched(anime.id, season.number, 5), isFalse);
  });

  test('season watched count is calculated per season', () async {
    final repo = FakeRepository()..saved = sampleAppData();
    final controller = AppController(repo, FakeApiClient());
    await controller.load();
    final anime = controller.allAnime.first;
    final season = anime.seasons.first;

    await controller.setEpisodeWatched(anime, season, season.episodes[2], true);

    expect(controller.watchedCountForSeason(anime, season), 3);
    expect(season.episodes.length, greaterThanOrEqualTo(3));
  });

  test('adding a wished anime to library removes it from wish list', () async {
    final repo = FakeRepository();
    final controller = AppController(repo, FakeApiClient());
    final anime = sampleNewAnime().first;
    await controller.addWish(anime);
    expect(controller.isWished(anime.id), isTrue);

    await controller.addAnime(anime);

    expect(controller.isInLibrary(anime.id), isTrue);
    expect(controller.isWished(anime.id), isFalse);
  });

  test('anime notes and dropped reasons are saved in app data', () async {
    final repo = FakeRepository()..saved = sampleAppData();
    final controller = AppController(repo, FakeApiClient());
    await controller.load();
    final anime = controller.allAnime.first;

    await controller.setAnimeNote(anime.id, '2기부터 다시 보기');
    await controller.toggleDropped(anime.id);
    await controller.setDroppedReason(anime.id, '자막 대기');

    expect(controller.animeNote(anime.id), '2기부터 다시 보기');
    expect(controller.droppedReason(anime.id), '자막 대기');
    expect(repo.saved.animeNotes[anime.id], '2기부터 다시 보기');
    expect(repo.saved.droppedReasons[anime.id], '자막 대기');
  });

  test('older backups without notes still load', () {
    final data = AppData.fromJson({
      'animeList': {},
      'watchedEpisodes': {},
      'watchedMovies': {},
      'wishList': {},
      'dropped': {},
      'updatedAt': DateTime.now().toIso8601String(),
      'backupVersion': 1,
    });

    expect(data.animeNotes, isEmpty);
    expect(data.droppedReasons, isEmpty);
    expect(data.settings.showPosterImages, isTrue);
  });

  test('today targets show each anime only once', () async {
    final repo = FakeRepository()..saved = sampleAppData();
    final controller = AppController(repo, FakeApiClient());
    await controller.load();

    final targetIds = controller.todayTargets
        .map((target) => target.anime.id)
        .toList();

    expect(targetIds.toSet().length, targetIds.length);
  });

  test('today target window hides old unwatched episodes', () async {
    final today = DateTime.now();
    final old = today.subtract(const Duration(days: 30));
    final current = today.subtract(const Duration(days: 3));
    String iso(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final anime = Anime(
      id: 'window',
      title: '기간 테스트',
      originalTitle: '',
      posterUrl: '',
      genres: const ['드라마'],
      status: 'Returning Series',
      weekday: '',
      firstAirDate: iso(old),
      seasons: [
        AnimeSeason(
          number: 1,
          name: '1기',
          subtitle: '',
          posterUrl: '',
          episodes: [
            Episode(number: 1, title: '오래된 화', airDate: iso(old)),
            Episode(number: 2, title: '최근 화', airDate: iso(current)),
          ],
        ),
      ],
      movies: const [],
      dropped: false,
    );
    final repo = FakeRepository()
      ..saved = AppData.empty().copyWith(
        animeList: {'window': anime},
        watchedEpisodes: {'window:s1:e1': true},
      );
    final controller = AppController(repo, FakeApiClient());
    await controller.load();

    expect(controller.todayTargets.single.episode.number, 2);
  });

  test(
    'schedule includes airing dropped anime and excludes ended anime',
    () async {
      final airing = Anime(
        id: 'airing',
        title: '방영중 보류작',
        originalTitle: '',
        posterUrl: '',
        genres: const ['드라마'],
        status: 'Returning Series',
        weekday: '매주 화요일',
        firstAirDate: '2026-04-01',
        seasons: const [],
        movies: const [],
        dropped: false,
      );
      final ended = Anime(
        id: 'ended',
        title: '완결 작품',
        originalTitle: '',
        posterUrl: '',
        genres: const ['드라마'],
        status: '방영 종료',
        weekday: '화요일',
        firstAirDate: '2025-01-01',
        seasons: const [],
        movies: const [],
        dropped: false,
      );
      final repo = FakeRepository()
        ..saved = AppData.empty().copyWith(
          animeList: {'airing': airing, 'ended': ended},
          dropped: {'airing': true},
        );
      final controller = AppController(repo, FakeApiClient());
      await controller.load();

      final tuesday = controller.scheduleByWeekday['화요일'] ?? const [];

      expect(tuesday.map((anime) => anime.id), contains('airing'));
      expect(tuesday.map((anime) => anime.id), isNot(contains('ended')));

      await controller.updateSettings(
        controller.settings.copyWith(includeDroppedInSchedule: false),
      );

      expect(controller.scheduleByWeekday['화요일'] ?? const [], isEmpty);
    },
  );

  test(
    'search falls back to local library when api is not configured',
    () async {
      final repo = FakeRepository()..saved = sampleAppData();
      final controller = AppController(repo, FakeApiClient());
      await controller.load();

      await controller.search('던전');

      expect(
        controller.searchResults.map((anime) => anime.title),
        contains('던전밥'),
      );
    },
  );

  test('local search also matches anime id', () async {
    final repo = FakeRepository()..saved = sampleAppData();
    final controller = AppController(repo, FakeApiClient());
    await controller.load();
    final anime = controller.allAnime.first;

    await controller.search(anime.id);

    expect(controller.searchResults.map((item) => item.id), contains(anime.id));
  });

  test('future new anime date is displayed as planned release', () {
    final result = formatNewAnimeAirDate(
      '2026-07-10',
      now: DateTime(2026, 6, 29),
    );
    expect(result, '방영일: 2026.07.10. 방영예정');
  });

  test('iso news dates are displayed as stored dates', () {
    expect(formatStoredDate('2026-06-19T04:07:07.000Z'), '2026.06.19.');
  });

  test('animation genre and unknown labels are hidden from compact cards', () {
    expect(visibleGenres(['애니메이션', '드라마', 'Animation', '코미디']), ['드라마', '코미디']);
    expect(hasUsefulText('???'), isFalse);
    expect(hasUsefulText('금요일'), isTrue);
  });
}
