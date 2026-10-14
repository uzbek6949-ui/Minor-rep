import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_controller.dart';
import '../state/player_controller.dart';
import '../utils/formatters.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/album_art.dart';
import '../widgets/empty_state.dart';
import 'lyrics_screen.dart';
import 'song_edit_screen.dart';

/// To'liq pleer ekrani: katta albom rasmi, boshqaruv tugmalari, Lyrics tugmasi.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const PlayerScreen());

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerController>();
    final library = context.watch<LibraryController>();
    final current = controller.currentSong;
    // Kutubxonadagi eng yangi nusxa (nom/matn tahrirlangan bo'lishi mumkin).
    final song =
        current == null ? null : library.songById(current.id) ?? current;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.play_circle_outline_rounded,
          title: 'Hozir hech narsa ijro etilmayapti',
          message: 'Kutubxonadan qoʻshiq tanlang.',
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.queueLabel.isEmpty
              ? 'Hozir ijroda'
              : controller.queueLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Navbat',
            onPressed: () => _showQueue(context, controller),
            icon: const Icon(Icons.queue_music_rounded),
          ),
          IconButton(
            tooltip: 'Tahrirlash',
            onPressed:
                () => Navigator.of(context).push(SongEditScreen.route(song)),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artSize = constraints.maxWidth.clamp(0.0, 420.0) - 48;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.25),
                              blurRadius: 40,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: AlbumArt(
                          song: song,
                          size: artSize < 160 ? 160 : artSize,
                          radius: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                song.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.album.trim().isEmpty
                                    ? song.displayArtist
                                    : '${song.displayArtist} • ${song.album}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sevimli',
                          onPressed: () => library.toggleFavorite(song),
                          icon: Icon(
                            song.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: song.isFavorite ? scheme.primary : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ProgressBar(controller: controller),
                    const SizedBox(height: 8),
                    _Controls(controller: controller),
                    const SizedBox(height: 12),
                    _SecondaryActions(song: song),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Navbat • ${songCountLabel(queue.length)}',
                          style: Theme.of(sheetContext).textTheme.titleMedium,
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
                        leading: AlbumArt(song: item, size: 44, radius: 10),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isCurrent
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
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

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.controller});

  final PlayerController controller;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: widget.controller.positionDataStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? PositionData.zero;
        final totalMs = data.duration.inMilliseconds.toDouble();
        final hasDuration = totalMs > 0;
        final maxMs = hasDuration ? totalMs : 1.0;
        final positionMs = data.position.inMilliseconds.toDouble();
        final value = (_dragValue ?? positionMs).clamp(0.0, maxMs);

        return Column(
          children: <Widget>[
            Slider(
              min: 0,
              max: maxMs,
              value: hasDuration ? value : 0.0,
              onChanged:
                  !hasDuration
                      ? null
                      : (next) => setState(() => _dragValue = next),
              onChangeEnd: (next) {
                widget.controller.seek(Duration(milliseconds: next.round()));
                setState(() => _dragValue = null);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    formatDuration(Duration(milliseconds: value.round())),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    formatDuration(data.duration),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loopMode = controller.loopMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          tooltip: 'Tasodifiy tartib',
          onPressed: controller.toggleShuffle,
          icon: Icon(
            Icons.shuffle_rounded,
            color: controller.shuffleEnabled ? scheme.primary : null,
          ),
        ),
        IconButton(
          tooltip: 'Oldingi',
          iconSize: 38,
          onPressed: controller.previous,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        StreamBuilder<PlayerState>(
          stream: controller.player.playerStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final processing = state?.processingState;
            final loading =
                processing == ProcessingState.loading ||
                processing == ProcessingState.buffering;
            final playing = state?.playing ?? false;

            if (loading) {
              return const SizedBox(
                width: 72,
                height: 72,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return IconButton(
              tooltip: playing ? 'Toʻxtatish' : 'Ijro etish',
              iconSize: 72,
              onPressed: controller.togglePlayPause,
              icon: Icon(
                playing
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: scheme.primary,
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Keyingi',
          iconSize: 38,
          onPressed: controller.next,
          icon: const Icon(Icons.skip_next_rounded),
        ),
        IconButton(
          tooltip: switch (loopMode) {
            LoopMode.off => 'Takrorlash: oʻchirilgan',
            LoopMode.all => 'Takrorlash: barchasi',
            LoopMode.one => 'Takrorlash: bitta qoʻshiq',
          },
          onPressed: controller.cycleRepeatMode,
          icon: Icon(
            loopMode == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: loopMode == LoopMode.off ? null : scheme.primary,
          ),
        ),
      ],
    );
  }
}

class _SecondaryActions extends StatelessWidget {
  const _SecondaryActions({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(LyricsScreen.route(song)),
          icon: const Icon(Icons.lyrics_rounded),
          label: Text(song.hasLyrics ? 'Lyrics' : 'Lyrics qoʻshish'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => showAddToPlaylistSheet(context, song),
          icon: const Icon(Icons.playlist_add_rounded),
          label: const Text('Playlist'),
        ),
      ],
    );
  }
}
