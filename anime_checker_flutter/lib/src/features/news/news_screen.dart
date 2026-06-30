import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/models.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import 'news_detail_screen.dart';

enum NewsFilter { all, newRelease, season, movie, boxOffice }

extension _NewsFilterText on NewsFilter {
  String get label {
    switch (this) {
      case NewsFilter.all:
        return '전체';
      case NewsFilter.newRelease:
        return '신작';
      case NewsFilter.season:
        return '시즌';
      case NewsFilter.movie:
        return '극장판';
      case NewsFilter.boxOffice:
        return '흥행';
    }
  }

  String? get key {
    switch (this) {
      case NewsFilter.all:
        return null;
      case NewsFilter.newRelease:
        return 'newRelease';
      case NewsFilter.season:
        return 'season';
      case NewsFilter.movie:
        return 'movie';
      case NewsFilter.boxOffice:
        return 'boxOffice';
    }
  }

  bool matches(NewsArticle article) {
    final text = '${article.title} ${article.summary}';
    switch (this) {
      case NewsFilter.all:
        return true;
      case NewsFilter.newRelease:
        return RegExp('신작|공개|방영|개봉').hasMatch(text);
      case NewsFilter.season:
        return RegExp('시즌|[23456789]기|속편|후속').hasMatch(text);
      case NewsFilter.movie:
        return RegExp('극장판|영화|개봉|상영').hasMatch(text);
      case NewsFilter.boxOffice:
        return RegExp('흥행|관객|박스오피스|예매|순위|돌파').hasMatch(text);
    }
  }
}

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  NewsFilter filter = NewsFilter.all;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final enabledNews = controller.news.where((article) {
      final enabledFilters = NewsFilter.values.where((value) {
        final key = value.key;
        return key != null && (controller.settings.newsFilters[key] ?? true);
      });
      return enabledFilters.any((value) => value.matches(article));
    }).toList();
    final items = enabledNews.where(filter.matches).toList();
    return RefreshIndicator(
      onRefresh: () => controller.refreshNews(),
      child: ListView(
        children: [
          SectionHeader(
            title: '애니 소식',
            meta: controller.newsBasis,
            action: IconButton(
              onPressed: controller.refreshNews,
              icon: const Icon(Icons.refresh),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NewsFilter.values.map((value) {
                final key = value.key;
                final enabled =
                    key == null ||
                    (controller.settings.newsFilters[key] ?? true);
                return ChoiceChip(
                  label: Text(value.label),
                  selected: filter == value,
                  onSelected: enabled
                      ? (_) => setState(() => filter = value)
                      : null,
                );
              }).toList(),
            ),
          ),
          if (controller.news.isEmpty)
            const EmptyState(
              title: '뉴스를 가져오지 못했어요',
              message: '프록시 설정이나 네트워크 상태를 확인해 주세요.',
              icon: Icons.article_outlined,
            )
          else if (items.isEmpty)
            const EmptyState(
              title: '해당 소식이 없어요',
              message: '다른 필터를 선택하거나 새로고침해 주세요.',
              icon: Icons.filter_alt_outlined,
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: items
                    .map(
                      (article) => _NewsCard(
                        article: article,
                        showImage: controller.settings.showNewsImages,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.showImage});

  final NewsArticle article;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showImage && article.imageUrl.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.network(
                    article.imageUrl,
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              if (showImage && article.imageUrl.trim().isNotEmpty)
                const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xA6000000),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${article.source} · ${formatStoredDate(article.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
