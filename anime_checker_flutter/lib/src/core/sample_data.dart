import 'models.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
String _iso(DateTime value) =>
    _dateOnly(value).toIso8601String().split('T').first;

List<Episode> _episodes(DateTime start, int count) {
  return List.generate(
    count,
    (index) => Episode(
      number: index + 1,
      title: '${index + 1}화',
      airDate: _iso(start.add(Duration(days: index * 7))),
    ),
  );
}

List<Anime> sampleAnimeList() {
  final today = _dateOnly(DateTime.now());
  return [
    Anime(
      id: 'sample-1',
      title: '던전밥',
      originalTitle: 'Dungeon Meshi',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/caU0EaqHlpWVK7NYwjv4FBmzfcB.jpg',
      genres: const ['판타지', '모험'],
      status: '방영 중',
      weekday: '목요일',
      firstAirDate: _iso(today.subtract(const Duration(days: 120))),
      seasons: [
        AnimeSeason(
          number: 1,
          name: '1기',
          subtitle: '',
          posterUrl: '',
          episodes: _episodes(today.subtract(const Duration(days: 70)), 12),
        ),
      ],
      movies: const [],
      dropped: false,
    ),
    Anime(
      id: 'sample-2',
      title: '괴수 8호',
      originalTitle: 'Kaiju No. 8',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/wBsGdFsrD9CL8xRphidx60EmgBE.jpg',
      genres: const ['액션', 'SF'],
      status: '방영 중',
      weekday: '토요일',
      firstAirDate: _iso(today.subtract(const Duration(days: 60))),
      seasons: [
        AnimeSeason(
          number: 1,
          name: '1기',
          subtitle: '',
          posterUrl: '',
          episodes: _episodes(today.subtract(const Duration(days: 49)), 10),
        ),
      ],
      movies: const [],
      dropped: false,
    ),
    Anime(
      id: 'sample-3',
      title: '장송의 프리렌',
      originalTitle: 'Frieren',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/mnj30hYDVAbL9BOA0f4HrKubAGF.jpg',
      genres: const ['판타지', '드라마'],
      status: '시즌 종료',
      weekday: '금요일',
      firstAirDate: _iso(today.subtract(const Duration(days: 260))),
      seasons: [
        AnimeSeason(
          number: 1,
          name: '1기',
          subtitle: '',
          posterUrl: '',
          episodes: _episodes(today.subtract(const Duration(days: 230)), 8),
        ),
      ],
      movies: const [
        AnimeMovie(
          id: 'frieren-movie-1',
          title: '장송의 프리렌 특별편',
          posterUrl: '',
          releaseDate: '2026-07-15',
          runtime: 90,
        ),
      ],
      dropped: false,
    ),
  ];
}

AppData sampleAppData() {
  final list = {for (final anime in sampleAnimeList()) anime.id: anime};
  return AppData.empty().copyWith(animeList: list);
}

List<Anime> sampleNewAnime() {
  final today = _dateOnly(DateTime.now());
  return [
    Anime(
      id: 'new-1',
      title: '여름의 터널, 안녕의 출구',
      originalTitle: '',
      posterUrl: '',
      genres: const ['청춘', '판타지'],
      status: '방영 예정',
      weekday: '수요일',
      firstAirDate: _iso(today.add(const Duration(days: 10))),
      seasons: const [],
      movies: const [],
      dropped: false,
    ),
    Anime(
      id: 'new-2',
      title: '약사의 혼잣말',
      originalTitle: '',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/e3GFLYIGjQEnK6AgpC8XcI1CiFm.jpg',
      genres: const ['미스터리', '드라마'],
      status: '방영 중',
      weekday: '일요일',
      firstAirDate: _iso(today.subtract(const Duration(days: 3))),
      seasons: const [],
      movies: const [],
      dropped: false,
    ),
  ];
}

List<NewsArticle> sampleNews() {
  final now = DateTime.now().toIso8601String();
  return [
    NewsArticle(
      id: 'news-1',
      title: '신작 애니 국내 OTT 공개 일정 발표',
      summary: '국내 서비스 예정작과 공개일이 순차적으로 안내됐다.',
      source: '애니 소식',
      date: now,
      imageUrl: '',
      url: 'https://example.com/anime-news-1',
    ),
    NewsArticle(
      id: 'news-2',
      title: '극장판 애니 주말 박스오피스 상위권 기록',
      summary: '관객 수와 순위가 상승하며 장기 흥행 가능성을 보였다.',
      source: '박스오피스',
      date: now,
      imageUrl: '',
      url: 'https://example.com/anime-news-2',
    ),
  ];
}
