import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';

class WishScreen extends ConsumerWidget {
  const WishScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final items = controller.wishItems;
    return ListView(
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
            compact: !controller.settings.showPosterImages,
            children: items.map((item) {
              return AnimePosterCard(
                title: item.title,
                posterUrl: item.posterUrl,
                genres: item.genres,
                metaLines: [formatNewAnimeAirDate(item.firstAirDate)],
                showImage: controller.settings.showPosterImages,
                onTap: () => controller.addWishToLibrary(item),
                actions: [
                  AnimeCardAction(
                    label: '보관함 추가',
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
              title: const Text('보관함 추가'),
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
