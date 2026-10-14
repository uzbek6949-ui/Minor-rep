import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Dizayndagi "to'lqin" (waveform) ko'rinishidagi progress.
///
/// Eslatma: bu haqiqiy audio tahlili emas — ustunlar qo'shiq identifikatoridan
/// barqaror tarzda hosil qilinadi (bir xil qo'shiq har doim bir xil ko'rinadi).
/// Ijro etilgan qism to'q, qolgani och rangda bo'ladi; bosib yoki surib
/// istalgan joyga o'tish mumkin.
class WaveformProgress extends StatefulWidget {
  const WaveformProgress({
    super.key,
    required this.seed,
    required this.position,
    required this.duration,
    this.onSeek,
    this.height = 56,
    this.barCount = 58,
  });

  final String seed;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;
  final double height;
  final int barCount;

  @override
  State<WaveformProgress> createState() => _WaveformProgressState();
}

class _WaveformProgressState extends State<WaveformProgress> {
  double? _dragFraction;
  List<double>? _bars;
  String? _barsSeed;

  List<double> _barsFor(String seed) {
    if (_bars != null && _barsSeed == seed) return _bars!;
    _barsSeed = seed;
    _bars = _generateBars(seed, widget.barCount);
    return _bars!;
  }

  /// Seed asosida barqaror "tasodifiy" balandliklar.
  static List<double> _generateBars(String seed, int count) {
    var state = seed.isEmpty ? 7 : seed.hashCode.abs() % 2147483647;
    if (state == 0) state = 7;
    final bars = <double>[];
    for (var i = 0; i < count; i++) {
      state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
      final random = (state >> 8) % 1000 / 1000;
      // Chekkalarga yaqin ustunlar pastroq — tabiiyroq ko'rinadi.
      final edge = (i / (count - 1) - 0.5).abs() * 2;
      final envelope = 0.55 + 0.45 * (1 - edge * edge);
      bars.add((0.16 + random * 0.84) * envelope);
    }
    return bars;
  }

  double get _fraction {
    final drag = _dragFraction;
    if (drag != null) return drag;
    final total = widget.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (widget.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  void _handle(double dx, double width, {required bool finished}) {
    if (widget.onSeek == null || widget.duration.inMilliseconds <= 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    setState(() => _dragFraction = fraction);
    if (finished) {
      widget.onSeek!(
        Duration(
          milliseconds: (widget.duration.inMilliseconds * fraction).round(),
        ),
      );
      setState(() => _dragFraction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = Duration(
      milliseconds:
          widget.duration.inMilliseconds <= 0
              ? widget.position.inMilliseconds
              : (widget.duration.inMilliseconds * _fraction).round(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown:
                  (d) => _handle(d.localPosition.dx, width, finished: true),
              onHorizontalDragUpdate:
                  (d) => _handle(d.localPosition.dx, width, finished: false),
              onHorizontalDragEnd: (_) {
                final drag = _dragFraction;
                if (drag != null) {
                  _handle(drag * width, width, finished: true);
                }
              },
              child: SizedBox(
                height: widget.height,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    bars: _barsFor(widget.seed),
                    progress: _fraction,
                    playedColor: scheme.primary,
                    remainingColor:
                        Theme.of(context).brightness == Brightness.light
                            ? AppColors.waveTrack
                            : AppColors.darkWaveTrack,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              formatDuration(shown),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              formatDuration(widget.duration),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.playedColor,
    required this.remainingColor,
  });

  final List<double> bars;
  final double progress;
  final Color playedColor;
  final Color remainingColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final slot = size.width / bars.length;
    final barWidth = slot * 0.42;
    final paint = Paint()..strokeCap = StrokeCap.round;
    final playedUntil = size.width * progress;

    for (var i = 0; i < bars.length; i++) {
      final center = slot * (i + 0.5);
      final height = (size.height * bars[i]).clamp(3.0, size.height);
      paint.color = center <= playedUntil ? playedColor : remainingColor;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center, size.height / 2),
          width: barWidth,
          height: height,
        ),
        Radius.circular(barWidth),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.bars != bars ||
      oldDelegate.playedColor != playedColor ||
      oldDelegate.remainingColor != remainingColor;
}
