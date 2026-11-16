import 'package:flutter/material.dart';

import '../core/format/genre_text.dart';
import '../data/models/models.dart';
import 'progress_bar.dart';

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
    this.listMode = false,
    this.statusLabel = '',
    this.progress,
    this.onLongPress,
  });

  factory AnimePosterCard.fromAnime({
    Key? key,
    required Anime anime,
    required VoidCallback onTap,
    List<String> metaLines = const [],
    List<AnimeCardAction> actions = const [],
    bool showImage = true,
    bool listMode = false,
    String statusLabel = '',
    double? progress,
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
      listMode: listMode,
      statusLabel: statusLabel,
      progress: progress,
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

  /// 방영중·완결 같은 상태. 제목 아래에 작은 칩으로 올린다.
  /// 「정보 확인 중」처럼 알려 주는 게 없는 값은 칩을 띄우지 않는다.
  final String statusLabel;

  bool get _showStatusChip =>
      statusLabel.trim().isNotEmpty && !statusLabel.contains('확인 중');

  /// true면 큰 표지 카드 대신 작은 썸네일이 붙은 가로 한 줄로 그린다.
  /// 「큰 표지로 보기」를 끄면 모든 목록 화면이 이 모양이 된다.
  final bool listMode;

  /// 0~1 진행률. null이면 진행률 바를 표시하지 않음.
  final double? progress;
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
    final hasPoster = widget.posterUrl.trim().isNotEmpty && !imageFailed;
    if (widget.listMode) return _buildRow(context, colors, hasPoster);
    // 큰 표지 모드에서는 포스터가 없어도 자리를 비우지 않는다. 한 카드만
    // 이미지 없이 글자만 남으면 같은 격자 안에서 혼자 다르게 보인다.
    final showPosterArea = widget.showImage;
    final hasImage = widget.showImage && hasPoster;
    final compact = !showPosterArea;
    final genres = visibleGenres(widget.genres);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashColor: colors.primary.withValues(alpha: 0.08),
        highlightColor: colors.primary.withValues(alpha: 0.04),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showPosterArea)
              AspectRatio(
                aspectRatio: 2 / 3,
                child: hasImage
                    ? Image.network(
                        widget.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !imageFailed) {
                              setState(() => imageFailed = true);
                            }
                          });
                          return _PosterPlaceholder(colors: colors);
                        },
                      )
                    : _PosterPlaceholder(colors: colors),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (widget._showStatusChip)
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 5 : 7),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _statusChip(context, colors),
                        ),
                      ),
                    if (genres.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: compact ? 4 : 6),
                        child: Text(
                          // 2열 카드 폭에 3개는 늘 잘린다. 2개까지만 보여준다.
                          genres.take(2).join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.tertiary,
                                fontWeight: FontWeight.w800,
                                height: 1.22,
                              ),
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
                          // 화 제목이 붙는 줄이 있어 두 줄까지 허용한다.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.22,
                              ),
                        ),
                      ),
                    const Spacer(),
                    if (widget.progress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GradientProgressBar(
                          value: widget.progress!,
                          height: 4,
                        ),
                      ),
                    if (widget.actions.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      _ActionButtons(actions: widget.actions),
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

  /// 상태를 칩으로 띄울 때 쓸 색. 회색 글자로 묻히지 않게 방영중만
  /// 민트로 올리고, 방영예정은 중간, 완결은 흐리게 둔다.
  Color _statusTone(ColorScheme colors) {
    final label = widget.statusLabel;
    if (label.contains('방영중')) return colors.primary;
    if (label.contains('예정')) return colors.onSurfaceVariant;
    return colors.onSurfaceVariant.withValues(alpha: 0.75);
  }

  /// 상태를 회색 본문 글자 대신 작은 칩으로 띄운다.
  Widget _statusChip(BuildContext context, ColorScheme colors) {
    final tone = _statusTone(colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        widget.statusLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }

  /// 작은 썸네일 + 제목 + 메타 한두 줄. 한 화면에 더 많이 들어간다.
  /// ListTile은 dense일 때 leading 높이를 48로 깎아 표지가 잘리므로 쓰지 않는다.
  Widget _buildRow(BuildContext context, ColorScheme colors, bool hasPoster) {
    final genres = visibleGenres(widget.genres);
    final meta = widget.metaLines
        .where((line) => line.trim().isNotEmpty)
        .take(2)
        .toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashColor: colors.primary.withValues(alpha: 0.08),
        highlightColor: colors.primary.withValues(alpha: 0.04),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: SizedBox(
                  width: 46,
                  height: 69,
                  child: hasPoster
                      ? Image.network(
                          widget.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !imageFailed) {
                                setState(() => imageFailed = true);
                              }
                            });
                            return ColoredBox(
                              color: colors.surfaceContainerHighest,
                            );
                          },
                        )
                      : ColoredBox(color: colors.surfaceContainerHighest),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (widget._showStatusChip)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _statusChip(context, colors),
                        ),
                      ),
                    if (genres.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          genres.take(2).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.tertiary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    for (final line in meta)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.2,
                              ),
                        ),
                      ),
                    if (widget.progress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: GradientProgressBar(
                          value: widget.progress!,
                          height: 3,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                _ActionButtons(actions: widget.actions, flexible: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 큰 표지일 땐 2열 격자, 작은 썸네일일 땐 한 줄짜리 목록으로 쌓는다.
/// 표지를 못 받았을 때 자리를 지키는 칸. 목록 모드의 작은 썸네일 자리와
/// 같은 색을 써서 두 보기가 같은 모양으로 보이게 한다.
class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 26,
          color: colors.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class TwoColumnAnimeGrid extends StatelessWidget {
  const TwoColumnAnimeGrid({
    super.key,
    required this.children,
    this.listMode = false,
    this.horizontalPadding = 16,
  });

  final List<Widget> children;
  final bool listMode;

  /// 바깥에서 이미 좌우 여백을 준 화면(편성표)은 0을 넘겨 여백이 겹치지 않게 한다.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (listMode) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          6,
          horizontalPadding,
          22,
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index += 1)
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                child: children[index],
              ),
          ],
        ),
      );
    }
    // 카드가 내용만큼만 높아지도록 행 단위로 배치한다.
    // 같은 행의 두 카드는 IntrinsicHeight로 높이를 맞춘다.
    final rows = <Widget>[];
    for (var index = 0; index < children.length; index += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[index]),
                const SizedBox(width: 12),
                Expanded(
                  child: index + 1 < children.length
                      ? children[index + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, 22),
      child: Column(children: rows),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.actions, this.flexible = true});

  final List<AnimeCardAction> actions;

  /// 가로 폭이 정해지지 않은 자리(목록 모드의 Row 오른쪽 끝)에서는
  /// Flexible을 쓸 수 없다. 쓰면 RenderFlex가 터진다.
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    if (actions.length <= 2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < actions.length; index += 1) ...[
            if (index > 0) const SizedBox(width: 6),
            if (flexible)
              Flexible(child: _ActionButton(action: actions[index]))
            else
              _ActionButton(action: actions[index]),
          ],
        ],
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: actions.map((action) => _ActionButton(action: action)).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final AnimeCardAction action;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      ),
      child: child,
    );
  }
}
