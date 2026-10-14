import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_controller.dart';
import '../state/player_controller.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

/// Bitta playlist ichidagi qo'shiqlar — tartibini o'zgartirish ham mumkin.
class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  static Route<void> route(String playlistId) => MaterialPageRoute<void>(
    builder: (_) => PlaylistDetailScreen(playlistId: playlistId),
  );

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final playerController = context.read<PlayerController>();
    final playlist = library.playlistById(playlistId);

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Playlist topilmadi',
        ),
      );
    }

    final songs = library.songsOfPlaylist(playlist);

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: <Widget>[
          IconButton(
            tooltip: 'Qoʻshiq qoʻshish',
            onPressed: () => _pickSongs(context, library, playlistId),
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (songs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      songCountLabel(songs.length),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await playerController.playQueue(
                        songs,
                        label: playlist.name,
                        sourceId: playlist.id,
                      );
                      if (!playerController.shuffleEnabled) {
                        await playerController.toggleShuffle();
                      }
                    },
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Tasodifiy'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed:
                        () => playerController.playQueue(
                          songs,
                          label: playlist.name,
                          sourceId: playlist.id,
                        ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Ijro'),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                songs.isEmpty
                    ? EmptyState(
                      icon: Icons.queue_music_rounded,
                      title: 'Playlist boʻsh',
                      message:
                          'Kutubxonadan qoʻshiq tanlab, '
                          'shu playlistga qoʻshing.',
                      action: FilledButton.icon(
                        onPressed:
                            () => _pickSongs(context, library, playlistId),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Qoʻshiq qoʻshish'),
                      ),
                    )
                    : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: songs.length,
                      onReorder:
                          (oldIndex, newIndex) => library.reorderPlaylist(
                            playlist,
                            oldIndex,
                            newIndex,
                          ),
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return Dismissible(
                          key: ValueKey<String>('playlist-item-${song.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: const Icon(Icons.playlist_remove_rounded),
                          ),
                          onDismissed:
                              (_) => library.removeSongFromPlaylist(
                                playlist,
                                song.id,
                              ),
                          child: SongTile(
                            song: song,
                            queue: songs,
                            queueLabel: playlist.name,
                            queueSourceId: playlist.id,
                            playlist: playlist,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSongs(
    BuildContext context,
    LibraryController library,
    String playlistId,
  ) async {
    final playlist = library.playlistById(playlistId);
    if (playlist == null) return;

    final selected = await showModalBottomSheet<List<Song>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (sheetContext) => _SongPickerSheet(
            songs:
                library.allSongs
                    .where((song) => !playlist.contains(song.id))
                    .toList(),
          ),
    );

    if (selected == null || selected.isEmpty) return;
    await library.addSongsToPlaylist(playlist, selected);
  }
}

class _SongPickerSheet extends StatefulWidget {
  const _SongPickerSheet({required this.songs});

  final List<Song> songs;

  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final Set<String> _selected = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final visible =
        needle.isEmpty
            ? widget.songs
            : widget.songs
                .where((song) => song.searchIndex.contains(needle))
                .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Qoʻshiq izlash...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child:
                  visible.isEmpty
                      ? const EmptyState(
                        icon: Icons.music_off_rounded,
                        title: 'Qoʻshadigan qoʻshiq yoʻq',
                      )
                      : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final song = visible[index];
                          final checked = _selected.contains(song.id);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.displayArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onChanged:
                                (value) => setState(() {
                                  if (value == true) {
                                    _selected.add(song.id);
                                  } else {
                                    _selected.remove(song.id);
                                  }
                                }),
                          );
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text('${_selected.length} ta tanlandi')),
                  FilledButton(
                    onPressed:
                        _selected.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(
                              widget.songs
                                  .where((song) => _selected.contains(song.id))
                                  .toList(),
                            ),
                    child: const Text('Qoʻshish'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
