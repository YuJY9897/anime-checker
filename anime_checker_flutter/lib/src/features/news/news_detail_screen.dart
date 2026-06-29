import 'package:flutter/material.dart';

import '../../core/date_text.dart';
import '../../core/models.dart';
import 'news_webview_screen.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('뉴스 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (article.imageUrl.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          if (article.imageUrl.trim().isNotEmpty) const SizedBox(height: 14),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0x99000000)),
          ),
          const SizedBox(height: 14),
          Text(
            article.summary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_browser),
            onPressed: article.url.trim().isEmpty
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NewsWebViewScreen(
                        url: article.url,
                        title: article.source,
                      ),
                    ),
                  ),
            label: const Text('원문 보기'),
          ),
        ],
      ),
    );
  }
}
