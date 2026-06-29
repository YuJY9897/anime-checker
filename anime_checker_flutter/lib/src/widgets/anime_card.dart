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

class AnimePosterCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasImage = posterUrl.trim().isNotEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.22,
                    ),
                  ),
                  if (genres.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        genres.take(3).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.tertiary, height: 1.24),
                      ),
                    ),
                  for (final line in metaLines.where(
                    (line) => line.trim().isNotEmpty,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xA6000000),
                          height: 1.24,
                        ),
                      ),
                    ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: actions.map((action) {
                        final child = Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                        if (action.filled) {
                          return FilledButton(
                            onPressed: action.onPressed,
                            child: child,
                          );
                        }
                        return OutlinedButton(
                          onPressed: action.onPressed,
                          child: child,
                        );
                      }).toList(),
                    ),
                  ],
                ],
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
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.48,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: children,
    );
  }
}
