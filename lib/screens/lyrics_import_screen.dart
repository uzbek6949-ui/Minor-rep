import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/album_art.dart';
import '../widgets/empty_state.dart';

/// Boshqa ilovadan "Ulashish" orqali kelgan matnni qo'shiqqa biriktiradi.
///
/// Matnning birinchi qatori qo'shiq nomiga o'xshasa — o'sha qo'shiq
/// avtomatik taklif qilinadi, foydalanuvchi faqat tasdiqlaydi.
class LyricsImportScreen extends StatefulWidget {
  const LyricsImportScreen({super.key, required this.text});

  final String text;

  static Route<void> route(String text) =>
      MaterialPageRoute<void>(builder: (_) => LyricsImportScreen(text: text));

  @override
  State<LyricsImportScreen> createState() => _LyricsImportScreenState();
}

class _LyricsImportScreenState extends State<LyricsImportScreen> {
  final TextEditingController _search = TextEditingController();
  String? _selectedId;
  String _query = '';
  bool _matched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guess());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Matndan qo'shiqni topishga urinish.
  void _guess() {
    final songs = context.read<LibraryController>().allSongs;
    if (songs.isEmpty) return;

    final lines =
        widget.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .take(3)
            .map(_normalize)
            .toList();
    if (lines.isEmpty) return;

    Song? found;
    for (final song in songs) {
      final title = _normalize(song.title);
      if (title.isEmpty) continue;
      for (final line in lines) {
        // Birinchi qatorlar nomga teng yoki nomni o'z ichiga olsa.
        if (line == title || line.contains(title) || title.contains(line)) {
          found = song;
          break;
        }
      }
      if (found != null) break;
    }

    if (found != null && mounted) {
      setState(() {
        _selectedId = found!.id;
        _matched = true;
      });
    }
  }

  static String _normalize(String value) =>
      value
          .toLowerCase()
          .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  Future<void> _save(Song song) async {
    await context.read<LibraryController>().saveLyrics(song, widget.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${song.title}" uchun matn saqlandi')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final scheme = Theme.of(context).colorScheme;

    final needle = _query.trim().toLowerCase();
    final songs =
        needle.isEmpty
            ? library.allSongs
            : library.allSongs
                .where((song) => song.searchIndex.contains(needle))
                .toList();

    final selected =
        _selectedId == null ? null : library.songById(_selectedId!);

    return Scaffold(
      appBar: AppBar(title: const Text('Matnni qo’shish')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: selected == null ? null : () => _save(selected),
            icon: const Icon(Icons.save_rounded, size: 20),
            label: Text(
              selected == null
                  ? 'Qo’shiqni tanlang'
                  : '"${selected.title}" ga saqlash',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body:
          library.allSongs.isEmpty
              ? const EmptyState(
                icon: Icons.music_off_rounded,
                title: 'Kutubxona bo’sh',
                message:
                    'Avval qo’shiq qo’shing, keyin matnni '
                    'unga biriktirasiz.',
              )
              : Column(
                children: <Widget>[
                  _TextPreview(text: widget.text),
                  if (_matched && selected != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Matndan topildi: ${selected.title}',
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        hintText: 'Qo’shiqni qidirish...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        final isSelected = song.id == _selectedId;
                        return ListTile(
                          leading: AlbumArt(song: song, size: 44, radius: 12),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            song.hasLyrics
                                ? '${song.displayArtist} • matn bor '
                                    '(almashtiriladi)'
                                : song.displayArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_circle_rounded,
                                    color: scheme.onSurface,
                                  )
                                  : null,
                          onTap:
                              () => setState(() {
                                _selectedId = song.id;
                                _matched = false;
                              }),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Kelgan matn • ${lines.length} qator',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            lines.take(4).join('\n'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  }
}
