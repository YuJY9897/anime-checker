import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_controller.dart';
import '../../core/format/date_text.dart';
import '../../core/format/genre_text.dart';
import '../../data/models/models.dart';
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

  /// 표지를 흐리게 깔아 배경으로 쓰고, 그 위에 표지 한 장과 제목·상태를 얹는다.
  /// 예전에는 작은 표지와 글자가 흰 바탕에 나란히 놓인 목록의 첫 줄이었다.
  Widget _header(
    BuildContext context,
    AppController controller,
    Anime anime,
    List<String> genres,
    bool inLibrary,
  ) {
    final colors = Theme.of(context).colorScheme;
    final hasPoster = anime.posterUrl.trim().isNotEmpty;
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return SizedBox(
      height: topInset + 212,
      // BackdropFilter는 제 경계를 안 지키고 밖까지 번진다. 잘라내지 않으면
      // 머리말 아래 버튼 줄까지 표지 얼룩이 따라 내려온다.
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPoster)
              Image.network(
                anime.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            if (hasPoster)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: const ColoredBox(color: Color(0x66000000)),
              ),
            // 아래쪽은 본문 바탕색으로 녹여야 머리말과 목록이 이어져 보인다.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.surface.withValues(alpha: 0.45),
                    colors.surface.withValues(alpha: 0.82),
                    colors.surface,
                  ],
                  stops: const [0, 0.62, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topInset - 8, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasPoster) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        anime.posterUrl,
                        width: 124,
                        height: 186,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(height: 1.16),
                        ),
                        if (genres.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              genres.join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: colors.secondary),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          anime.isMovie
                              ? '극장판'
                              : controller.animeStatusLabel(anime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        // 편성표·보관함과 같은 판정을 쓴다.
                        if (!anime.isMovie &&
                            controller.isOnAirThisWeek(anime) &&
                            hasUsefulText(anime.weekday))
                          Text(
                            anime.weekday,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Text(
                          anime.isMovie
                              ? '개봉일: ${formatStoredDate(anime.firstAirDate)}'
                              : '첫 방영: ${formatStoredDate(anime.firstAirDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (inLibrary) ...[
                          const SizedBox(height: 8),
                          Text(
                            controller.progressLabel(anime),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            controller.latestWatchLabel(anime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
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

  Widget _buildDetail(
    BuildContext context,
    AppController controller,
    Anime anime,
  ) {
    final inLibrary = controller.isInLibrary(anime.id);
    final genres = visibleGenres(anime.genres);
    final note = controller.animeNote(anime.id);
    // 서버는 시즌 0에 OVA·특별편을 모아 보낸다. 본편과 섞지 않고 따로 보여준다.
    final mainSeasons = anime.seasons
        .where((season) => season.number != 0)
        .toList();
    final extraSeasons = anime.seasons
        .where((season) => season.number == 0)
        .toList();
    return Scaffold(
      // 표지를 머리말 배경으로 깔기 때문에 앱바가 그 위에 떠야 한다.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('상세'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(context, controller, anime, genres, inLibrary),
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
                  // 완결작은 자동 갱신 대상이 아니라, 서버에 외전·극장판이
                  // 새로 생겨도 저장본에는 영영 안 들어온다. 한 작품만 다시 받는다.
                  OutlinedButton(
                    onPressed: () => controller.refreshAnimeDetail(anime.id),
                    child: const Text('새로 받기'),
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
          if (mainSeasons.isNotEmpty || inLibrary) SectionHeader(title: '본편'),
          if (mainSeasons.isEmpty && !inLibrary)
            const SizedBox.shrink()
          else if (mainSeasons.isEmpty)
            EmptyState(
              title: '시즌 정보가 없어요',
              message: '프록시에서 상세 정보를 가져오면 시즌과 에피소드가 채워져요.',
              actionLabel: previewAnime == null ? '시즌 정보 다시 가져오기' : null,
              onAction: previewAnime == null
                  ? () => controller.refreshAnimeDetail(anime.id)
                  : null,
            )
          else
            _SeasonList(
              anime: anime,
              seasons: mainSeasons,
              controller: controller,
            ),
          if (extraSeasons.isNotEmpty) ...[
            SectionHeader(title: '외전'),
            _SeasonList(
              anime: anime,
              seasons: extraSeasons,
              controller: controller,
            ),
          ],
          if (anime.movies.isNotEmpty) ...[
            SectionHeader(title: '극장판'),
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
                                // TMDB 영화 검색은 상영시간을 주지 않는다. 작품마다
                                // 따로 조회하면 원피스만 20회가 더 들어 예산을 넘긴다.
                                // 모르는 값을 '0분'이라고 쓰지 않고 그냥 뺀다.
                                movie.runtime > 0
                                    ? '개봉일: ${formatStoredDate(movie.releaseDate)} · ${movie.runtime}분'
                                    : '개봉일: ${formatStoredDate(movie.releaseDate)}',
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          // 아직 개봉 전이면 시청 처리를 막는다.
                          onPressed: !watched && _isUpcoming(movie.releaseDate)
                              ? null
                              : () => _toggleMovieWatched(
                                  context,
                                  controller,
                                  anime,
                                  movie,
                                  watched,
                                ),
                          child: Text(
                            watched
                                ? '완료'
                                : (_isUpcoming(movie.releaseDate)
                                      ? '개봉 전'
                                      : '시청'),
                          ),
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

  /// 개봉일/방영일이 오늘보다 뒤면 아직 안 나온 것.
  bool _isUpcoming(String storedDate) {
    final date = parseDate(storedDate);
    if (date == null) return false;
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isAfter(DateTime(now.year, now.month, now.day));
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

/// 본편과 외전이 같은 모양으로 보이도록 시즌 목록을 한 군데서 그린다.
class _SeasonList extends StatelessWidget {
  const _SeasonList({
    required this.anime,
    required this.seasons,
    required this.controller,
  });

  final Anime anime;
  final List<AnimeSeason> seasons;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: seasons.map((season) {
          final watched = controller.watchedCountForSeason(anime, season);
          final total = season.episodes.length;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                seasonDisplayName(season.number, season.name),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('$watched화 / $total화'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EpisodeScreen(anime: anime, season: season),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
