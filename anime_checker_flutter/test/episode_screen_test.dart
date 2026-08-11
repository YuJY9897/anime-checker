import 'package:anime_checker_flutter/src/core/models.dart';
import 'package:anime_checker_flutter/src/features/detail/episode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Anime animeWith(List<Episode> episodes) => Anime(
  id: '200',
  title: '테스트 애니',
  originalTitle: '',
  posterUrl: '',
  genres: const [],
  status: '방영 중',
  weekday: '',
  firstAirDate: '',
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

String storedDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

void main() {
  testWidgets('방영 전인 화는 시청 버튼이 비활성화된다', (tester) async {
    final now = DateTime.now();
    final anime = animeWith([
      Episode(
        number: 1,
        title: '첫 화',
        airDate: storedDate(now.subtract(const Duration(days: 7))),
      ),
      Episode(
        number: 2,
        title: '다음 화',
        airDate: storedDate(now.add(const Duration(days: 7))),
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EpisodeScreen(anime: anime, season: anime.seasons.first),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final aired = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('시청'),
        matching: find.byType(OutlinedButton),
      ),
    );
    final unaired = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('방영 전'),
        matching: find.byType(OutlinedButton),
      ),
    );

    expect(aired.onPressed, isNotNull);
    expect(unaired.onPressed, isNull);
  });
}
