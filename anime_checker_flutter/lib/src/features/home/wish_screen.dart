import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/models.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/scroll_top_area.dart';
import '../detail/detail_screen.dart';

class WishScreen extends ConsumerWidget {
  const WishScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final items = controller.wishItems;
    return ScrollTopArea(
      builder: (scrollController) => ListView(
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '총 ${items.length}개',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          if (items.isEmpty)
            const EmptyState(
              title: '찜한 작품이 없어요',
              message: '신작 애니나 검색 결과에서 관심 작품을 담아둘 수 있어요.',
            )
          else
            TwoColumnAnimeGrid(
              children: items.map((item) {
                return AnimePosterCard(
                  title: item.title,
                  posterUrl: item.posterUrl,
                  genres: item.genres,
                  metaLines: animeBroadcastMetaLines(
                    item.firstAirDate,
                    isMovie: item.isMovie,
                  ),
                  showImage: controller.settings.showPosterImages,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DetailScreen.preview(anime: _animeFromWish(item)),
                    ),
                  ),
                  actions: [
                    AnimeCardAction(
                      label: '추가',
                      filled: true,
                      onPressed: () => controller.addWishToLibrary(item),
                    ),
                    AnimeCardAction(
                      label: '삭제',
                      onPressed: () => controller.removeWish(item.id),
                    ),
                  ],
                  onLongPress: () => _showMenu(context, controller, item),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Anime _animeFromWish(WishItem item) {
    return Anime(
      id: item.id,
      title: item.title,
      originalTitle: '',
      posterUrl: item.posterUrl,
      genres: item.genres,
      status: '정보 확인 중',
      weekday: '',
      firstAirDate: item.firstAirDate,
      seasons: const [],
      movies: const [],
      dropped: false,
      isMovie: item.isMovie,
    );
  }

  void _showMenu(BuildContext context, AppController controller, item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('추가'),
              onTap: () {
                Navigator.pop(context);
                controller.addWishToLibrary(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              onTap: () {
                Navigator.pop(context);
                controller.removeWish(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
