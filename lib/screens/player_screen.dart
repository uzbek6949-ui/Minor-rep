import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_controller.dart';
import '../state/player_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/album_art.dart';
import '../widgets/empty_state.dart';
import '../widgets/player_controls.dart';
import '../widgets/song_tile.dart';
import '../widgets/waveform_progress.dart';
import 'lyrics_screen.dart';

/// To'liq pleer ekrani: katta albom rasmi, to'lqinli progress, boshqaruv.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const PlayerScreen());

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerController>();
    final library = context.watch<LibraryController>();
    final current = controller.currentSong;
    final song = current == null ? null : library.songById(current.id) ?? current;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.play_circle_outline_rounded,
          title: 'Hozir hech narsa ijro etilmayapti',
          message: 'Kutubxonadan qo’shiq tanlang.',
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _TopBar(
              label: controller.queueLabel.isEmpty
                  ? 'Hozir ijroda'
                  : controller.queueLabel,
              onQueue: () => _showQueue(context, controller),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final artSize = (constraints.maxWidth - 88).clamp(140.0, 340.0);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: constraints.maxHeight * 0.02),
                        AlbumArt(
                          song: song,
                          size: artSize.toDouble(),
                          radius: AppRadii.artwork,
                          shadow: AppShadows.artwork(),
                        ),
                        const SizedBox(height: 34),
                        _TitleRow(
                          song: song,
                          onFavorite: () => library.toggleFavorite(song),
                          onMenu: () => showSongMenu(context, song: song),
                        ),
                        const SizedBox(height: 26),
                        StreamBuilder<PositionData>(
                          stream: controller.positionDataStream,
                          builder: (context, snapshot) {
                            final data = snapshot.data ?? PositionData.zero;
                            return WaveformProgress(
                              seed: song.id,
                              position: data.position,
                              duration: data.duration.inMilliseconds > 0
                                  ? data.duration
                                  : song.duration,
                              onSeek: controller.seek,
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        StreamBuilder<PlayerState>(
                          stream: controller.player.playerStateStream,
                          builder: (context, snapshot) {
                            final state = snapshot.data;
                            final processing = state?.processingState;
                            return PlayerControls(
                              isPlaying: state?.playing ?? false,
                              shuffleEnabled: controller.shuffleEnabled,
                              loopMode: controller.loopMode,
                              isLoading: processing == ProcessingState.loading ||
                                  processing == ProcessingState.buffering,
                              onShuffle: controller.toggleShuffle,
                              onPrevious: controller.previous,
                              onPlayPause: controller.togglePlayPause,
                              onNext: controller.next,
                              onRepeat: controller.cycleRepeatMode,
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .push(LyricsScreen.route(song)),
                              icon: const Icon(Icons.subject_rounded, size: 19),
                              label: Text(
                                song.hasLyrics ? 'Lyrics' : 'Lyrics qo’shish',
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _showQueue(context, controller),
                              icon: const Icon(Icons.queue_music_rounded, size: 19),
                              label: Text(songCountLabel(controller.queue.length)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQueue(BuildContext context, PlayerController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final queue = controller.queue;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Navbat • ${songCountLabel(queue.length)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final isCurrent = controller.currentIndex == index;
                      return ListTile(
                        leading: AlbumArt(song: item, size: 44, radius: 12),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          item.displayArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(formatDuration(item.duration)),
                        onTap: () {
                          controller.seekToIndex(index);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.label, required this.onQueue});

  final String label;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            tooltip: 'Yopish',
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: onQueue,
            icon: const Icon(Icons.queue_music_rounded, size: 26),
            tooltip: 'Navbat',
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.song,
    required this.onFavorite,
    required this.onMenu,
  });

  final Song song;
  final VoidCallback onFavorite;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onFavorite,
          iconSize: 24,
          color: song.isFavorite ? scheme.onSurface : scheme.onSurfaceVariant,
          icon: Icon(
            song.isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
          ),
        ),
        Expanded(
          child: Column(
            children: <Widget>[
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.album.trim().isEmpty
                    ? song.displayArtist
                    : '${song.displayArtist} • ${song.album}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onMenu,
          iconSize: 24,
          color: scheme.onSurfaceVariant,
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }
}
