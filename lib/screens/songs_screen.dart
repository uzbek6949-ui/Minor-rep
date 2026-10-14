import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    final message = result.added == 0
        ? 'Yangi qo’shiq qo’shilmadi'
        : '${result.added} ta qo’shiq qo’shildi'
            '${result.skipped > 0 ? ' (${result.skipped} ta o’tkazib yuborildi)' : ''}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final playerController = context.read<PlayerController>();
    final songs = _onlyFavorites ? library.favorites : library.songs;
    final label = _onlyFavorites ? 'Sevimlilar' : 'Barcha qo’shiqlar';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Minor Rep'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sevimlilar',
            onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
            icon: Icon(
              _onlyFavorites ? Icons.favorite : Icons.favorite_border_rounded,
            ),
          ),
          PopupMenuButton<SongSort>(
            tooltip: 'Tartiblash',
            icon: const Icon(Icons.swap_vert_rounded),
            initialValue: library.sort,
            onSelected: library.setSort,
            itemBuilder: (context) => const <PopupMenuEntry<SongSort>>[
              PopupMenuItem<SongSort>(
                value: SongSort.titleAsc,
                child: Text('Nomi bo’yicha'),
              ),
              PopupMenuItem<SongSort>(
                value: SongSort.artistAsc,
                child: Text('Ijrochisi bo’yicha'),
              ),
              PopupMenuItem<SongSort>(
                value: SongSort.recentlyAdded,
                child: Text('Yangi qo’shilganlar'),
              ),
              PopupMenuItem<SongSort>(
                value: SongSort.durationDesc,
                child: Text('Davomiyligi bo’yicha'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Qo’shiq qo’shish',
            onPressed: library.isImporting ? null : () => _import(library),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: library.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                if (library.isImporting) _ImportProgress(library: library),
                if (songs.isNotEmpty)
                  _ActionsHeader(
                    count: songs.length,
                    onPlay: () => playerController.playQueue(
                      songs,
                      label: label,
                      sourceId: 'all',
                    ),
                    onShuffle: () async {
                      await playerController.playQueue(
                        songs,
                        label: label,
                        sourceId: 'all',
                      );
                      if (!playerController.shuffleEnabled) {
                        await playerController.toggleShuffle();
                      }
                    },
                  ),
                if (library.availableGenres.isNotEmpty && songs.isNotEmpty)
                  _GenreFilterBar(library: library),
                Expanded(
                  child: songs.isEmpty
                      ? _emptyState(library)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
                          itemCount: songs.length,
                          itemBuilder: (context, index) => SongTile(
                            song: songs[index],
                            queue: songs,
                            queueLabel: label,
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
        title: 'Sevimli qo’shiqlar yo’q',
        message: 'Qo’shiq menyusidan "Sevimlilarga qo’shish"ni tanlang.',
      );
    }
    if (library.genreFilter != null) {
      return EmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'Bu janrda qo’shiq yo’q',
        message: 'Filtrni o’chirib, barcha qo’shiqlarni ko’rish mumkin.',
        action: OutlinedButton(
          onPressed: () => library.setGenreFilter(null),
          child: const Text('Filtrni o’chirish'),
        ),
      );
    }
    return EmptyState(
      icon: Icons.music_note_rounded,
      title: 'Kutubxona bo’sh',
      message: 'Telefon xotirasidan mp3 yoki boshqa audio fayllarni qo’shing. '
          'Internet talab qilinmaydi.',
      action: FilledButton.icon(
        onPressed: () => _import(library),
        icon: const Icon(Icons.folder_open_rounded, size: 20),
        label: const Text('Fayl tanlash'),
      ),
    );
  }
}

/// Dizayndagi kabi: qora "Ijro" va och "Tasodifiy" tugmalari.
class _ActionsHeader extends StatelessWidget {
  const _ActionsHeader({
    required this.count,
    required this.onPlay,
    required this.onShuffle,
  });

  final int count;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            songCountLabel(count),
            style: TextStyle(
              fontSize: 13.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 21),
                  label: const Text('Ijro'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShuffle,
                  icon: const Icon(Icons.shuffle_rounded, size: 19),
                  label: const Text('Tasodifiy'),
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Yuklanmoqda: $done / $total',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
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
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: FilterChip(
              label: const Text('Hammasi'),
              selected: library.genreFilter == null,
              onSelected: (_) => library.setGenreFilter(null),
              labelStyle: _labelStyle(context, library.genreFilter == null),
            ),
          ),
          for (final genre in genres)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: FilterChip(
                label: Text(genre),
                selected: library.genreFilter == genre,
                onSelected: (selected) =>
                    library.setGenreFilter(selected ? genre : null),
                labelStyle: _labelStyle(context, library.genreFilter == genre),
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context, bool selected) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: selected ? scheme.onPrimary : scheme.onSurface,
    );
  }
}
