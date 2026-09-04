import 'package:anime_checker_flutter/src/data/models/models.dart';
import 'package:anime_checker_flutter/src/state/season_migration.dart';
import 'package:flutter_test/flutter_test.dart';

AnimeSeason season({
  required int number,
  required String name,
  required List<Episode> episodes,
}) => AnimeSeason(
  number: number,
  name: name,
  subtitle: '',
  posterUrl: '',
  episodes: episodes,
);

/// 원본 좌표를 달고 있는 화.
Episode ep(int number, {int srcSeason = 0, int srcEpisode = 0}) => Episode(
  number: number,
  title: '$number화',
  airDate: '',
  sourceSeason: srcSeason,
  sourceEpisode: srcEpisode,
);

void main() {
  test('뭉친 시즌을 기수별로 나눠도 본 화가 그대로 따라온다', () {
    // 옛 구성: 한 시즌에 24화가 통으로. 원본 좌표가 없던 시절 데이터.
    final before = [
      season(
        number: 1,
        name: '시즌 1',
        episodes: [for (var i = 1; i <= 24; i++) ep(i)],
      ),
    ];
    // 새 구성: 12화씩 두 기수로 나뉘고 각각 1화부터 다시 시작.
    final after = [
      season(
        number: 1,
        name: '1기',
        episodes: [for (var i = 1; i <= 12; i++) ep(i, srcSeason: 1, srcEpisode: i)],
      ),
      season(
        number: 2,
        name: '2기',
        episodes: [
          for (var i = 1; i <= 12; i++)
            ep(i, srcSeason: 1, srcEpisode: 12 + i),
        ],
      ),
    ];
    // 1~15화를 봤다면 2기 3화까지 본 셈이다.
    final watched = {for (var i = 1; i <= 15; i++) 'a:s1:e$i': true};

    final moved = migrateWatchedEpisodes(
      animeId: 'a',
      watchedEpisodes: watched,
      before: before,
      after: after,
    );

    expect(moved['a:s1:e12'], isTrue);
    expect(moved['a:s2:e1'], isTrue);
    expect(moved['a:s2:e3'], isTrue);
    expect(moved['a:s2:e4'], isNull);
    expect(moved.values.where((v) => v).length, 15);
  });

  test('옮긴 뒤 옛 키는 남지 않는다', () {
    final before = [
      season(number: 1, name: '시즌 1', episodes: [for (var i = 1; i <= 20; i++) ep(i)]),
    ];
    final after = [
      season(
        number: 1,
        name: '1기',
        episodes: [for (var i = 1; i <= 10; i++) ep(i, srcSeason: 1, srcEpisode: i)],
      ),
      season(
        number: 2,
        name: '2기',
        episodes: [
          for (var i = 1; i <= 10; i++) ep(i, srcSeason: 1, srcEpisode: 10 + i),
        ],
      ),
    ];
    final watched = {for (var i = 1; i <= 20; i++) 'a:s1:e$i': true};

    final moved = migrateWatchedEpisodes(
      animeId: 'a',
      watchedEpisodes: watched,
      before: before,
      after: after,
    );

    expect(moved['a:s1:e20'], isNull);
    expect(moved['a:s2:e10'], isTrue);
    expect(moved.values.where((v) => v).length, 20);
  });

  test('다른 작품의 기록은 건드리지 않는다', () {
    final before = [
      season(number: 1, name: '시즌 1', episodes: [for (var i = 1; i <= 4; i++) ep(i)]),
    ];
    final after = [
      season(
        number: 1,
        name: '1기',
        episodes: [for (var i = 1; i <= 2; i++) ep(i, srcSeason: 1, srcEpisode: i)],
      ),
      season(
        number: 2,
        name: '2기',
        episodes: [for (var i = 1; i <= 2; i++) ep(i, srcSeason: 1, srcEpisode: 2 + i)],
      ),
    ];
    final watched = {
      'a:s1:e1': true,
      'a:s1:e4': true,
      'other:s1:e7': true,
      'other:s2:e1': true,
    };

    final moved = migrateWatchedEpisodes(
      animeId: 'a',
      watchedEpisodes: watched,
      before: before,
      after: after,
    );

    expect(moved['other:s1:e7'], isTrue);
    expect(moved['other:s2:e1'], isTrue);
  });

  test('구성이 그대로면 기록을 손대지 않는다', () {
    final seasons = [
      season(number: 1, name: '1기', episodes: [for (var i = 1; i <= 5; i++) ep(i)]),
    ];
    final watched = {'a:s1:e2': true};

    final moved = migrateWatchedEpisodes(
      animeId: 'a',
      watchedEpisodes: watched,
      before: seasons,
      after: seasons,
    );

    expect(identical(moved, watched), isTrue);
  });

  test('이미 나뉜 작품을 다시 받아도 기록이 유지된다', () {
    // 원피스처럼 처음부터 시즌이 나뉜 경우. 원본 좌표가 시즌마다 다르다.
    final seasons = [
      season(
        number: 1,
        name: '1기',
        episodes: [for (var i = 1; i <= 3; i++) ep(i, srcSeason: 1, srcEpisode: i)],
      ),
      season(
        number: 2,
        name: '2기',
        episodes: [for (var i = 1; i <= 3; i++) ep(i, srcSeason: 2, srcEpisode: i)],
      ),
    ];
    final watched = {'a:s1:e1': true, 'a:s1:e2': true, 'a:s2:e1': true};

    final moved = migrateWatchedEpisodes(
      animeId: 'a',
      watchedEpisodes: watched,
      before: seasons,
      after: seasons,
    );

    expect(moved['a:s1:e2'], isTrue);
    expect(moved['a:s2:e1'], isTrue);
  });

  test('새 구성에 자리가 없는 기록은 잃은 수로 센다', () {
    final before = [
      season(number: 1, name: '시즌 1', episodes: [for (var i = 1; i <= 10; i++) ep(i)]),
    ];
    // 새 구성이 6화까지만 담고 있는 경우(그룹 정보가 일부만 있을 때).
    final after = [
      season(
        number: 1,
        name: '1기',
        episodes: [for (var i = 1; i <= 6; i++) ep(i, srcSeason: 1, srcEpisode: i)],
      ),
      season(
        number: 2,
        name: '2기',
        episodes: [ep(1, srcSeason: 1, srcEpisode: 7)],
      ),
    ];
    final watched = {for (var i = 1; i <= 10; i++) 'a:s1:e$i': true};

    final moved = migrateWatchedEpisodes(
      animeId: 'a',
      watchedEpisodes: watched,
      before: before,
      after: after,
    );

    expect(
      lostWatchedCount(
        animeId: 'a',
        beforeWatched: watched,
        afterWatched: moved,
      ),
      3,
    );
  });

  test('원본 좌표계가 통째로 바뀌어도 순번으로 기록을 지킨다', () {
    // TMDB가 시즌 구조를 바꾸면 옛 s2 좌표가 새 좌표계에 아예 없다(주술회전 사례).
    final before = [
      season(number: 1, name: '1기', episodes: [for (var i = 1; i <= 24; i++) ep(i)]),
      season(number: 2, name: '2기', episodes: [for (var i = 1; i <= 23; i++) ep(i)]),
    ];
    // 새 구성은 전부 s1 연속 번호를 원본으로 갖는다.
    final after = [
      season(
        number: 1,
        name: '1기',
        episodes: [for (var i = 1; i <= 24; i++) ep(i, srcSeason: 1, srcEpisode: i)],
      ),
      season(
        number: 2,
        name: '2기',
        episodes: [
          for (var i = 1; i <= 23; i++) ep(i, srcSeason: 1, srcEpisode: 24 + i),
        ],
      ),
    ];
    final watched = {
      for (var i = 1; i <= 24; i++) 'a:s1:e$i': true,
      for (var i = 1; i <= 10; i++) 'a:s2:e$i': true,
    };

    final moved = migrateWatchedEpisodes(
      animeId: 'a',
      watchedEpisodes: watched,
      before: before,
      after: after,
    );

    expect(moved.values.where((v) => v).length, 34);
    expect(moved['a:s2:e10'], isTrue);
    expect(moved['a:s2:e11'], isNull);
  });

  test('새 구성이 옛 구성보다 짧으면 순번 추정을 쓰지 않는다', () {
    final before = [
      season(number: 1, name: '1기', episodes: [for (var i = 1; i <= 10; i++) ep(i)]),
    ];
    final after = [
      season(
        number: 1,
        name: '1기',
        episodes: [for (var i = 1; i <= 4; i++) ep(i, srcSeason: 9, srcEpisode: i)],
      ),
    ];
    final watched = {for (var i = 1; i <= 10; i++) 'a:s1:e$i': true};

    final moved = migrateWatchedEpisodes(
      animeId: 'a',
      watchedEpisodes: watched,
      before: before,
      after: after,
    );

    // 좌표도 안 맞고 화수도 줄었으면 함부로 채우지 않는다.
    expect(moved.values.where((v) => v).length, 0);
  });

  test('새 구성에 없는 키를 찾아낸다', () {
    final seasons = [
      season(
        number: 1,
        name: '1기',
        episodes: [for (var i = 1; i <= 2; i++) ep(i)],
      ),
    ];

    final orphans = orphanKeys(
      animeId: 'a',
      watchedEpisodes: {'a:s1:e1': true, 'a:s9:e9': true, 'b:s1:e1': true},
      seasons: seasons,
    );

    expect(orphans, {'a:s9:e9'});
  });
}
