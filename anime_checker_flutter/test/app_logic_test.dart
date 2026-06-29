import 'dart:io';

import 'package:anime_checker_flutter/src/core/api_client.dart';
import 'package:anime_checker_flutter/src/core/app_controller.dart';
import 'package:anime_checker_flutter/src/core/date_text.dart';
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
}
