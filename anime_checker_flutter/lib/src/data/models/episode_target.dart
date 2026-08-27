import 'anime.dart';
import 'anime_season.dart';
import 'episode.dart';

class EpisodeTarget {
  const EpisodeTarget({
    required this.anime,
    required this.season,
    required this.episode,
  });

  final Anime anime;
  final AnimeSeason season;
  final Episode episode;
}
