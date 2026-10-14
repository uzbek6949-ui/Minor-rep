import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';

/// Pleer tugmalari: shuffle — oldingi — katta play — keyingi — repeat.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.shuffleEnabled,
    required this.loopMode,
    this.isLoading = false,
    this.onShuffle,
    this.onPrevious,
    this.onPlayPause,
    this.onNext,
    this.onRepeat,
  });

  final bool isPlaying;
  final bool shuffleEnabled;
  final LoopMode loopMode;
  final bool isLoading;
  final VoidCallback? onShuffle;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onRepeat;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _SideButton(
          icon: Icons.shuffle_rounded,
          active: shuffleEnabled,
          onPressed: onShuffle,
          tooltip: 'Tasodifiy tartib',
        ),
        _SideButton(
          icon: Icons.skip_previous_rounded,
          size: 34,
          active: true,
          onPressed: onPrevious,
          tooltip: 'Oldingi',
        ),
        _PlayButton(
          isPlaying: isPlaying,
          isLoading: isLoading,
          onPressed: onPlayPause,
        ),
        _SideButton(
          icon: Icons.skip_next_rounded,
          size: 34,
          active: true,
          onPressed: onNext,
          tooltip: 'Keyingi',
        ),
        _SideButton(
          icon:
              loopMode == LoopMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
          active: loopMode != LoopMode.off,
          onPressed: onRepeat,
          tooltip: switch (loopMode) {
            LoopMode.off => 'Takrorlash: o\u2019chirilgan',
            LoopMode.all => 'Takrorlash: barchasi',
            LoopMode.one => 'Takrorlash: bitta qo\u2019shiq',
          },
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    this.onPressed,
    this.active = false,
    this.size = 26,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: size,
      color: active ? scheme.onSurface : scheme.onSurfaceVariant,
      icon: Icon(icon),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    this.onPressed,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
          boxShadow: AppShadows.button(Theme.of(context).brightness),
        ),
        child:
            isLoading
                ? Padding(
                  padding: const EdgeInsets.all(26),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: scheme.onPrimary,
                  ),
                )
                : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: scheme.onPrimary,
                  size: 36,
                ),
      ),
    );
  }
}
