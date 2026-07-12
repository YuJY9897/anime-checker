import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/models.dart';

class EpisodeScreen extends ConsumerWidget {
  const EpisodeScreen({super.key, required this.anime, required this.season});

  final Anime anime;
  final AnimeSeason season;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(season.name)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemBuilder: (context, index) {
          final episode = season.episodes[index];
          final watched = controller.isEpisodeWatched(
            anime.id,
            season.number,
            episode.number,
          );
          final episodeTitle = episode.title.trim();
          final episodeLabel =
              episodeTitle.isEmpty || episodeTitle == '${episode.number}화'
              ? '${episode.number}화'
              : '${episode.number}화 : $episodeTitle';
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episodeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '방영일: ${formatStoredDate(episode.airDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                watched
                    ? FilledButton.tonal(
                        onPressed: () =>
                            _setWatched(context, controller, episode, false),
                        child: const Text('완료'),
                      )
                    : OutlinedButton(
                        onPressed: () =>
                            _setWatched(context, controller, episode, true),
                        child: const Text('시청'),
                      ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemCount: season.episodes.length,
      ),
    );
  }

  Future<void> _setWatched(
    BuildContext context,
    AppController controller,
    Episode episode,
    bool watched,
  ) async {
    if (watched && !controller.isInLibrary(anime.id)) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('보관함에 추가할까요?'),
          content: Text(
            '${anime.title}을 보관함에 추가하고 ${episode.number}화까지 시청 완료로 표시합니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      await controller.addAnime(anime);
    }
    await controller.setEpisodeWatched(anime, season, episode, watched);
  }
}
