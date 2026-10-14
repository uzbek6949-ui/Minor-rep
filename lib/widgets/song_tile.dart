import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../screens/lyrics_screen.dart';
import '../screens/song_edit_screen.dart';
import '../state/library_controller.dart';
import '../state/player_controller.dart';
import 'add_to_playlist_sheet.dart';
import 'song_row.dart';

/// [SongRow]ni ilova holatiga ulaydi: bosilganda ijro, menyudagi amallar.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    this.queue,
    this.queueLabel = '',
    this.queueSourceId,
    this.playlist,
    this.index,
    this.showHandle = false,
  });

  final Song song;

  /// Shu qatorni bosganda navbatga qo'yiladigan ro'yxat.
  final List<Song>? queue;
  final String queueLabel;
  final String? queueSourceId;

  /// Agar qator playlist ichida ko'rsatilsa — "olib tashlash" amali chiqadi.
  final Playlist? playlist;

  final int? index;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerController>();
    final isCurrent = playerController.currentSong?.id == song.id;

    return SongRow(
      song: song,
      index: index,
      isCurrent: isCurrent,
      isPlaying: isCurrent && playerController.isPlaying,
      onTap:
          () => playerController.playSong(
            song,
            inList: queue ?? <Song>[song],
            label: queueLabel,
            sourceId: queueSourceId,
          ),
      trailing:
          showHandle && index != null
              ? ReorderableDragStartListener(
                index: index! - 1 < 0 ? 0 : index! - 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              : null,
      onMenu: () => showSongMenu(context, song: song, playlist: playlist),
    );
  }
}

/// Qo'shiq amallari — pastdan chiqadigan menyu.
Future<void> showSongMenu(
  BuildContext context, {
  required Song song,
  Playlist? playlist,
}) async {
  final library = context.read<LibraryController>();
  final playerController = context.read<PlayerController>();

  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      Widget item(IconData icon, String title, String value) => ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        onTap: () => Navigator.of(sheetContext).pop(value),
      );

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            item(Icons.play_arrow_rounded, 'Ijro etish', 'play'),
            item(Icons.playlist_add_rounded, 'Playlistga qo’shish', 'playlist'),
            item(
              Icons.subject_rounded,
              song.hasLyrics ? 'Lyrics (matn)' : 'Lyrics qo’shish',
              'lyrics',
            ),
            item(Icons.edit_outlined, 'Ma’lumotlarni tahrirlash', 'edit'),
            item(
              song.isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
              song.isFavorite ? 'Sevimlilardan olish' : 'Sevimlilarga qo’shish',
              'favorite',
            ),
            if (playlist != null)
              item(
                Icons.playlist_remove_rounded,
                'Playlistdan olib tashlash',
                'remove',
              ),
            item(
              Icons.delete_outline_rounded,
              'Kutubxonadan o’chirish',
              'delete',
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (action == null || !context.mounted) return;

  switch (action) {
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
      if (playlist != null) {
        await library.removeSongFromPlaylist(playlist, song.id);
      }
      break;
    case 'delete':
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('O’chirilsinmi?'),
              content: Text(
                '"${song.title}" kutubxonadan o’chiriladi. '
                'Telefon xotirasidagi asl fayl saqlanib qoladi.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Bekor qilish'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('O’chirish'),
                ),
              ],
            ),
      );
      if (confirmed != true) return;
      await playerController.handleSongRemoved(song.id);
      await library.deleteSong(song);
      break;
  }
}
