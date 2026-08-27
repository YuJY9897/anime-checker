class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.date,
    required this.imageUrl,
    required this.url,
  });

  final String id;
  final String title;
  final String summary;
  final String source;
  final String date;
  final String imageUrl;
  final String url;

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
    id: json['id']?.toString() ?? json['url']?.toString() ?? '',
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? json['content'] as String? ?? '',
    source: json['source'] as String? ?? '',
    date: json['date'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    url: json['url'] as String? ?? json['link'] as String? ?? '',
  );
}
