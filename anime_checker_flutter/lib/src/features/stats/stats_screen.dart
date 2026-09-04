import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_controller.dart';
import '../../state/watch_stats.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/scroll_top_area.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final stats = watchStats(controller.data);

    if (stats.watchedEpisodes == 0 && stats.wishItems == 0) {
      return const EmptyState(
        title: '아직 볼 기록이 없어요',
        message: '보관함에 작품을 추가하고 시청한 화를 체크하면 여기에 모아 보여줘요.',
        icon: Icons.insights_outlined,
      );
    }

    return ScrollTopArea(
      builder: (scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HeadlineCard(stats: stats),
          const SizedBox(height: 12),
          _CountGrid(stats: stats),
          const SizedBox(height: 12),
          if (stats.topGenres.isNotEmpty) ...[
            _GenreCard(stats: stats),
            const SizedBox(height: 12),
          ],
          if (stats.longestCount > 0) _MostWatchedCard(stats: stats),
        ],
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.stats});

  final WatchStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percent = (stats.completionRatio * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '지금까지 본 화',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${stats.watchedEpisodes}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text('화', style: Theme.of(context).textTheme.titleMedium),
                if (stats.watchedMovies > 0) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '+ 극장판 ${stats.watchedMovies}편',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '시간으로 치면 ${watchTimeLabel(stats.watchedMinutes)}쯤 봤어요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stats.completionRatio,
                minHeight: 10,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '보관함 전체 ${stats.totalEpisodes}화 중 $percent% 시청',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({required this.stats});

  final WatchStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = <_CountTile>[
      _CountTile(
        label: '완주',
        value: stats.finishedAnime,
        icon: Icons.verified_outlined,
      ),
      _CountTile(
        label: '보는 중',
        value: stats.watchingAnime,
        icon: Icons.play_circle_outline,
      ),
      _CountTile(
        label: '시작 전',
        value: stats.untouchedAnime,
        icon: Icons.hourglass_empty,
      ),
      _CountTile(
        label: '보류',
        value: stats.droppedAnime,
        icon: Icons.pause_circle_outline,
      ),
      _CountTile(
        label: '찜',
        value: stats.wishItems,
        icon: Icons.star_border_rounded,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // 좁은 화면에서도 두 칸이 유지되도록 폭을 나눠 쓴다.
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tiles
              .map((tile) => SizedBox(width: width, child: tile))
              .toList(),
        );
      },
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.stats});

  final WatchStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final top = stats.topGenres.first.count;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '많이 본 장르',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final genre in stats.topGenres) ...[
              Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      genre.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: top == 0 ? 0 : genre.count / top,
                        minHeight: 8,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${genre.count}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _MostWatchedCard extends StatelessWidget {
  const _MostWatchedCard({required this.stats});

  final WatchStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '가장 많이 본 작품',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.longestTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stats.longestCount}화 시청',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
