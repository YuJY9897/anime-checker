import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../detail/detail_screen.dart';

class NewAnimeScreen extends ConsumerWidget {
  const NewAnimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final items = controller.newAnime;
    return RefreshIndicator(
      onRefresh: () => controller.refreshNewAnime(),
      child: ListView(
        children: [
          SectionHeader(
            title: '신작 애니',
            meta: controller.newAnimeBasis,
            action: IconButton(
              onPressed: controller.refreshNewAnime,
              icon: const Icon(Icons.refresh),
            ),
          ),
          if (items.isEmpty)
            const EmptyState(
              title: '신작 정보를 가져오지 못했어요',
              message: '인터넷 연결이나 프록시 설정을 확인해 주세요.',
            )
          else
            TwoColumnAnimeGrid(
              children: items.map((anime) {
                final inLibrary = controller.isInLibrary(anime.id);
                final wished = controller.isWished(anime.id);
                return AnimePosterCard.fromAnime(
                  anime: anime,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetailScreen.preview(anime: anime),
                    ),
                  ),
                  metaLines: [
                    formatNewAnimeAirDate(anime.firstAirDate),
                    anime.status,
                  ],
                  actions: [
                    AnimeCardAction(
                      label: inLibrary ? '추가됨' : '보관함 추가',
                      filled: !inLibrary,
                      onPressed: inLibrary
                          ? null
                          : () => controller.addAnime(anime),
                    ),
                    AnimeCardAction(
                      label: wished ? '찜해제' : '찜',
                      onPressed: () => controller.toggleWish(anime),
                    ),
                  ],
                  onLongPress: () => _showMenu(context, controller, anime),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, AppController controller, anime) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(controller.isInLibrary(anime.id) ? '추가됨' : '보관함 추가'),
              onTap: controller.isInLibrary(anime.id)
                  ? null
                  : () {
                      Navigator.pop(context);
                      controller.addAnime(anime);
                    },
            ),
            ListTile(
              leading: Icon(
                controller.isWished(anime.id) ? Icons.star : Icons.star_border,
              ),
              title: Text(controller.isWished(anime.id) ? '찜해제' : '찜'),
              onTap: () {
                Navigator.pop(context);
                controller.toggleWish(anime);
              },
            ),
          ],
        ),
      ),
    );
  }
}
