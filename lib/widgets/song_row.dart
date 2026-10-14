import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'album_art.dart';

/// Ro'yxatdagi bitta qo'shiq qatori — faqat ko'rinish (holatga bog'liq emas).
///
/// Ijro etilayotgan qator oq "tabletka" ichida, chapda ekvalayzer chiziqlari
/// bilan ko'rsatiladi — dizayndagi kabi.
class SongRow extends StatelessWidget {
  const SongRow({
    super.key,
    required this.song,
    this.isCurrent = false,
    this.isPlaying = false,
    this.index,
    this.onTap,
    this.onMenu,
    this.trailing,
  });

  final Song song;
  final bool isCurrent;
  final bool isPlaying;

  /// Berilsa — albom rasmi o'rniga tartib raqami chiqadi.
  final int? index;

  final VoidCallback? onTap;
  final VoidCallback? onMenu;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.tile),
          boxShadow: isCurrent ? AppShadows.soft(opacity: 0.07) : null,
        ),
        child: Material(
          color: isCurrent ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child:
                          isCurrent
                              ? _EqualizerMark(
                                animated: isPlaying,
                                color: scheme.primary,
                              )
                              : (index != null
                                  ? Text(
                                    index!.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  )
                                  : AlbumArt(song: song, size: 48, radius: 14)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                song.displayArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              '  •  ${formatDuration(song.duration)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (song.isFavorite)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.favorite,
                        size: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (song.hasLyrics)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.subject_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (trailing != null)
                    trailing!
                  else if (onMenu != null)
                    IconButton(
                      onPressed: onMenu,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ijro etilayotgan qo'shiq yonidagi chiziqchalar.
class _EqualizerMark extends StatefulWidget {
  const _EqualizerMark({required this.animated, required this.color});

  final bool animated;
  final Color color;

  @override
  State<_EqualizerMark> createState() => _EqualizerMarkState();
}

class _EqualizerMarkState extends State<_EqualizerMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _EqualizerMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const factors = <double>[0.45, 1.0, 0.65, 0.85];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (var i = 0; i < factors.length; i++) ...<Widget>[
              Container(
                width: 3,
                height:
                    6 +
                    16 *
                        factors[i] *
                        (widget.animated
                            ? (0.45 + 0.55 * ((t + i * 0.22) % 1.0))
                            : 0.7),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (i != factors.length - 1) const SizedBox(width: 3),
            ],
          ],
        );
      },
    );
  }
}
