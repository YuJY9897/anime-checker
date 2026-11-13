import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_controller.dart';
import '../../core/format/date_text.dart';
import '../../data/models/models.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/scroll_top_area.dart';
import '../detail/detail_screen.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  static const _weekdayOrder = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  /// 오늘 요일이 맨 위에 오도록 돌린다. "오늘 뭐 보지"가 스크롤 0번이 된다.
  static List<String> _orderFromToday() {
    final today = weekdayLabel(DateTime.now());
    final start = _weekdayOrder.indexOf(today);
    if (start <= 0) return _weekdayOrder;
    return [
      ..._weekdayOrder.sublist(start),
      ..._weekdayOrder.sublist(0, start),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final schedule = controller.scheduleByWeekday;
    final newEpisodeIds = controller.todayTargets
        .map((target) => target.anime.id)
        .toSet();
    final count = schedule.values.fold<int>(
      0,
      (sum, items) => sum + items.length,
    );
    return ScrollTopArea(
      builder: (scrollController) => ListView(
        controller: scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '방영중 $count개',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          if (schedule.isEmpty)
            const EmptyState(
              title: '편성표가 비어 있어요',
              message: '방영 중인 작품의 요일을 아직 알아내지 못했어요.',
              icon: Icons.calendar_month_outlined,
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: _orderFromToday().where(schedule.containsKey).map((
                  day,
                ) {
                  return _DaySection(
                    day: day,
                    items: schedule[day]!,
                    newEpisodeIds: newEpisodeIds,
                    controller: controller,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.items,
    required this.newEpisodeIds,
    required this.controller,
  });

  final String day;
  final List<Anime> items;
  final Set<String> newEpisodeIds;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final isToday = day == weekdayLabel(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                day,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}개',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '오늘',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // 다른 화면과 같은 표지 카드를 쓴다. 편성표만 글자 목록이면 따로 논다.
          TwoColumnAnimeGrid(
            listMode: !controller.settings.showPosterImages,
            horizontalPadding: 0,
            children: items.map((anime) {
              final isDropped = controller.isDropped(anime.id);
              return AnimePosterCard.fromAnime(
                anime: anime,
                showImage: controller.settings.showPosterImages,
                listMode: !controller.settings.showPosterImages,
                progress: controller.progressRatio(anime),
                metaLines: [
                  if (newEpisodeIds.contains(anime.id)) '새 화',
                  if (isDropped) '보류',
                  controller.progressLabel(anime),
                  controller.latestWatchLabel(anime),
                ],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(animeId: anime.id),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
