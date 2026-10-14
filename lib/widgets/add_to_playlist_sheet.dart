import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_controller.dart';
import '../utils/formatters.dart';

/// Qo'shiqni playlistga qo'shish uchun pastdan chiqadigan oyna.
Future<void> showAddToPlaylistSheet(BuildContext context, Song song) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _AddToPlaylistSheet(song: song),
  );
}

class _AddToPlaylistSheet extends StatelessWidget {
  const _AddToPlaylistSheet({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final playlists = library.playlists;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Playlistga qo’shish',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Yangi playlist yaratish'),
              onTap: () async {
                final name = await promptPlaylistName(context);
                if (name == null || name.trim().isEmpty) return;
                final playlist = await library.createPlaylist(name);
                await library.addSongToPlaylist(playlist, song);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            const Divider(height: 1),
            Flexible(
              child:
                  playlists.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Hali playlist yo’q. Yuqoridagi tugma bilan '
                          'birinchi playlistni yaratishingiz mumkin.',
                          textAlign: TextAlign.center,
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final alreadyIn = playlist.contains(song.id);
                          return ListTile(
                            leading: const Icon(Icons.queue_music_rounded),
                            title: Text(playlist.name),
                            subtitle: Text(songCountLabel(playlist.length)),
                            trailing: Icon(
                              alreadyIn
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color:
                                  alreadyIn
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                            onTap: () async {
                              if (alreadyIn) {
                                await library.removeSongFromPlaylist(
                                  playlist,
                                  song.id,
                                );
                              } else {
                                await library.addSongToPlaylist(playlist, song);
                              }
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Playlist nomini kiritish dialogi. Bekor qilinsa `null` qaytaradi.
Future<String?> promptPlaylistName(
  BuildContext context, {
  String initialValue = '',
  String title = 'Playlist nomi',
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Masalan: Kechqurun'),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Saqlash'),
            ),
          ],
        ),
  );
}
