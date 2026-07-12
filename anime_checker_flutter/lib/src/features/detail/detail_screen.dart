import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/genre_text.dart';
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
    if (previewAnime != null &&
        anime.seasons.isEmpty &&
        anime.movies.isEmpty &&
        !anime.id.startsWith('movie-')) {
      return FutureBuilder<Anime>(
        future: controller.previewAnimeDetail(anime),
        builder: (context, snapshot) {
          final detailed = snapshot.data ?? anime;
          if (snapshot.connectionState != ConnectionState.done &&
              snapshot.data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('상세')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          return _buildDetail(context, controller, detailed);
        },
      );
    }
    return _buildDetail(context, controller, anime);
  }

  Widget _buildDetail(
    BuildContext context,
    AppController controller,
    Anime anime,
  ) {
    final inLibrary = controller.isInLibrary(anime.id);
    final genres = visibleGenres(anime.genres);
    final note = controller.animeNote(anime.id);
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
                    borderRadius: BorderRadius.circular(12),
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
                      if (genres.isNotEmpty) ...[
                        Text(
                          genres.join(' · '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(anime.status.isEmpty ? '상태 확인 중' : anime.status),
                      if (isAnimeCurrentlyAiring(
                            anime.firstAirDate,
                            status: anime.status,
                          ) &&
                          hasUsefulText(anime.weekday))
                        Text(anime.weekday),
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
                    child: const Text('추가'),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => controller.toggleDropped(anime.id),
                    child: Text(controller.isDropped(anime.id) ? '복귀' : '보류'),
                  ),
                  OutlinedButton(
                    onPressed: () => _editNote(context, controller, anime),
                    child: const Text('메모'),
                  ),
                  if (controller.isDropped(anime.id))
                    OutlinedButton(
                      onPressed: () =>
                          _editDroppedReason(context, controller, anime),
                      child: const Text('사유'),
                    ),
                  OutlinedButton(
                    onPressed: () => _confirmDelete(context, controller, anime),
                    child: const Text('삭제'),
                  ),
                ],
              ],
            ),
          ),
          if (inLibrary && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '메모',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(note),
                    ],
                  ),
                ),
              ),
            ),
          if (anime.seasons.isNotEmpty || inLibrary) SectionHeader(title: '시즌'),
          if (anime.seasons.isEmpty && !inLibrary)
            const SizedBox.shrink()
          else if (anime.seasons.isEmpty)
            EmptyState(
              title: '시즌 정보가 없어요',
              message: '프록시에서 상세 정보를 가져오면 시즌과 에피소드가 채워져요.',
              actionLabel: previewAnime == null ? '시즌 정보 다시 가져오기' : null,
              onAction: previewAnime == null
                  ? () => controller.refreshAnimeDetail(anime.id)
                  : null,
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: anime.seasons.map((season) {
                  final watched = controller.watchedCountForSeason(
                    anime,
                    season,
                  );
                  final total = season.episodes.length;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        season.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('$watched화 / $total화'),
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
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
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
                          onPressed: () => _toggleMovieWatched(
                            context,
                            controller,
                            anime,
                            movie,
                            watched,
                          ),
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

  Future<void> _toggleMovieWatched(
    BuildContext context,
    AppController controller,
    Anime anime,
    AnimeMovie movie,
    bool watched,
  ) async {
    if (!watched && !controller.isInLibrary(anime.id)) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('보관함에 추가할까요?'),
          content: Text('${anime.title}을 보관함에 추가하고 이 영화를 시청 완료로 표시합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      await controller.addAnime(anime);
    }
    await controller.toggleMovieWatched(movie);
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

  void _editNote(BuildContext context, AppController controller, Anime anime) {
    final textController = TextEditingController(
      text: controller.animeNote(anime.id),
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: '작품에 대한 메모를 남겨요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.setAnimeNote(anime.id, textController.text);
            },
            child: const Text('저장'),
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
