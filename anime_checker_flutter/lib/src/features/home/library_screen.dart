import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/genre_text.dart';
import '../../core/models.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../detail/detail_screen.dart';

enum LibraryMode { library, dropped }

enum LibrarySort {
  title,
  recentAirDate,
  lowProgress,
  highProgress,
  completedFirst,
}

extension LibrarySortText on LibrarySort {
  String get label {
    switch (this) {
      case LibrarySort.title:
        return '제목순';
      case LibrarySort.recentAirDate:
        return '최근 방영일순';
      case LibrarySort.lowProgress:
        return '진행 낮은순';
      case LibrarySort.highProgress:
        return '진행 높은순';
      case LibrarySort.completedFirst:
        return '완료 먼저';
    }
  }

  String get key {
    switch (this) {
      case LibrarySort.title:
        return 'title';
      case LibrarySort.recentAirDate:
        return 'recentAirDate';
      case LibrarySort.lowProgress:
        return 'lowProgress';
      case LibrarySort.highProgress:
        return 'highProgress';
      case LibrarySort.completedFirst:
        return 'completedFirst';
    }
  }

  static LibrarySort fromKey(String key) {
    for (final value in LibrarySort.values) {
      if (value.key == key) return value;
    }
    return LibrarySort.title;
  }
}

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, required this.mode});

  final LibraryMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final sort = LibrarySortText.fromKey(controller.settings.librarySort);
    final items = mode == LibraryMode.library
        ? controller.libraryAnime
        : controller.droppedAnime;
    final sorted = _sorted(items, controller);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '총 ${items.length}개',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LibrarySort.values.map((value) {
              return ChoiceChip(
                label: Text(value.label),
                selected: sort == value,
                onSelected: (_) => controller.updateSettings(
                  controller.settings.copyWith(librarySort: value.key),
                ),
              );
            }).toList(),
          ),
        ),
        if (items.isEmpty)
          EmptyState(
            title: mode == LibraryMode.library ? '보관함이 비어 있어요' : '보류한 작품이 없어요',
            message: mode == LibraryMode.library
                ? '검색이나 신작 애니에서 작품을 추가해 보세요.'
                : '잠깐 멈춘 작품은 여기에서 따로 관리돼요.',
          )
        else
          TwoColumnAnimeGrid(
            compact: !controller.settings.showPosterImages,
            children: sorted.map((anime) {
              final reason = controller.droppedReason(anime.id);
              final metaLines = [
                if (mode == LibraryMode.library &&
                    isAnimeCurrentlyAiring(
                      anime.firstAirDate,
                      status: anime.status,
                    ) &&
                    hasUsefulText(anime.weekday))
                  anime.weekday,
                if (mode == LibraryMode.dropped && reason.isNotEmpty) reason,
                controller.progressLabel(anime),
                controller.latestWatchLabel(anime),
              ];
              return AnimePosterCard.fromAnime(
                anime: anime,
                showImage: controller.settings.showPosterImages,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(animeId: anime.id),
                  ),
                ),
                metaLines: metaLines,
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

  List<Anime> _sorted(List<Anime> items, AppController controller) {
    final sorted = [...items];
    final sort = LibrarySortText.fromKey(controller.settings.librarySort);
    switch (sort) {
      case LibrarySort.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case LibrarySort.recentAirDate:
        sorted.sort((a, b) => _latestAirDate(b).compareTo(_latestAirDate(a)));
      case LibrarySort.lowProgress:
        sorted.sort(
          (a, b) => controller
              .progressRatio(a)
              .compareTo(controller.progressRatio(b)),
        );
      case LibrarySort.highProgress:
        sorted.sort(
          (a, b) => controller
              .progressRatio(b)
              .compareTo(controller.progressRatio(a)),
        );
      case LibrarySort.completedFirst:
        sorted.sort((a, b) {
          final aDone = controller.progressRatio(a) >= 1;
          final bDone = controller.progressRatio(b) >= 1;
          if (aDone != bDone) return aDone ? -1 : 1;
          return a.title.compareTo(b.title);
        });
    }
    return sorted;
  }

  DateTime _latestAirDate(Anime anime) {
    DateTime latest = DateTime(0);
    for (final season in anime.seasons) {
      for (final episode in season.episodes) {
        final date = parseDate(episode.airDate);
        if (date != null && date.isAfter(latest)) latest = date;
      }
    }
    final firstAirDate = parseDate(anime.firstAirDate);
    if (firstAirDate != null && firstAirDate.isAfter(latest)) {
      latest = firstAirDate;
    }
    return latest;
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
            if (controller.isDropped(anime.id))
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: const Text('보류 사유'),
                subtitle: Text(
                  controller.droppedReason(anime.id).isEmpty
                      ? '사유 없음'
                      : controller.droppedReason(anime.id),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editDroppedReason(context, controller, anime);
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

  void _editDroppedReason(
    BuildContext context,
    AppController controller,
    Anime anime,
  ) {
    final textController = TextEditingController(
      text: controller.droppedReason(anime.id),
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보류 사유'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 나중에, 자막 대기'),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.setDroppedReason(anime.id, textController.text);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
