import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist.dart';
import '../state/library_controller.dart';
import '../utils/formatters.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/album_art.dart';
import '../widgets/empty_state.dart';
import 'playlist_detail_screen.dart';

/// Playlistlar ro'yxati.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final playlists = library.playlists;

    return Scaffold(
      appBar: AppBar(title: const Text('Playlistlar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPlaylist(context, library),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yangi playlist'),
      ),
      body:
          playlists.isEmpty
              ? EmptyState(
                icon: Icons.queue_music_rounded,
                title: 'Playlist yoʻq',
                message:
                    'Qoʻshiqlarni mavzu yoki kayfiyat boʻyicha '
                    'guruhlash uchun playlist yarating.',
                action: FilledButton.icon(
                  onPressed: () => _createPlaylist(context, library),
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text('Playlist yaratish'),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final songs = library.songsOfPlaylist(playlist);
                  return ListTile(
                    leading: AlbumArt(
                      song: songs.isEmpty ? null : songs.first,
                      size: 52,
                    ),
                    title: Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(songCountLabel(playlist.length)),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (value) async {
                        if (value == 'rename') {
                          final name = await promptPlaylistName(
                            context,
                            initialValue: playlist.name,
                            title: 'Nomini oʻzgartirish',
                          );
                          if (name == null || name.trim().isEmpty) return;
                          await library.renamePlaylist(playlist, name);
                        } else if (value == 'delete') {
                          final confirmed = await _confirmDelete(
                            context,
                            playlist,
                          );
                          if (confirmed == true) {
                            await library.deletePlaylist(playlist);
                          }
                        }
                      },
                      itemBuilder:
                          (context) => const <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'rename',
                              child: ListTile(
                                leading: Icon(Icons.edit_rounded),
                                title: Text('Nomini oʻzgartirish'),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline_rounded),
                                title: Text('Playlistni oʻchirish'),
                              ),
                            ),
                          ],
                    ),
                    onTap:
                        () => Navigator.of(
                          context,
                        ).push(PlaylistDetailScreen.route(playlist.id)),
                  );
                },
              ),
    );
  }

  Future<void> _createPlaylist(
    BuildContext context,
    LibraryController library,
  ) async {
    final name = await promptPlaylistName(context, title: 'Yangi playlist');
    if (name == null || name.trim().isEmpty) return;
    final playlist = await library.createPlaylist(name);
    if (!context.mounted) return;
    await Navigator.of(context).push(PlaylistDetailScreen.route(playlist.id));
  }

  Future<bool?> _confirmDelete(BuildContext context, Playlist playlist) {
    return showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Playlist oʻchirilsinmi?'),
            content: Text(
              '"${playlist.name}" oʻchiriladi. Qoʻshiqlar kutubxonada qoladi.',
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
