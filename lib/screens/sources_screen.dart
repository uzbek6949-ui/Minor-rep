import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../services/folder_scanner.dart';
import '../state/library_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

/// "Manbalar" ekrani — Telegram, Yuklamalar, Musiqa papkalaridan
/// yangi qo'shiqlarni topib, kutubxonaga qo'shadi.
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const SourcesScreen());

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final Map<String, List<File>> _found = <String, List<File>>{};
  final Set<String> _selected = <String>{};
  bool _scanning = false;
  bool _scanned = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _permissionDenied = false;
    });

    final granted = await FolderScanner.instance.ensurePermission();
    if (!mounted) return;
    if (!granted) {
      setState(() {
        _scanning = false;
        _scanned = true;
        _permissionDenied = true;
      });
      return;
    }

    final library = context.read<LibraryController>();
    final result = await FolderScanner.instance.scanAll();
    if (!mounted) return;

    // Kutubxonada bor fayllarni ro'yxatdan chiqarib tashlaymiz.
    final fresh = <String, List<File>>{};
    for (final entry in result.entries) {
      final newFiles =
          entry.value.where((file) => !library.containsFile(file)).toList();
      if (newFiles.isNotEmpty) fresh[entry.key] = newFiles;
    }

    setState(() {
      _found
        ..clear()
        ..addAll(fresh);
      _selected
        ..clear()
        ..addAll(fresh.values.expand((files) => files.map((f) => f.path)));
      _scanning = false;
      _scanned = true;
    });
  }

  Future<void> _import() async {
    final library = context.read<LibraryController>();
    final paths = _selected.toList();
    if (paths.isEmpty) return;

    final result = await library.addFiles(paths);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.added == 0
              ? 'Yangi qo’shiq qo’shilmadi'
              : '${result.added} ta qo’shiq qo’shildi',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _found.values.fold<int>(
      0,
      (sum, files) => sum + files.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manbalardan qidirish'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Qayta qidirish',
            onPressed: _scanning ? null : _scan,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar:
          total == 0
              ? null
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton.icon(
                    onPressed: _selected.isEmpty ? null : _import,
                    icon: const Icon(Icons.library_add_rounded, size: 20),
                    label: Text(
                      _selected.isEmpty
                          ? 'Hech narsa tanlanmagan'
                          : '${_selected.length} ta qo’shiqni qo’shish',
                    ),
                  ),
                ),
              ),
      body:
          _scanning
              ? const Center(child: CircularProgressIndicator())
              : _permissionDenied
              ? EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Ruxsat berilmadi',
                message:
                    'Telegram va Yuklamalar papkalarini ko’rish uchun '
                    'ilovaga "Musiqa va audio" ruxsatini bering.',
                action: FilledButton(
                  onPressed: _scan,
                  child: const Text('Qayta so’rash'),
                ),
              )
              : !_scanned || total == 0
              ? EmptyState(
                icon: Icons.folder_open_rounded,
                title: 'Yangi qo’shiq topilmadi',
                message:
                    'Telegram, Yuklamalar va Musiqa papkalari '
                    'tekshirildi — hammasi allaqachon kutubxonada.\n\n'
                    'Telegramda musiqani yuklab olib (strelka tugmasi), '
                    'keyin shu yerni yangilang.',
                action: OutlinedButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  label: const Text('Qayta qidirish'),
                ),
              )
              : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      '$total ta yangi audio fayl topildi',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final entry in _found.entries)
                    _SourceGroup(
                      name: entry.key,
                      files: entry.value,
                      selected: _selected,
                      onToggle:
                          (path, value) => setState(() {
                            if (value) {
                              _selected.add(path);
                            } else {
                              _selected.remove(path);
                            }
                          }),
                      onToggleAll:
                          (value) => setState(() {
                            for (final file in entry.value) {
                              if (value) {
                                _selected.add(file.path);
                              } else {
                                _selected.remove(file.path);
                              }
                            }
                          }),
                    ),
                ],
              ),
    );
  }
}

class _SourceGroup extends StatelessWidget {
  const _SourceGroup({
    required this.name,
    required this.files,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
  });

  final String name;
  final List<File> files;
  final Set<String> selected;
  final void Function(String path, bool value) onToggle;
  final void Function(bool value) onToggleAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allSelected = files.every((file) => selected.contains(file.path));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: scheme.outline),
        ),
        child: Column(
          children: <Widget>[
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              leading: Icon(
                name == 'Telegram'
                    ? Icons.send_rounded
                    : name == 'Musiqa'
                    ? Icons.library_music_rounded
                    : Icons.folder_rounded,
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(songCountLabel(files.length)),
              trailing: TextButton(
                onPressed: () => onToggleAll(!allSelected),
                child: Text(allSelected ? 'Bekor qilish' : 'Hammasi'),
              ),
            ),
            const Divider(height: 1),
            for (final file in files.take(40))
              CheckboxListTile(
                dense: true,
                value: selected.contains(file.path),
                onChanged: (value) => onToggle(file.path, value ?? false),
                title: Text(
                  p.basenameWithoutExtension(file.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(_size(file)),
              ),
            if (files.length > 40)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'va yana ${files.length - 40} ta fayl '
                  '(hammasi "Hammasi" tugmasi bilan tanlanadi)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _size(File file) {
    try {
      final mb = file.lengthSync() / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }
}
