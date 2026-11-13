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
          // 빈 상태에서는 '방영중 0개'와 아래 안내가 같은 말을 두 번 하게 된다.
          if (schedule.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '방영중 $count개',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          if (schedule.isEmpty)
            EmptyState(
              title: '이번 주 새 화가 없어요',
              // 예전 문구는 '요일을 알아내지 못했다'였는데 실제 이유와 달랐다.
              // 비는 진짜 이유는 최근 2주 안에 나온 화가 없다는 것이다.
              message: '보관함에 최근 2주 안에 새 화가 나온 작품이 없어요. '
                  '회차 정보가 오래됐으면 다시 받아 보세요.',
              icon: Icons.calendar_month_outlined,
              actionLabel: controller.refreshingAll ? null : '회차 다시 받기',
              onAction: controller.refreshingAll
                  ? null
                  : () => controller.refreshAllAnimeDetails(),
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
