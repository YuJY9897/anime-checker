import 'package:flutter/material.dart';

import '../core/genre_text.dart';
import '../core/models.dart';

class AnimeCardAction {
  const AnimeCardAction({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
}

class AnimePosterCard extends StatefulWidget {
  const AnimePosterCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.onTap,
    this.genres = const [],
    this.metaLines = const [],
    this.actions = const [],
    this.showImage = true,
    this.onLongPress,
  });

  factory AnimePosterCard.fromAnime({
    Key? key,
    required Anime anime,
    required VoidCallback onTap,
    List<String> metaLines = const [],
    List<AnimeCardAction> actions = const [],
    bool showImage = true,
    VoidCallback? onLongPress,
  }) {
    return AnimePosterCard(
      key: key,
      title: anime.title,
      posterUrl: anime.posterUrl,
      genres: anime.genres,
      metaLines: metaLines,
      actions: actions,
      showImage: showImage,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  final String title;
  final String posterUrl;
  final List<String> genres;
  final List<String> metaLines;
  final List<AnimeCardAction> actions;
  final bool showImage;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<AnimePosterCard> createState() => _AnimePosterCardState();
}

class _AnimePosterCardState extends State<AnimePosterCard> {
  bool imageFailed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasImage =
        widget.showImage && widget.posterUrl.trim().isNotEmpty && !imageFailed;
    final compact = !hasImage;
    final genres = visibleGenres(widget.genres);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Image.network(
                  widget.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !imageFailed) {
                        setState(() => imageFailed = true);
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.22,
                      ),
                    ),
                    if (genres.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 4 : 6),
                        child: Text(
                          genres.take(compact ? 2 : 3).join(' · '),
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.tertiary, height: 1.24),
                        ),
                      ),
                    for (final line
                        in widget.metaLines
                            .where((line) => line.trim().isNotEmpty)
                            .take(compact ? 2 : widget.metaLines.length))
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 4 : 5),
                        child: Text(
                          line,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xA6000000),
                                height: 1.24,
                              ),
                        ),
                      ),
                    const Spacer(),
                    if (widget.actions.isNotEmpty) ...[
                      SizedBox(height: compact ? 7 : 9),
                      Wrap(
                        spacing: compact ? 5 : 6,
                        runSpacing: compact ? 5 : 6,
                        children: widget.actions.map((action) {
                          final child = Text(
                            action.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                          if (action.filled) {
                            return FilledButton(
                              onPressed: action.onPressed,
                              style: FilledButton.styleFrom(
                                minimumSize: Size(0, compact ? 28 : 30),
                                visualDensity: compact
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                                tapTargetSize: compact
                                    ? MaterialTapTargetSize.shrinkWrap
                                    : null,
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 8 : 10,
                                  vertical: compact ? 4 : 6,
                                ),
                              ),
                              child: child,
                            );
                          }
                          return OutlinedButton(
                            onPressed: action.onPressed,
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(0, compact ? 28 : 30),
                              visualDensity: compact
                                  ? VisualDensity.compact
                                  : VisualDensity.standard,
                              tapTargetSize: compact
                                  ? MaterialTapTargetSize.shrinkWrap
                                  : null,
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 8 : 9,
                                vertical: compact ? 4 : 6,
                              ),
                            ),
                            child: child,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TwoColumnAnimeGrid extends StatelessWidget {
  const TwoColumnAnimeGrid({
    super.key,
    required this.children,
    this.compact = false,
  });

  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 32.0;
        const spacing = 10.0;
        final cardWidth =
            (constraints.maxWidth - horizontalPadding - spacing) / 2;
        final cardHeight = cardWidth * (compact ? 1.18 : 2.78);
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: 10,
          childAspectRatio: cardWidth / cardHeight,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: children,
        );
      },
    );
  }
}
