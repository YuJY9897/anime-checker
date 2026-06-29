import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/models.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../detail/detail_screen.dart';

enum LibraryMode { library, dropped }

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, required this.mode});

  final LibraryMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final items = mode == LibraryMode.library
        ? controller.libraryAnime
        : controller.droppedAnime;
    final title = mode == LibraryMode.library ? '보관함' : '보류';
    return ListView(
      children: [
        SectionHeader(title: title, meta: '${items.length}개'),
        if (items.isEmpty)
          EmptyState(
            title: mode == LibraryMode.library ? '보관함이 비어 있어요' : '보류한 작품이 없어요',
            message: mode == LibraryMode.library
                ? '검색이나 신작 애니에서 작품을 추가해 보세요.'
                : '잠깐 멈춘 작품은 여기에서 따로 관리돼요.',
          )
        else
          TwoColumnAnimeGrid(
            children: items.map((anime) {
              return AnimePosterCard.fromAnime(
                anime: anime,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(animeId: anime.id),
                  ),
                ),
                metaLines: [
                  anime.weekday,
                  controller.progressLabel(anime),
                  controller.latestWatchLabel(anime),
                ],
                actions: [
                  AnimeCardAction(
                    label: mode == LibraryMode.library ? '보류' : '복귀',
                    onPressed: () => controller.toggleDropped(anime.id),
                  ),
                  AnimeCardAction(
                    label: '삭제',
                    onPressed: () => _confirmDelete(context, controller, anime),
                  ),
                ],
                onLongPress: () => _showMenu(context, controller, anime),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showMenu(BuildContext context, AppController controller, Anime anime) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                controller.isDropped(anime.id)
                    ? Icons.play_circle_outline
                    : Icons.pause_circle_outline,
              ),
              title: Text(controller.isDropped(anime.id) ? '복귀' : '보류'),
              onTap: () {
                Navigator.pop(context);
                controller.toggleDropped(anime.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, controller, anime);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppController controller,
    Anime anime,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: Text('${anime.title} 기록을 보관함에서 삭제합니다.'),
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
