import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_controller.dart';
import '../state/player_controller.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

/// Bosh ekran — barcha qo'shiqlar ro'yxati.
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  bool _onlyFavorites = false;

  Future<void> _import(LibraryController library) async {
    final result = await library.importFromDevice();
    if (!mounted || result.cancelled) return;

    final message =
        result.added == 0
            ? 'Yangi qoʻshiq qoʻshilmadi'
            : '${result.added} ta qoʻshiq qoʻshildi'
                '${result.skipped > 0 ? ' (${result.skipped} ta oʻtkazib yuborildi)' : ''}';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final playerController = context.read<PlayerController>();
    final songs = _onlyFavorites ? library.favorites : library.songs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minor Rep'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sevimlilar',
            onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
            icon: Icon(
              _onlyFavorites
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
          ),
          PopupMenuButton<SongSort>(
            tooltip: 'Tartiblash',
            icon: const Icon(Icons.sort_rounded),
            initialValue: library.sort,
            onSelected: library.setSort,
            itemBuilder:
                (context) => const <PopupMenuEntry<SongSort>>[
                  PopupMenuItem<SongSort>(
                    value: SongSort.titleAsc,
                    child: Text('Nomi boʻyicha'),
                  ),
                  PopupMenuItem<SongSort>(
                    value: SongSort.artistAsc,
                    child: Text('Ijrochisi boʻyicha'),
                  ),
                  PopupMenuItem<SongSort>(
                    value: SongSort.recentlyAdded,
                    child: Text('Yangi qoʻshilganlar'),
                  ),
                  PopupMenuItem<SongSort>(
                    value: SongSort.durationDesc,
                    child: Text('Davomiyligi boʻyicha'),
                  ),
                ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: library.isImporting ? null : () => _import(library),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Qoʻshiq qoʻshish'),
      ),
      body:
          library.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: <Widget>[
                  if (library.isImporting) _ImportProgress(library: library),
                  if (library.availableGenres.isNotEmpty)
                    _GenreFilterBar(library: library),
                  if (songs.isNotEmpty)
                    _LibraryHeader(
                      songs: songs,
                      onPlayAll:
                          () => playerController.playQueue(
                            songs,
                            label:
                                _onlyFavorites
                                    ? 'Sevimlilar'
                                    : 'Barcha qoʻshiqlar',
                            sourceId: 'all',
                          ),
                      onShuffleAll: () async {
                        await playerController.playQueue(
                          songs,
                          label:
                              _onlyFavorites
                                  ? 'Sevimlilar'
                                  : 'Barcha qoʻshiqlar',
                          sourceId: 'all',
                        );
                        if (!playerController.shuffleEnabled) {
                          await playerController.toggleShuffle();
                        }
                      },
                    ),
                  Expanded(
                    child:
                        songs.isEmpty
                            ? _emptyState(library)
                            : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 96),
                              itemCount: songs.length,
                              itemBuilder:
                                  (context, index) => SongTile(
                                    song: songs[index],
                                    queue: songs,
                                    queueLabel:
                                        _onlyFavorites
                                            ? 'Sevimlilar'
                                            : 'Barcha qoʻshiqlar',
                                    queueSourceId: 'all',
                                  ),
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _emptyState(LibraryController library) {
    if (_onlyFavorites) {
      return const EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Sevimli qoʻshiqlar yoʻq',
        message: 'Qoʻshiq menyusidan "Sevimlilarga qoʻshish"ni tanlang.',
      );
    }
    if (library.genreFilter != null) {
      return EmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'Bu janrda qoʻshiq yoʻq',
        message: 'Filtrni oʻchirib, barcha qoʻshiqlarni koʻrish mumkin.',
        action: OutlinedButton(
          onPressed: () => library.setGenreFilter(null),
          child: const Text('Filtrni oʻchirish'),
        ),
      );
    }
    return EmptyState(
      icon: Icons.music_note_rounded,
      title: 'Kutubxona boʻsh',
      message:
          'Telefon xotirasidan mp3 yoki boshqa audio fayllarni qoʻshing. '
          'Internet talab qilinmaydi.',
      action: FilledButton.icon(
        onPressed: () => _import(library),
        icon: const Icon(Icons.folder_open_rounded),
        label: const Text('Fayl tanlash'),
      ),
    );
  }
}

class _ImportProgress extends StatelessWidget {
  const _ImportProgress({required this.library});

  final LibraryController library;

  @override
  Widget build(BuildContext context) {
    final total = library.importTotal;
    final done = library.importDone;
    final value = total <= 0 ? null : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Yuklanmoqda: $done / $total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: value, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

class _GenreFilterBar extends StatelessWidget {
  const _GenreFilterBar({required this.library});

  final LibraryController library;

  @override
  Widget build(BuildContext context) {
    final genres = library.availableGenres;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('Hammasi'),
              selected: library.genreFilter == null,
              onSelected: (_) => library.setGenreFilter(null),
            ),
          ),
          for (final genre in genres)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(genre),
                selected: library.genreFilter == genre,
                onSelected:
                    (selected) =>
                        library.setGenreFilter(selected ? genre : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.songs,
    required this.onPlayAll,
    required this.onShuffleAll,
  });

  final List<Song> songs;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffleAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            onPressed: onShuffleAll,
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Tasodifiy'),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: onPlayAll,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Ijro'),
          ),
        ],
      ),
    );
  }
}
