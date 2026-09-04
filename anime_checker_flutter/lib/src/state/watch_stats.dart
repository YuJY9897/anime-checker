// 보관함 데이터에서 시청 통계를 계산한다. 화면에 그리기 좋은 형태로만 가공한다.
import '../core/format/genre_text.dart';
import '../data/models/models.dart';
import 'anime_query.dart' as query;

/// 화당 평균 길이(분). 시청 시간 환산에만 쓰는 어림값.
const int minutesPerEpisode = 24;

class GenreCount {
  const GenreCount(this.name, this.count);

  final String name;
  final int count;
}

class WatchStats {
  const WatchStats({
    required this.watchedEpisodes,
    required this.watchedMovies,
    required this.finishedAnime,
    required this.watchingAnime,
    required this.untouchedAnime,
    required this.droppedAnime,
    required this.wishItems,
    required this.totalEpisodes,
    required this.topGenres,
    required this.longestTitle,
    required this.longestCount,
  });

  final int watchedEpisodes;
  final int watchedMovies;
  final int finishedAnime;
  final int watchingAnime;
  final int untouchedAnime;
  final int droppedAnime;
  final int wishItems;
  final int totalEpisodes;
  final List<GenreCount> topGenres;

  /// 가장 많이 본 작품과 그 화수.
  final String longestTitle;
  final int longestCount;

  int get watchedMinutes => watchedEpisodes * minutesPerEpisode;

  /// 보관함 전체 화수 대비 시청률(0~1).
  double get completionRatio =>
      totalEpisodes == 0 ? 0 : watchedEpisodes / totalEpisodes;
}

WatchStats watchStats(AppData data) {
  final library = query.libraryAnime(data);
  var finished = 0;
  var watching = 0;
  var untouched = 0;
  var totalEpisodes = 0;
  var longestTitle = '';
  var longestCount = 0;
  final genres = <String, int>{};

  for (final anime in library) {
    final total = query.totalEpisodeCount(anime);
    final watched = query.watchedCount(data, anime);
    totalEpisodes += total;

    if (total > 0 && watched >= total) {
      finished += 1;
    } else if (watched > 0) {
      watching += 1;
    } else {
      untouched += 1;
    }

    if (watched > longestCount) {
      longestCount = watched;
      longestTitle = anime.title;
    }

    // 장르는 시청한 작품만 집계해야 취향이 드러난다.
    // 화면 다른 곳과 같은 규칙(한글 이름, 모든 작품에 붙는 '애니메이션' 제외)을 쓴다.
    if (watched > 0) {
      for (final name in visibleGenres(anime.genres)) {
        genres[name] = (genres[name] ?? 0) + 1;
      }
    }
  }

  final topGenres = genres.entries.map((e) => GenreCount(e.key, e.value)).toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });

  return WatchStats(
    watchedEpisodes: data.watchedEpisodes.values.where((v) => v).length,
    watchedMovies: data.watchedMovies.values.where((v) => v).length,
    finishedAnime: finished,
    watchingAnime: watching,
    untouchedAnime: untouched,
    droppedAnime: query.droppedAnime(data).length,
    wishItems: data.wishList.length,
    totalEpisodes: totalEpisodes,
    topGenres: topGenres.take(5).toList(),
    longestTitle: longestTitle,
    longestCount: longestCount,
  );
}

/// 시청 시간을 "3일 4시간" 같은 문구로 바꾼다.
String watchTimeLabel(int minutes) {
  if (minutes <= 0) return '아직 없음';
  final days = minutes ~/ (60 * 24);
  final hours = (minutes % (60 * 24)) ~/ 60;
  final mins = minutes % 60;
  if (days > 0) return hours > 0 ? '$days일 $hours시간' : '$days일';
  if (hours > 0) return mins > 0 ? '$hours시간 $mins분' : '$hours시간';
  return '$mins분';
}
