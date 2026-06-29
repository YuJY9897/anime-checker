import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/models.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../detail/detail_screen.dart';

class NewAnimeScreen extends ConsumerStatefulWidget {
  const NewAnimeScreen({super.key});

  @override
  ConsumerState<NewAnimeScreen> createState() => _NewAnimeScreenState();
}

class _NewAnimeScreenState extends ConsumerState<NewAnimeScreen> {
  String selectedMonth = '전체';

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final items = controller.newAnime;
    final months = _months(items);
    if (selectedMonth != '전체' && !months.contains(selectedMonth)) {
      selectedMonth = '전체';
    }
    final filtered = selectedMonth == '전체'
        ? items
        : items
              .where((anime) => _monthKey(anime.firstAirDate) == selectedMonth)
              .toList();
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
          if (months.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['전체', ...months].map((month) {
                  return ChoiceChip(
                    label: Text(month),
                    selected: selectedMonth == month,
                    onSelected: (_) => setState(() => selectedMonth = month),
                  );
                }).toList(),
              ),
            ),
          if (items.isEmpty)
            const EmptyState(
              title: '신작 정보를 가져오지 못했어요',
              message: '인터넷 연결이나 프록시 설정을 확인해 주세요.',
            )
          else if (filtered.isEmpty)
            const EmptyState(
              title: '해당 월의 작품이 없어요',
              message: '다른 월을 선택하거나 새로고침해 주세요.',
            )
          else
            TwoColumnAnimeGrid(
              children: filtered.map((anime) {
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

  List<String> _months(List<Anime> items) {
    final months =
        items
            .map((anime) => _monthKey(anime.firstAirDate))
            .where((month) => month.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return months;
  }

  String _monthKey(String value) {
    final date = parseDate(value);
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}';
  }

  void _showMenu(BuildContext context, AppController controller, Anime anime) {
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
