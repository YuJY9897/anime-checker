import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_controller.dart';
import '../../core/format/date_text.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../detail/detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _searched = false;
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(hintText: '애니 제목 검색'),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: const Text('검색')),
              ],
            ),
          ),
          // 아직 한 번도 검색하지 않았으면 '0개 / 결과가 없어요'를 띄우지 않는다.
          // 처음 들어온 사람에게 실패 화면처럼 보인다.
          if (!_searched)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                controller.apiConfigured
                    ? '보고 싶은 애니 제목을 넣어 보세요.'
                    : 'API 주소가 연결되지 않아 지금은 보관함 안에서만 검색돼요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            SectionHeader(
              title: '검색 결과',
              meta: controller.apiConfigured
                  ? '${controller.searchResults.length}개'
                  : '${controller.searchResults.length}개 · 보관함 검색',
            ),
            if (controller.searchResults.isEmpty)
              EmptyState(
                title: controller.searchError == null
                    ? '검색 결과가 없어요'
                    : '검색하지 못했어요',
                message: controller.searchError ?? '다른 제목으로 찾아보세요.',
                icon: Icons.search,
              )
            else
              TwoColumnAnimeGrid(
                children: controller.searchResults.map((anime) {
                  final inLibrary = controller.isInLibrary(anime.id);
                  final wished = controller.isWished(anime.id);
                  return AnimePosterCard.fromAnime(
                    anime: anime,
                    showImage: controller.settings.showPosterImages,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen.preview(anime: anime),
                      ),
                    ),
                    metaLines: [
                      ...animeBroadcastMetaLines(
                        anime.firstAirDate,
                        status: anime.status,
                        isMovie: anime.isMovie,
                      ),
                    ],
                    actions: [
                      AnimeCardAction(
                        label: inLibrary ? '추가됨' : '추가',
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
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _searched = true);
    ref.read(appControllerProvider).search(textController.text);
  }
}
