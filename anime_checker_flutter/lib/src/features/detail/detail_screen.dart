import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/models.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import 'episode_screen.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.animeId}) : previewAnime = null;

  const DetailScreen.preview({super.key, required Anime anime})
    : animeId = null,
      previewAnime = anime;

  final String? animeId;
  final Anime? previewAnime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final anime = previewAnime ?? controller.data.animeList[animeId];
    if (anime == null) {
      return const Scaffold(
        body: EmptyState(
          title: '작품을 찾지 못했어요',
          message: '삭제되었거나 아직 저장되지 않은 작품입니다.',
        ),
      );
    }
    final inLibrary = controller.isInLibrary(anime.id);
    return Scaffold(
      appBar: AppBar(title: const Text('상세')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (anime.posterUrl.trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      anime.posterUrl,
                      width: 118,
                      height: 177,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                if (anime.posterUrl.trim().isNotEmpty)
                  const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        anime.genres.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(anime.status.isEmpty ? '상태 확인 중' : anime.status),
                      Text(
                        anime.weekday.isEmpty ? '편성 요일 확인 중' : anime.weekday,
                      ),
                      Text('첫 방영: ${formatStoredDate(anime.firstAirDate)}'),
                      const SizedBox(height: 8),
                      if (inLibrary) ...[
                        Text(
                          controller.progressLabel(anime),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(controller.latestWatchLabel(anime)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!inLibrary)
                  FilledButton(
                    onPressed: () => controller.addAnime(anime),
                    child: const Text('보관함 추가'),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => controller.toggleDropped(anime.id),
                    child: Text(controller.isDropped(anime.id) ? '복귀' : '보류'),
                  ),
                  OutlinedButton(
                    onPressed: () => _confirmDelete(context, controller, anime),
                    child: const Text('삭제'),
                  ),
                ],
              ],
            ),
          ),
          SectionHeader(title: '시즌'),
          if (anime.seasons.isEmpty)
            const EmptyState(
              title: '시즌 정보가 없어요',
              message: '프록시에서 상세 정보를 가져오면 시즌과 에피소드가 채워져요.',
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: anime.seasons.map((season) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        season.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('${season.episodes.length}화'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EpisodeScreen(anime: anime, season: season),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (anime.movies.isNotEmpty) ...[
            SectionHeader(title: '극장판/영화'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: anime.movies.map((movie) {
                  final watched = controller.isMovieWatched(movie.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '개봉일: ${formatStoredDate(movie.releaseDate)} · ${movie.runtime}분',
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => controller.toggleMovieWatched(movie),
                          child: Text(watched ? '완료' : '시청'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
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
        content: Text('${anime.title} 기록을 삭제합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
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
