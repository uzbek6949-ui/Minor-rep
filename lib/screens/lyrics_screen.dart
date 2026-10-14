import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_controller.dart';
import '../widgets/empty_state.dart';

/// Qo'shiq so'zlari: ko'rish va tahrirlash.
///
/// Matn qo'lda yoziladi va darhol lokal bazaga saqlanadi — keyinchalik
/// istalgan vaqtda to'ldirish mumkin.
class LyricsScreen extends StatefulWidget {
  const LyricsScreen({
    super.key,
    required this.songId,
    this.startInEditMode = false,
  });

  final String songId;
  final bool startInEditMode;

  static Route<void> route(Song song, {bool edit = false}) =>
      MaterialPageRoute<void>(
        builder: (_) => LyricsScreen(songId: song.id, startInEditMode: edit),
      );

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  late final TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final song = context.read<LibraryController>().songById(widget.songId);
    _controller = TextEditingController(text: song?.lyrics ?? '');
    _editing = widget.startInEditMode || !(song?.hasLyrics ?? false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(Song song) async {
    await context.read<LibraryController>().saveLyrics(song, _controller.text);
    if (!mounted) return;
    setState(() => _editing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Matn saqlandi')));
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
          title: 'Qoʻshiq topilmadi',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              song.displayArtist,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: <Widget>[
          if (_editing)
            IconButton(
              tooltip: 'Saqlash',
              onPressed: () => _save(song),
              icon: const Icon(Icons.check_rounded),
            )
          else
            IconButton(
              tooltip: 'Tahrirlash',
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child:
              _editing
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            hintText:
                                'Qoʻshiq soʻzlarini shu yerga '
                                'yozing yoki qoʻyib (paste) qoʻying...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _controller.text = song.lyrics ?? '';
                                setState(() => _editing = false);
                              },
                              child: const Text('Bekor qilish'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _save(song),
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Saqlash'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  : song.hasLyrics
                  ? SingleChildScrollView(
                    child: SelectableText(
                      song.lyrics!.trim(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  )
                  : EmptyState(
                    icon: Icons.lyrics_rounded,
                    title: 'Matn hali yoʻq',
                    message:
                        'Qoʻshiq soʻzlarini qoʻlda '
                        'yozib qoʻyishingiz mumkin.',
                    action: FilledButton.icon(
                      onPressed: () => setState(() => _editing = true),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Matn qoʻshish'),
                    ),
                  ),
        ),
      ),
    );
  }
}
