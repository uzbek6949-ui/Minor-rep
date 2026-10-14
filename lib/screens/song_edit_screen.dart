import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_controller.dart';
import '../utils/formatters.dart';
import '../widgets/album_art.dart';
import '../widgets/empty_state.dart';

/// Qo'shiq ma'lumotlarini tahrirlash: nomi, ijrochisi, albomi, janri, rasmi.
class SongEditScreen extends StatefulWidget {
  const SongEditScreen({super.key, required this.songId});

  final String songId;

  static Route<void> route(Song song) =>
      MaterialPageRoute<void>(builder: (_) => SongEditScreen(songId: song.id));

  @override
  State<SongEditScreen> createState() => _SongEditScreenState();
}

class _SongEditScreenState extends State<SongEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _album;
  late final TextEditingController _genre;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final song = context.read<LibraryController>().songById(widget.songId);
    _title = TextEditingController(text: song?.title ?? '');
    _artist = TextEditingController(text: song?.artist ?? '');
    _album = TextEditingController(text: song?.album ?? '');
    _genre = TextEditingController(text: song?.genre ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _genre.dispose();
    super.dispose();
  }

  Future<void> _save(Song song) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await context.read<LibraryController>().updateSong(
      song,
      title: _title.text,
      artist: _artist.text,
      album: _album.text,
      genre: _genre.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final song = library.songById(widget.songId);

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Qo’shiq topilmadi',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tahrirlash')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    AlbumArt(song: song, size: 160, radius: 20),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final changed = await library.pickArtwork(song);
                        if (!context.mounted) return;
                        if (!changed) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Albom rasmi yangilandi'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('Albom rasmini tanlash'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nomi'),
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Nomi bo’sh bo’lmasligi kerak'
                            : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _artist,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Ijrochi'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _album,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Albom'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _genre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Janr',
                  helperText: 'Filtrlash uchun ishlatiladi',
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Fayl ma’lumoti',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Davomiyligi: ${formatDuration(song.duration)}'),
                      const SizedBox(height: 4),
                      Text(
                        song.filePath,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(song),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
