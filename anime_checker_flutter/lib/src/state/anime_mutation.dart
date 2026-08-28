// 저장 데이터를 바꾼 새 AppData를 돌려주는 순수 함수 모음.
// 실제 저장과 화면 알림은 AppController가 맡는다.
import '../data/models/models.dart';
import 'anime_query.dart' as query;

AppData withAnimeAdded(AppData data, String animeId, Anime stored) {
  final list = Map<String, Anime>.from(data.animeList)..[animeId] = stored;
  final wish = Map<String, WishItem>.from(data.wishList)..remove(animeId);
  final dropped = Map<String, bool>.from(data.dropped)..remove(animeId);
  final syncedAt = Map<String, String>.from(data.animeSyncedAt)
    ..[animeId] = DateTime.now().toIso8601String();
  return data.copyWith(
    animeList: list,
    wishList: wish,
    dropped: dropped,
    animeSyncedAt: syncedAt,
  );
}

/// 작품과 함께 시청 기록·메모·중단 사유까지 모두 지운다.
AppData withAnimeRemoved(AppData data, String animeId) {
  final list = Map<String, Anime>.from(data.animeList)..remove(animeId);
  final dropped = Map<String, bool>.from(data.dropped)..remove(animeId);
  final notes = Map<String, String>.from(data.animeNotes)..remove(animeId);
  final reasons = Map<String, String>.from(data.droppedReasons)
    ..remove(animeId);
  final watched = Map<String, bool>.from(data.watchedEpisodes)
    ..removeWhere((key, value) => key.startsWith('$animeId:'));
  final syncedAt = Map<String, String>.from(data.animeSyncedAt)
    ..remove(animeId);
  return data.copyWith(
    animeList: list,
    dropped: dropped,
    animeNotes: notes,
    droppedReasons: reasons,
    watchedEpisodes: watched,
    animeSyncedAt: syncedAt,
  );
}

AppData withAnimeDetail(AppData data, String animeId, Anime next) {
  final list = Map<String, Anime>.from(data.animeList)..[animeId] = next;
  final syncedAt = Map<String, String>.from(data.animeSyncedAt)
    ..[animeId] = DateTime.now().toIso8601String();
  return data.copyWith(animeList: list, animeSyncedAt: syncedAt);
}

AppData withSyncedAnime(
  AppData data,
  Map<String, Anime> animeList,
  Map<String, String> animeSyncedAt,
) => data.copyWith(animeList: animeList, animeSyncedAt: animeSyncedAt);

/// 중단 상태를 뒤집는다. 다시 보기로 되돌리면 중단 사유도 지운다.
AppData withDroppedToggled(AppData data, String animeId, Anime anime) {
  final next = !query.isDropped(data, animeId);
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
  return data.copyWith(
    animeList: list,
    dropped: dropped,
    droppedReasons: reasons,
  );
}

AppData withAnimeNote(AppData data, String animeId, String note) {
  final notes = Map<String, String>.from(data.animeNotes);
  final value = note.trim();
  if (value.isEmpty) {
    notes.remove(animeId);
  } else {
    notes[animeId] = value;
  }
  return data.copyWith(animeNotes: notes);
}

AppData withDroppedReason(AppData data, String animeId, String reason) {
  final reasons = Map<String, String>.from(data.droppedReasons);
  final value = reason.trim();
  if (value.isEmpty) {
    reasons.remove(animeId);
  } else {
    reasons[animeId] = value;
  }
  return data.copyWith(droppedReasons: reasons);
}

/// 고른 화까지 한꺼번에 시청 처리하고, 해제하면 그 화부터 뒤를 모두 지운다.
AppData withEpisodeWatched(
  AppData data,
  Anime anime,
  AnimeSeason season,
  Episode episode,
  bool watched,
) {
  final next = Map<String, bool>.from(data.watchedEpisodes);
  for (final item in season.episodes) {
    final key = query.episodeKey(anime.id, season.number, item.number);
    if (watched && item.number <= episode.number) {
      next[key] = true;
    } else if (!watched && item.number >= episode.number) {
      next.remove(key);
    }
  }
  return data.copyWith(watchedEpisodes: next);
}

AppData withMovieWatchedToggled(AppData data, AnimeMovie movie) {
  final next = Map<String, bool>.from(data.watchedMovies);
  if (next[movie.id] == true) {
    next.remove(movie.id);
  } else {
    next[movie.id] = true;
  }
  return data.copyWith(watchedMovies: next);
}

AppData withWishAdded(AppData data, Anime anime) {
  final wish = Map<String, WishItem>.from(data.wishList)
    ..[anime.id] = WishItem.fromAnime(anime);
  return data.copyWith(wishList: wish);
}

AppData withWishRemoved(AppData data, String animeId) {
  final wish = Map<String, WishItem>.from(data.wishList)..remove(animeId);
  return data.copyWith(wishList: wish);
}
