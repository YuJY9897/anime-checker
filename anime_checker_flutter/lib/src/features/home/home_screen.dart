import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final targets = controller.todayTargets;
    return RefreshIndicator(
      onRefresh: () async => controller.load(),
      child: ListView(
        children: [
          SectionHeader(title: '오늘 볼 애니', meta: nowBasisText()),
          if (targets.isEmpty)
            const EmptyState(
              title: '볼 새 화가 없어요',
              message: '보관함에 추가한 작품 중 아직 안 본 새 화가 있으면 여기에 보여요.',
            )
          else
            TwoColumnAnimeGrid(
              children: targets.map((target) {
                return AnimePosterCard.fromAnime(
                  anime: target.anime,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(animeId: target.anime.id),
                    ),
                  ),
                  metaLines: [
                    '${target.season.name} ${target.episode.number}화',
                    '방영일: ${formatStoredDate(target.episode.airDate)}',
                  ],
                  actions: [
                    AnimeCardAction(
                      label: '시청 완료',
                      filled: true,
                      onPressed: () => controller.setEpisodeWatched(
                        target.anime,
                        target.season,
                        target.episode,
                        true,
                      ),
                    ),
                  ],
                  onLongPress: () =>
                      _showAnimeMenu(context, controller, target.anime.id),
                );
              }).toList(),
            ),
          SectionHeader(title: '요일별 편성표'),
          _ScheduleList(controller: controller),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAnimeMenu(
    BuildContext context,
    AppController controller,
    String animeId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(controller.isDropped(animeId) ? '복귀' : '보류'),
              onTap: () {
                Navigator.pop(context);
                controller.toggleDropped(animeId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              onTap: () {
                Navigator.pop(context);
                controller.deleteAnime(animeId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final schedule = controller.scheduleByWeekday;
    if (schedule.isEmpty) {
      return const EmptyState(
        title: '편성표가 비어 있어요',
        message: '요일 정보가 있는 작품이 보관함에 추가되면 표시돼요.',
        icon: Icons.calendar_month_outlined,
      );
    }
    const order = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: order.where(schedule.containsKey).map((day) {
          final titles = schedule[day]!.map((anime) => anime.title).join(', ');
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 54,
                  child: Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: Text(
                    titles,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
