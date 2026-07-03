import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/models.dart';
import '../../widgets/empty_state.dart';
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
    return ListView(
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
            message: '현재 방영 중이고 요일 정보가 있는 작품만 여기에 표시돼요.',
            icon: Icons.calendar_month_outlined,
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: _weekdayOrder.where(schedule.containsKey).map((day) {
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
            ],
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index += 1) ...[
                  _ScheduleRow(
                    anime: items[index],
                    isDropped: controller.isDropped(items[index].id),
                    hasNewEpisode: newEpisodeIds.contains(items[index].id),
                  ),
                  if (index != items.length - 1)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.anime,
    required this.isDropped,
    required this.hasNewEpisode,
  });

  final Anime anime;
  final bool isDropped;
  final bool hasNewEpisode;

  @override
  Widget build(BuildContext context) {
    final label = isDropped ? '보류' : (hasNewEpisode ? '새 화' : '보관함');
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Text(
        anime.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        anime.status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: hasNewEpisode ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: hasNewEpisode ? colors.onPrimaryContainer : colors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(animeId: anime.id)),
      ),
    );
  }
}
