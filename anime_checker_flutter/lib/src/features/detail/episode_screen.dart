import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_controller.dart';
import '../../core/format/date_text.dart';
import '../../data/models/models.dart';

class EpisodeScreen extends ConsumerWidget {
  const EpisodeScreen({super.key, required this.anime, required this.season});

  final Anime anime;
  final AnimeSeason season;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    // 화면을 연 시점의 시즌을 그대로 쓰면, 뒤에서 새 화가 들어오거나 기수가
    // 재편돼도 다시 열기 전에는 반영되지 않는다. 매번 지금 데이터에서 같은
    // 번호의 시즌을 다시 찾는다. 번호로 찾으므로 시청 기록 좌표는 그대로다.
    final live = controller.data.animeList[anime.id] ?? anime;
    final season = live.seasons.firstWhere(
      (item) => item.number == this.season.number,
      orElse: () => this.season,
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              live.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              seasonDisplayName(season.number, season.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemBuilder: (context, index) {
          final episode = season.episodes[index];
          final watched = controller.isEpisodeWatched(
            anime.id,
            season.number,
            episode.number,
          );
          final label = episodeLabel(episode);
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
                        label,
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
                        onPressed: () => _setWatched(
                          context,
                          controller,
                          live,
                          season,
                          episode,
                          false,
                        ),
                        child: const Text('완료'),
                      )
                    : OutlinedButton(
                        // 아직 방영 전인 화는 시청 처리를 막는다.
                        onPressed: _isUnaired(episode)
                            ? null
                            : () => _setWatched(
                                context,
                                controller,
                                live,
                                season,
                                episode,
                                true,
                              ),
                        child: Text(_isUnaired(episode) ? '방영 전' : '시청'),
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

  /// 방영일이 오늘보다 뒤면 아직 안 나온 화.
  bool _isUnaired(Episode episode) {
    final date = parseDate(episode.airDate);
    if (date == null) return false;
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isAfter(DateTime(now.year, now.month, now.day));
  }

  Future<void> _setWatched(
    BuildContext context,
    AppController controller,
    Anime anime,
    AnimeSeason season,
    Episode episode,
    bool watched,
  ) async {
    if (!watched) {
      // 되돌리기는 이 화 하나가 아니라 뒤쪽 화까지 지우므로 먼저 확인받는다.
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('시청 기록을 지울까요?'),
          content: Text('${episode.number}화부터 이 시즌 마지막 화까지 시청 기록을 지웁니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('지우기'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      await controller.setEpisodeWatched(anime, season, episode, false);
      return;
    }
    if (!controller.isInLibrary(anime.id)) {
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
