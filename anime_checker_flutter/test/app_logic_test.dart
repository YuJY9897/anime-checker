import 'dart:io';

import 'package:anime_checker_flutter/src/data/remote/api_client.dart';
import 'package:anime_checker_flutter/src/state/app_controller.dart';
import 'package:anime_checker_flutter/src/core/format/date_text.dart';
import 'package:anime_checker_flutter/src/core/format/genre_text.dart';
import 'package:anime_checker_flutter/src/data/local/local_repository.dart';
import 'package:anime_checker_flutter/src/data/models/models.dart';
import 'package:anime_checker_flutter/src/data/sample/sample_data.dart';
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

class SyncApiClient extends AnimeApiClient {
  SyncApiClient(this.detail);

  final Anime detail;
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<Anime?> fetchAnime(String id) async {
    calls += 1;
    return detail;
  }

  @override
  Future<List<Anime>> search(String query) async => const [];

  @override
  Future<List<Anime>> fetchNewAnime() async => const [];

  @override
  Future<List<NewsArticle>> fetchNews() async => const [];
}

/// 갱신이 느린 서버를 흉내 낸다. 갱신 도중에 보관함을 바꿔 보려고 쓴다.
class SlowSyncApiClient extends SyncApiClient {
  SlowSyncApiClient(super.detail);

  @override
  Future<Anime?> fetchAnime(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return super.fetchAnime(id);
  }
}

Anime airingAnime(List<Episode> episodes, {String id = '100'}) => Anime(
  id: id,
  title: '테스트 애니',
  originalTitle: '',
  posterUrl: '',
  genres: const [],
  status: '방영 중',
  weekday: '수요일',
  firstAirDate: '2026-01-07',
  seasons: [
    AnimeSeason(
      number: 1,
      name: '1기',
      subtitle: '',
      posterUrl: '',
      episodes: episodes,
    ),
  ],
  movies: const [],
  dropped: false,
);

