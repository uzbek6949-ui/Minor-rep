import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/library_controller.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

/// Qidiruv ekrani — nom, ijrochi, albom bo'yicha; janr va playlist filtri bilan.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String? _genre;
  String? _playlistId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final genres = library.availableGenres;
    final playlists = library.playlists;

    final results = library.search(
      _query,
      genre: _genre,
      playlistId: _playlistId,
    );

    final hasFilters =
        _query.trim().isNotEmpty || _genre != null || _playlistId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Qidiruv')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Qo’shiq nomi yoki ijrochi...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (genres.isNotEmpty || playlists.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: <Widget>[
                  for (final genre in genres)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        avatar: const Icon(Icons.music_note_rounded, size: 18),
                        label: Text(genre),
                        selected: _genre == genre,
                        onSelected:
                            (selected) => setState(
                              () => _genre = selected ? genre : null,
                            ),
                      ),
                    ),
                  for (final playlist in playlists)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        avatar: const Icon(Icons.queue_music_rounded, size: 18),
                        label: Text(playlist.name),
                        selected: _playlistId == playlist.id,
                        onSelected:
                            (selected) => setState(
                              () => _playlistId = selected ? playlist.id : null,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(songCountLabel(results.length))),
                  TextButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _query = '';
                        _genre = null;
                        _playlistId = null;
                      });
                    },
                    child: const Text('Tozalash'),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                !hasFilters
                    ? const EmptyState(
                      icon: Icons.search_rounded,
                      title: 'Qidirishni boshlang',
                      message:
                          'Qo’shiq nomi yoki ijrochi nomini yozing, '
                          'yoki janr/playlist filtridan foydalaning.',
                    )
                    : results.isEmpty
                    ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Hech narsa topilmadi',
                      message: 'Boshqa so’z bilan qidirib ko’ring.',
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: results.length,
                      itemBuilder:
                          (context, index) => SongTile(
                            song: results[index],
                            queue: results,
                            queueLabel: 'Qidiruv natijalari',
                            queueSourceId: 'search',
                          ),
                    ),
          ),
        ],
      ),
    );
  }
}
