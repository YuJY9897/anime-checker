import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
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
          SectionHeader(
            title: '검색 결과',
            meta: controller.apiConfigured
                ? '${controller.searchResults.length}개'
                : '${controller.searchResults.length}개 · 보관함 검색',
          ),
          if (controller.searchResults.isEmpty)
            EmptyState(
              title: '검색 결과가 없어요',
              message: controller.apiConfigured
                  ? '제목을 입력하고 검색해 주세요.'
                  : 'API 주소가 연결되지 않아 지금은 보관함 안에서만 검색돼요.',
              icon: Icons.search,
            )
          else
            TwoColumnAnimeGrid(
              compact: !controller.settings.showPosterImages,
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
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _submit() => ref.read(appControllerProvider).search(textController.text);
}