void main() {
  test('airing anime picks up newly released episodes and titles', () async {
    final stored = airingAnime(const [
      Episode(number: 1, title: '출항', airDate: '2026-01-07'),
      Episode(number: 2, title: '2화', airDate: '2026-01-14'),
    ]);
    final fetched = airingAnime(const [
      Episode(number: 1, title: '출항', airDate: '2026-01-07'),
      Episode(number: 2, title: '에피소드 2', airDate: '2026-01-14'),
      Episode(number: 3, title: '새로 나온 화', airDate: '2026-01-21'),
    ]);
    final repo = FakeRepository()
      ..saved = AppData.empty().copyWith(
        animeList: {stored.id: stored},
        watchedEpisodes: {'100:s1:e1': true},
      );
    final api = SyncApiClient(fetched);
    final controller = AppController(repo, api);

    await controller.load();
    await controller.pendingEpisodeSync;

    final season = controller.data.animeList['100']!.seasons.first;
    expect(api.calls, 1);
    expect(season.episodes.length, 3);
    expect(season.episodes[2].title, '새로 나온 화');
    // 아직 제목이 안 나온 화는 기존 표기를 유지한다.
    expect(season.episodes[1].title, '2화');
    expect(controller.isEpisodeWatched('100', 1, 1), isTrue);
    expect(repo.saved.animeSyncedAt['100'], isNotNull);
  });

  test('anime added while syncing is not wiped by the sync commit', () async {
    final stored = airingAnime(const [
      Episode(number: 1, title: '출항', airDate: '2026-01-07'),
    ]);
    final repo = FakeRepository()
      ..saved = AppData.empty().copyWith(animeList: {stored.id: stored});
    final controller = AppController(repo, SlowSyncApiClient(stored));

    await controller.load();
    // 회차 갱신이 도는 중에 보관함에 작품을 추가한다.
    await controller.addAnime(airingAnime(const [], id: '200'));
    await controller.pendingEpisodeSync;

    expect(controller.data.animeList.containsKey('200'), isTrue);
    expect(repo.saved.animeList.containsKey('200'), isTrue);
  });

  test('episode checked while syncing is not wiped by the sync commit', () async {
    final stored = airingAnime(const [
      Episode(number: 1, title: '출항', airDate: '2026-01-07'),
    ]);
    final repo = FakeRepository()
      ..saved = AppData.empty().copyWith(animeList: {stored.id: stored});
    final controller = AppController(repo, SlowSyncApiClient(stored));

    await controller.load();
    // 회차 갱신이 도는 중에 다른 작품의 화를 시청 완료로 체크한다.
    final other = airingAnime(const [
      Episode(number: 1, title: '출항', airDate: '2026-01-07'),
    ], id: '200');
    await controller.addAnime(other);
    await controller.setEpisodeWatched(
      other,
      other.seasons.first,
      other.seasons.first.episodes.first,
      true,
    );
    await controller.pendingEpisodeSync;

    expect(controller.isEpisodeWatched('200', 1, 1), isTrue);
    expect(repo.saved.watchedEpisodes['200:s1:e1'], isTrue);
  });

  test('recently synced anime is not fetched again', () async {
    final stored = airingAnime(const [
      Episode(number: 1, title: '출항', airDate: '2026-01-07'),
    ]);
    final repo = FakeRepository()
      ..saved = AppData.empty().copyWith(
        animeList: {stored.id: stored},
        animeSyncedAt: {'100': DateTime.now().toIso8601String()},
      );
    final api = SyncApiClient(stored);
    final controller = AppController(repo, api);

    await controller.load();
    await controller.pendingEpisodeSync;

    expect(api.calls, 0);
  });

  test('episode label hides auto generated titles', () {
    expect(
      episodeLabel(const Episode(number: 12, title: '에피소드 12', airDate: '')),
      '12화',
    );
    expect(
      episodeLabel(const Episode(number: 12, title: 'Episode 12', airDate: '')),
      '12화',
    );
    expect(
      episodeLabel(const Episode(number: 12, title: '결전', airDate: '')),
      '12화 : 결전',
    );
  });

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
    expect(data.settings.showNewsImages, isTrue);
    // 기본값을 다크로 바꿨다. 앱 화면이 어두운 바탕을 전제로 짜여 있어서,
    // 설정이 없는 상태로 시작하면 밝은 테마가 나와 의도한 모습이 아니었다.
    expect(data.settings.darkMode, isTrue);
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

  test(
    'today targets include old unwatched episodes and skip future episodes',
    () async {
      final today = DateTime.now();
      final old = today.subtract(const Duration(days: 30));
      final future = today.add(const Duration(days: 7));
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
        status: 'Ended',
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
              Episode(number: 2, title: '미래 화', airDate: iso(future)),
            ],
          ),
        ],
        movies: const [],
        dropped: false,
      );
      final repo = FakeRepository()
        ..saved = AppData.empty().copyWith(animeList: {'window': anime});
      final controller = AppController(repo, FakeApiClient());
      await controller.load();

      expect(controller.todayTargets.single.episode.number, 1);
    },
  );

  test(
    'schedule shows only currently airing anime regardless of settings',
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
          settings: AppSettings.defaults().copyWith(
            includeDroppedInSchedule: false,
            inferScheduleWeekday: false,
          ),
        );
      final controller = AppController(repo, FakeApiClient());
      await controller.load();

      final tuesday = controller.scheduleByWeekday['화요일'] ?? const [];

      expect(tuesday.map((anime) => anime.id), contains('airing'));
      expect(tuesday.map((anime) => anime.id), isNot(contains('ended')));
    },
  );

  test('마지막 화가 오래된 작품은 편성표에 넣지 않는다', () async {
    // TMDB가 완결작도 'Returning Series'로 두는 탓에 상태만 보면
    // 다 끝난 작품이 요일 편성표에 영영 남는다.
    final finished = Anime(
      id: 'finished',
      title: '완결됐지만 상태가 안 바뀐 작품',
      originalTitle: '',
      posterUrl: '',
      genres: const ['드라마'],
      status: 'Returning Series',
      weekday: '금요일',
      firstAirDate: '2023-09-29',
      seasons: const [
        AnimeSeason(
          number: 1,
          name: '1기',
          subtitle: '',
          posterUrl: '',
          episodes: [Episode(number: 1, title: '1화', airDate: '2024-03-22')],
        ),
      ],
      movies: const [],
      dropped: false,
    );
    final repo = FakeRepository()
      ..saved = AppData.empty().copyWith(animeList: {'finished': finished});
    final controller = AppController(repo, FakeApiClient());
    await controller.load();

    final friday = controller.scheduleByWeekday['금요일'] ?? const [];
    expect(friday.map((anime) => anime.id), isNot(contains('finished')));
  });

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

  test('new anime air date and status are displayed on separate lines', () {
    expect(formatNewAnimeAirDate('2026-07-10'), '방영일: 2026.07.10.');
    expect(
      animeAiringStatusLabel('2026-07-10', now: DateTime(2026, 6, 29)),
      '방영예정',
    );
    expect(animeAiringStatusLabel('2026-06-10', status: 'Ended'), '완결');
    expect(
      animeAiringStatusLabel('2026-06-10', status: 'Returning Series'),
      '방영중',
    );
    // 검색 응답에는 status가 없다. 날짜가 과거라는 이유만으로 방영중이라고
    // 하면 2004년 완결작까지 방영중으로 보인다.
    expect(animeAiringStatusLabel('2004-10-03'), '정보 확인 중');
    expect(isAnimeCurrentlyAiring('2004-10-03'), isFalse);
    expect(
      isAnimeCurrentlyAiring('2026-06-10', status: 'Returning Series'),
      isTrue,
    );
    expect(isAnimeCurrentlyAiring('2026-06-10', status: 'Ended'), isFalse);
    expect(
      isAnimeCurrentlyAiring('2026-07-10', now: DateTime(2026, 6, 29)),
      isFalse,
    );
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
