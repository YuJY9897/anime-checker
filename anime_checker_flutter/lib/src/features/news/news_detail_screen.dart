import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';
import '../../core/date_text.dart';
import '../../core/external_links.dart';
import '../../core/models.dart';
import 'news_webview_screen.dart';

class NewsDetailScreen extends ConsumerWidget {
  const NewsDetailScreen({super.key, required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appControllerProvider).settings;
    return Scaffold(
      appBar: AppBar(title: const Text('뉴스 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${article.source} · ${formatStoredDate(article.date)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (article.summary.trim().isNotEmpty &&
              article.summary.trim() != article.title.trim()) ...[
            const SizedBox(height: 14),
            Text(
              article.summary,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              icon: const Icon(Icons.open_in_browser),
              onPressed: article.url.trim().isEmpty
                  ? null
                  : () {
                      if (settings.openNewsInsideApp) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NewsWebViewScreen(
                              url: article.url,
                              title: article.source,
                            ),
                          ),
                        );
                      } else {
                        ExternalLinks.open(article.url);
                      }
                    },
              label: const Text('원문 보기'),
            ),
          ),
        ],
      ),
    );
  }
}
