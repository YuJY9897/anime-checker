import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/models.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../detail/detail_screen.dart';

class NewAnimeScreen extends ConsumerStatefulWidget {
  const NewAnimeScreen({super.key});

  @override
  ConsumerState<NewAnimeScreen> createState() => _NewAnimeScreenState();
}

class _NewAnimeScreenState extends ConsumerState<NewAnimeScreen> {
  int? selectedYear;
  int? selectedMonth;
  bool initializedFromSettings = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final settings = controller.settings;
    final items = controller.newAnime;
    final years = _years(items);
    if (!initializedFromSettings) {
      final now = DateTime.now();
      selectedYear = now.year;
      selectedMonth = now.month;
      initializedFromSettings = true;
    }
    if (!years.contains(selectedYear)) selectedYear = years.firstOrNull;
    final months = _monthsForYear(items, selectedYear);
    if (selectedMonth != null && !months.contains(selectedMonth)) {
      selectedMonth = null;
    }
    final filtered = items.where((anime) {
      final date = parseDate(anime.firstAirDate);
      if (date == null) return false;
      if (selectedYear != null && date.year != selectedYear) return false;
      if (selectedMonth != null && date.month != selectedMonth) return false;
      return true;
    }).toList();
    return RefreshIndicator(
      onRefresh: () => controller.refreshNewAnime(),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.newAnimeBasis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: controller.refreshNewAnime,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          if (years.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(
                        labelText: '년도',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: years
                          .map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text('$year년'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        selectedYear = value;
                        selectedMonth = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: selectedMonth,
                      decoration: const InputDecoration(
                        labelText: '월',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('전체'),
                        ),
                        ...months.map(
                          (month) => DropdownMenuItem<int?>(
                            value: month,
                            child: Text('$month월'),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        selectedMonth = value;
                      }),
                    ),
                  ),
                ],
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
              compact: !settings.showPosterImages,
              children: filtered.map((anime) {
                final inLibrary = controller.isInLibrary(anime.id);
                final wished = controller.isWished(anime.id);
                return AnimePosterCard.fromAnime(
                  anime: anime,
                  showImage: settings.showPosterImages,
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

  List<int> _years(List<Anime> items) {
    final now = DateTime.now();
    final years = {
      now.year,
      ...items.map((anime) => parseDate(anime.firstAirDate)?.year).nonNulls,
    }.toList()..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<int> _monthsForYear(List<Anime> items, int? year) {
    if (year == null) return const [];
    final now = DateTime.now();
    final monthLimit = year == now.year ? now.month : 12;
    final months = {
      for (var month = 1; month <= monthLimit; month += 1) month,
      ...items
          .map((anime) => parseDate(anime.firstAirDate))
          .where((date) => date?.year == year)
          .map((date) => date!.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    return months;
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
