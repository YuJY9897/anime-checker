import 'package:anime_checker_flutter/src/data/models/models.dart';
import 'package:anime_checker_flutter/src/state/watch_stats.dart';
import 'package:flutter_test/flutter_test.dart';

Anime anime({
  required String id,
  required String title,
  required int episodes,
  List<String> genres = const [],
  bool dropped = false,
}) => Anime(
  id: id,
  title: title,
  originalTitle: '',
  posterUrl: '',
  genres: genres,
  status: '방영 중',
  weekday: '',
  firstAirDate: '',
  seasons: [
    AnimeSeason(
      number: 1,
      name: '1기',
      subtitle: '',
      posterUrl: '',
      episodes: List.generate(
        episodes,
        (i) => Episode(number: i + 1, title: '${i + 1}화', airDate: ''),
      ),
    ),
  ],
  movies: const [],
  dropped: dropped,
);

Map<String, bool> watched(String animeId, int upTo) => {
  for (var i = 1; i <= upTo; i++) '$animeId:s1:e$i': true,
};

void main() {
  test('완주·시청중·시작전을 나눠 센다', () {
    final data = AppData.empty().copyWith(
      animeList: {
        'a': anime(id: 'a', title: '완주작', episodes: 12),
        'b': anime(id: 'b', title: '보는중', episodes: 12),
        'c': anime(id: 'c', title: '시작전', episodes: 12),
      },
      watchedEpisodes: {...watched('a', 12), ...watched('b', 3)},
    );

    final stats = watchStats(data);

    expect(stats.finishedAnime, 1);
    expect(stats.watchingAnime, 1);
    expect(stats.untouchedAnime, 1);
    expect(stats.watchedEpisodes, 15);
    expect(stats.totalEpisodes, 36);
  });

  test('보류한 작품은 보관함 집계에서 빠지고 따로 센다', () {
    final data = AppData.empty().copyWith(
      animeList: {
        'a': anime(id: 'a', title: '보는중', episodes: 10),
        'b': anime(id: 'b', title: '보류작', episodes: 10, dropped: true),
      },
      watchedEpisodes: watched('a', 5),
      dropped: {'b': true},
    );

    final stats = watchStats(data);

    expect(stats.droppedAnime, 1);
    // 진행률 분모는 보류작까지 포함해야 총 시청 화수와 기준이 맞는다.
    expect(stats.totalEpisodes, 20);
  });

  test('보류작의 시청 기록도 진행률에 반영된다', () {
    final data = AppData.empty().copyWith(
      animeList: {
        'a': anime(id: 'a', title: '보는중', episodes: 10),
        'b': anime(id: 'b', title: '보류작', episodes: 10, dropped: true),
      },
      watchedEpisodes: {...watched('a', 5), ...watched('b', 5)},
      dropped: {'b': true},
    );

    final stats = watchStats(data);

    expect(stats.watchedEpisodes, 10);
    expect(stats.totalEpisodes, 20);
    expect(stats.completionRatio, 0.5);
  });

  test('보류작이 가장 많이 본 작품일 수도 있다', () {
    final data = AppData.empty().copyWith(
      animeList: {
        'a': anime(id: 'a', title: '보는중', episodes: 30),
        'b': anime(id: 'b', title: '보류작', episodes: 30, dropped: true),
      },
      watchedEpisodes: {...watched('a', 4), ...watched('b', 25)},
      dropped: {'b': true},
    );

    expect(watchStats(data).longestTitle, '보류작');
  });

  test('영어 장르는 한글로 바꾸고 애니메이션 장르는 빼고 센다', () {
    final data = AppData.empty().copyWith(
      animeList: {
        'a': anime(
          id: 'a',
          title: '가',
          episodes: 5,
          genres: ['Animation', 'Action & Adventure'],
        ),
      },
      watchedEpisodes: watched('a', 2),
    );

    final stats = watchStats(data);

    expect(stats.topGenres.length, 1);
    expect(stats.topGenres.first.name, '액션/모험');
  });

  test('장르는 시청한 작품만 집계하고 많은 순으로 정렬한다', () {
    final data = AppData.empty().copyWith(
      animeList: {
        'a': anime(id: 'a', title: '가', episodes: 5, genres: ['코미디', '액션']),
        'b': anime(id: 'b', title: '나', episodes: 5, genres: ['코미디']),
        'c': anime(id: 'c', title: '다', episodes: 5, genres: ['드라마']),
      },
      watchedEpisodes: {...watched('a', 1), ...watched('b', 1)},
    );

    final stats = watchStats(data);

    expect(stats.topGenres.first.name, '코미디');
    expect(stats.topGenres.first.count, 2);
    expect(stats.topGenres.any((g) => g.name == '드라마'), isFalse);
  });

  test('가장 많이 본 작품을 찾는다', () {
    final data = AppData.empty().copyWith(
      animeList: {
        'a': anime(id: 'a', title: '조금 본 작품', episodes: 20),
        'b': anime(id: 'b', title: '많이 본 작품', episodes: 20),
      },
      watchedEpisodes: {...watched('a', 3), ...watched('b', 17)},
    );

    final stats = watchStats(data);

    expect(stats.longestTitle, '많이 본 작품');
    expect(stats.longestCount, 17);
  });

  test('시청 시간을 읽기 쉬운 문구로 바꾼다', () {
    expect(watchTimeLabel(0), '아직 없음');
    expect(watchTimeLabel(45), '45분');
    expect(watchTimeLabel(90), '1시간 30분');
    expect(watchTimeLabel(60 * 24 * 3 + 60 * 4), '3일 4시간');
  });

  test('기록이 없으면 0으로 계산된다', () {
    final stats = watchStats(AppData.empty());

    expect(stats.watchedEpisodes, 0);
    expect(stats.completionRatio, 0);
    expect(stats.topGenres, isEmpty);
  });
}
