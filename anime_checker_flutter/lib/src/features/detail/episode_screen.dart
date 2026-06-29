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
                        '${episode.number}화 : ${episode.title}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '방영일: ${formatStoredDate(episode.airDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0x99000000),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                watched
                    ? FilledButton.tonal(
                        onPressed: () => controller.setEpisodeWatched(
                          anime,
                          season,
                          episode,
                          false,
                        ),
                        child: const Text('완료'),
                      )
                    : OutlinedButton(
                        onPressed: () => controller.setEpisodeWatched(
                          anime,
                          season,
                          episode,
                          true,
                        ),
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
}
