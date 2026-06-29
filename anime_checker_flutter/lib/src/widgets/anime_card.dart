import 'package:flutter/material.dart';

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
    this.onLongPress,
  });

  factory AnimePosterCard.fromAnime({
    Key? key,
    required Anime anime,
    required VoidCallback onTap,
    List<String> metaLines = const [],
    List<AnimeCardAction> actions = const [],
    VoidCallback? onLongPress,
  }) {
    return AnimePosterCard(
      key: key,
      title: anime.title,
      posterUrl: anime.posterUrl,
      genres: anime.genres,
      metaLines: metaLines,
      actions: actions,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  final String title;
  final String posterUrl;
  final List<String> genres;
  final List<String> metaLines;
  final List<AnimeCardAction> actions;
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
    final hasImage = widget.posterUrl.trim().isNotEmpty && !imageFailed;
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
                    if (widget.genres.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          widget.genres.take(3).join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.tertiary, height: 1.24),
                        ),
                      ),
                    for (final line in widget.metaLines.where(
                      (line) => line.trim().isNotEmpty,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          line,
                          maxLines: 2,
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
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
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
                                minimumSize: const Size(0, 30),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              child: child,
                            );
                          }
                          return OutlinedButton(
                            onPressed: action.onPressed,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
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
  const TwoColumnAnimeGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 32.0;
        const spacing = 10.0;
        final cardWidth =
            (constraints.maxWidth - horizontalPadding - spacing) / 2;
        final cardHeight = cardWidth * 2.78;
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
