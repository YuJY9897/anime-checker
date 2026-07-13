import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/models.dart';
import '../../widgets/empty_state.dart';
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
  static const _pageSize = 20;

  NewsFilter filter = NewsFilter.all;
  int visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appControllerProvider).ensureNewsLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final filteredAll = controller.news.where(filter.matches).toList();
    final items = filteredAll.take(visibleCount).toList();
    return RefreshIndicator(
      onRefresh: () => controller.refreshNews(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 400 &&
              visibleCount < filteredAll.length) {
            setState(() => visibleCount += _pageSize);
          }
          return false;
        },
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.newsLoading ? '불러오는 중…' : controller.newsBasis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '새로고침',
                    onPressed: controller.newsLoading
                        ? null
                        : controller.refreshNews,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '기사 ${filteredAll.length}개',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<NewsFilter>(
                      initialValue: filter,
                      decoration: const InputDecoration(
                        labelText: '주제',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: NewsFilter.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            filter = value;
                            visibleCount = _pageSize;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (controller.newsLoading && controller.news.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(
                        '새 소식을 모으고 있어요. 조금만 기다려 주세요.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else if (controller.news.isEmpty)
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
                      .map((article) => _NewsCard(article: article))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashColor: colors.primary.withValues(alpha: 0.08),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (article.summary.trim().isNotEmpty &&
                        article.summary.trim() != article.title.trim()) ...[
                      const SizedBox(height: 6),
                      Text(
                        article.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          '${article.source} · ${formatStoredDate(article.date)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
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
