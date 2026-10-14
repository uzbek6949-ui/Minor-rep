import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/player_screen.dart';
import '../state/library_controller.dart';
import '../state/player_controller.dart';
import 'mini_player_bar.dart';

/// Mini pleerni ilova holatiga ulaydi.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerController>();
    final library = context.watch<LibraryController>();
    final current = controller.currentSong;
    if (current == null) return const SizedBox.shrink();

    final song = library.songById(current.id) ?? current;

    return StreamBuilder<PositionData>(
      stream: controller.positionDataStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? PositionData.zero;
        final total = data.duration.inMilliseconds;
        final progress = total <= 0 ? 0.0 : data.position.inMilliseconds / total;

        return MiniPlayerBar(
          song: song,
          isPlaying: controller.isPlaying,
          progress: progress,
          onTap: () => Navigator.of(context).push(PlayerScreen.route()),
          onPlayPause: controller.togglePlayPause,
          onFavorite: () => library.toggleFavorite(song),
        );
      },
    );
  }
}
