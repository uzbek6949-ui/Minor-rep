import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../screens/lyrics_screen.dart';
import '../screens/song_edit_screen.dart';
import '../state/library_controller.dart';
import '../state/player_controller.dart';
import '../utils/formatters.dart';
import 'add_to_playlist_sheet.dart';
import 'album_art.dart';

/// Ro'yxatdagi bitta qo'shiq qatori — bosilganda ijro boshlanadi.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.queue,
    this.queueLabel = '',
    this.queueSourceId,
    this.playlist,
    this.showHandle = false,
    this.index,
  });

  final Song song;

  /// Shu qatorni bosganda navbatga qo'yiladigan ro'yxat.
  final List<Song>? queue;
  final String queueLabel;
  final String? queueSourceId;

  /// Agar qator playlist ichida ko'rsatilsa — "olib tashlash" amali chiqadi.
  final Playlist? playlist;

  final bool showHandle;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playerController = context.watch<PlayerController>();
    final isCurrent = playerController.currentSong?.id == song.id;

    return ListTile(
      onTap:
          () => playerController.playSong(
            song,
            inList: queue ?? <Song>[song],
            label: queueLabel,
            sourceId: queueSourceId,
          ),
      leading: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AlbumArt(song: song, size: 52),
          if (isCurrent)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                playerController.isPlaying
                    ? Icons.equalizer_rounded
                    : Icons.pause_rounded,
                color: Colors.white,
              ),
            ),
        ],
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isCurrent ? scheme.primary : null,
        ),
      ),
      subtitle: Text(
        '${song.displayArtist} • ${formatDuration(song.duration)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (song.isFavorite)
            Icon(Icons.favorite_rounded, size: 18, color: scheme.primary),
          if (song.hasLyrics)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                Icons.lyrics_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (showHandle && index != null)
            ReorderableDragStartListener(
              index: index!,
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.drag_handle_rounded),
              ),
            )
          else
            _SongMenu(song: song, playlist: playlist),
        ],
      ),
    );
  }
}

class _SongMenu extends StatelessWidget {
  const _SongMenu({required this.song, this.playlist});

  final Song song;
  final Playlist? playlist;

  @override
  Widget build(BuildContext context) {
    final library = context.read<LibraryController>();
    final playerController = context.read<PlayerController>();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) async {
        switch (value) {
          case 'play':
            await playerController.playSong(song);
            break;
          case 'playlist':
            await showAddToPlaylistSheet(context, song);
            break;
          case 'lyrics':
            await Navigator.of(context).push(LyricsScreen.route(song));
            break;
          case 'edit':
            await Navigator.of(context).push(SongEditScreen.route(song));
            break;
          case 'favorite':
            await library.toggleFavorite(song);
            break;
          case 'remove':
            final target = playlist;
            if (target != null) {
              await library.removeSongFromPlaylist(target, song.id);
            }
            break;
          case 'delete':
            final confirmed = await _confirmDelete(context);
            if (confirmed != true) return;
            await playerController.handleSongRemoved(song.id);
            await library.deleteSong(song);
            break;
        }
      },
      itemBuilder:
          (context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'play',
              child: ListTile(
                leading: Icon(Icons.play_arrow_rounded),
                title: Text('Ijro etish'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'playlist',
              child: ListTile(
                leading: Icon(Icons.playlist_add_rounded),
                title: Text('Playlistga qoʻshish'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'lyrics',
              child: ListTile(
                leading: const Icon(Icons.lyrics_rounded),
                title: Text(
                  song.hasLyrics ? 'Lyrics (matn)' : 'Lyrics qoʻshish',
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_rounded),
                title: Text('Maʻlumotlarni tahrirlash'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'favorite',
              child: ListTile(
                leading: Icon(
                  song.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                title: Text(
                  song.isFavorite
                      ? 'Sevimlilardan olish'
                      : 'Sevimlilarga qoʻshish',
                ),
              ),
            ),
            if (playlist != null)
              const PopupMenuItem<String>(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.playlist_remove_rounded),
                  title: Text('Playlistdan olib tashlash'),
                ),
              ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline_rounded),
                title: Text('Kutubxonadan oʻchirish'),
              ),
            ),
          ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Oʻchirilsinmi?'),
            content: Text(
              '"${song.title}" kutubxonadan oʻchiriladi. '
              'Telefon xotirasidagi asl fayl saqlanib qoladi.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Oʻchirish'),
              ),
            ],
          ),
    );
  }
}
