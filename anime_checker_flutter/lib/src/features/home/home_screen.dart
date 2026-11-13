import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_controller.dart';
import '../../core/format/date_text.dart';
import '../../data/models/models.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/scroll_top_area.dart';
import '../../widgets/section_header.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final targets = controller.todayTargets;
    return ScrollTopArea(
      builder: (scrollController) => RefreshIndicator(
        onRefresh: () async {
          await controller.load();
          await controller.syncAiringEpisodes(force: true);
        },
        child: ListView(
          controller: scrollController,
          children: [
            SectionHeader(title: '이어볼 애니', meta: nowBasisText()),
            if (targets.isEmpty)
              const EmptyState(
                title: '이어볼 작품이 없어요',
                message: '보관함에 추가한 작품 중 아직 안 본 화가 있으면 여기에 보여요.',
              )
            else
              TwoColumnAnimeGrid(
                children: targets.map((target) {
                  return AnimePosterCard.fromAnime(
                    anime: target.anime,
                    showImage: controller.settings.showPosterImages,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(animeId: target.anime.id),
                      ),
                    ),
                    metaLines: [
                      '이어볼 화: ${target.season.name} '
                          '${episodeLabel(target.episode)}',
                      '방영일: ${formatStoredDate(target.episode.airDate)}',
                    ],
                    onLongPress: () =>
                        _showAnimeMenu(context, controller, target),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAnimeMenu(
    BuildContext context,
    AppController controller,
    EpisodeTarget target,
  ) {
    final animeId = target.anime.id;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text('${episodeLabel(target.episode)} 시청 완료'),
              onTap: () {
                Navigator.pop(context);
                controller.setEpisodeWatched(
                  target.anime,
                  target.season,
                  target.episode,
                  true,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(controller.isDropped(animeId) ? '복귀' : '보류'),
              onTap: () {
                Navigator.pop(context);
                controller.toggleDropped(animeId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, controller, target.anime);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 보관함·상세와 같은 확인을 거쳐야 시청 기록이 지워진다.
  void _confirmDelete(
    BuildContext context,
    AppController controller,
    Anime anime,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: Text('${anime.title} 기록을 삭제합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteAnime(anime.id);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
