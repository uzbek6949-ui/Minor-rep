import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../services/folder_scanner.dart';
import '../state/library_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

/// Telefon papkalaridan yangi qo'shiqlarni topib, kutubxonaga qo'shadi.
///
/// [onlyFolder] berilsa — faqat o'sha papka tekshiriladi ("Minor" kabi
/// asosiy papkani bir bosishda ochish uchun).
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key, this.onlyFolder});

  final String? onlyFolder;

  static Route<void> route({String? onlyFolder}) => MaterialPageRoute<void>(
    builder: (_) => SourcesScreen(onlyFolder: onlyFolder),
  );

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final Map<String, List<File>> _found = <String, List<File>>{};
  final Set<String> _selected = <String>{};
  final TextEditingController _search = TextEditingController();

  String _query = '';
  bool _scanning = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _permissionDenied = false;
    });

    final scanner = FolderScanner.instance;
    final granted = await scanner.ensurePermission();
    if (!mounted) return;
    if (!granted) {
      setState(() {
        _scanning = false;
        _permissionDenied = true;
      });
      return;
    }

    final library = context.read<LibraryController>();
    final result = <String, List<File>>{};

    if (widget.onlyFolder != null) {
      result[p.basename(widget.onlyFolder!)] = await scanner.scanFolder(
        widget.onlyFolder!,
      );
    } else {
      // Birinchi marta: "Minor" kabi papkalarni o'zi topib qo'shadi.
      if (scanner.customFolders.isEmpty) {
        for (final path in await scanner.autoDetectFolders()) {
          await scanner.addCustomFolder(path);
          if (scanner.mainFolder == null) {
            await scanner.setMainFolder(path);
          }
        }
      }
      result.addAll(await scanner.scanAll());
    }
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
    });
  }

  /// Qidiruv so'zi bo'yicha filtrlangan natijalar.
  Map<String, List<File>> get _visible {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _found;

    final filtered = <String, List<File>>{};
    for (final entry in _found.entries) {
      final matches =
          entry.value
              .where(
                (file) => p.basename(file.path).toLowerCase().contains(needle),
              )
              .toList();
      if (matches.isNotEmpty) filtered[entry.key] = matches;
    }
    return filtered;
  }

  Future<void> _addFolder() async {
    final scanner = FolderScanner.instance;
    final granted = await scanner.ensurePermission();
    if (!mounted || !granted) return;

    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Qo’shiqlar turgan papkani tanlang',
    );
    if (path == null || !mounted) return;

    await scanner.addCustomFolder(path);
    if (scanner.mainFolder == null) await scanner.setMainFolder(path);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Papka qo’shildi: ${p.basename(path)}')),
    );
    await _scan();
  }

  /// Guruh nomi qaysi qo'lda qo'shilgan papkaga tegishli ekanini topadi.
  String? _folderFor(String groupName) {
    for (final path in FolderScanner.instance.customFolders) {
      if (groupName.startsWith(p.basename(path))) return path;
    }
    if (widget.onlyFolder != null &&
        groupName == p.basename(widget.onlyFolder!)) {
      return widget.onlyFolder;
    }
    return null;
  }

  Future<void> _folderAction(String path, String action) async {
    final scanner = FolderScanner.instance;
    if (action == 'main') {
      await scanner.setMainFolder(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${p.basename(path)}" asosiy papka qilib belgilandi'),
        ),
      );
      setState(() {});
      return;
    }
    if (action == 'remove') {
      await scanner.removeCustomFolder(path);
      if (!mounted) return;
      await _scan();
    }
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
    final visible = _visible;
    final shown = visible.values.fold<int>(
      0,
      (sum, files) => sum + files.length,
    );
    final total = _found.values.fold<int>(
      0,
      (sum, files) => sum + files.length,
    );
    final selectedVisible =
        visible.values
            .expand((files) => files)
            .where((file) => _selected.contains(file.path))
            .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.onlyFolder == null
              ? 'Manbalardan qidirish'
              : p.basename(widget.onlyFolder!),
        ),
        actions: <Widget>[
          if (widget.onlyFolder == null)
            IconButton(
              tooltip: 'Papka qo’shish',
              onPressed: _scanning ? null : _addFolder,
              icon: const Icon(Icons.create_new_folder_outlined),
            ),
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
                    'Papkalarni ko’rish uchun ilovaga "Musiqa va audio" '
                    'ruxsatini bering.',
                action: FilledButton(
                  onPressed: _scan,
                  child: const Text('Qayta so’rash'),
                ),
              )
              : total == 0
              ? _emptyResult()
              : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'Fayl nomi bo’yicha qidirish...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon:
                            _query.isEmpty
                                ? null
                                : IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 12, 2),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _query.isEmpty
                                ? '$total ta yangi fayl • $selectedVisible tanlandi'
                                : '$shown ta topildi • $selectedVisible tanlandi',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => setState(() {
                                final paths = visible.values.expand(
                                  (files) => files.map((f) => f.path),
                                );
                                if (selectedVisible == shown) {
                                  _selected.removeAll(paths);
                                } else {
                                  _selected.addAll(paths);
                                }
                              }),
                          child: Text(
                            selectedVisible == shown
                                ? 'Belgilashni olish'
                                : 'Hammasini belgilash',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        shown == 0
                            ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Bunday fayl topilmadi',
                              message: 'Boshqa so’z bilan qidirib ko’ring.',
                            )
                            : ListView(
                              padding: const EdgeInsets.only(bottom: 24),
                              children: <Widget>[
                                for (final entry in visible.entries)
                                  _SourceGroup(
                                    name: entry.key,
                                    files: entry.value,
                                    folderPath: _folderFor(entry.key),
                                    isMain:
                                        _folderFor(entry.key) != null &&
                                        _folderFor(entry.key) ==
                                            FolderScanner.instance.mainFolder,
                                    onFolderAction: _folderAction,
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
                  ),
                ],
              ),
    );
  }

  Widget _emptyResult() {
    return EmptyState(
      icon: Icons.folder_open_rounded,
      title: 'Yangi qo’shiq topilmadi',
      message:
          widget.onlyFolder == null
              ? 'Telegram, Yuklamalar va Musiqa papkalari tekshirildi — '
                  'hammasi allaqachon kutubxonada.\n\nQo’shiqlaringiz '
                  'boshqa papkada bo’lsa, uni qo’shib qo’ying.'
              : 'Bu papkada yangi audio fayl yo’q.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.onlyFolder == null)
            FilledButton.icon(
              onPressed: _addFolder,
              icon: const Icon(Icons.create_new_folder_outlined, size: 19),
              label: const Text('Papka qo’shish'),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('Qayta qidirish'),
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
    this.folderPath,
    this.isMain = false,
    this.onFolderAction,
  });

  final String name;
  final List<File> files;

  /// Qo'lda qo'shilgan papka bo'lsa — uning yo'li (boshqarish uchun).
  final String? folderPath;
  final bool isMain;
  final Future<void> Function(String path, String action)? onFolderAction;

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
              leading: Icon(
                name == 'Telegram'
                    ? Icons.send_rounded
                    : name == 'Musiqa'
                    ? Icons.library_music_rounded
                    : Icons.folder_rounded,
              ),
              title: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isMain)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.star_rounded,
                        size: 17,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              subtitle: Text(songCountLabel(files.length)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton(
                    onPressed: () => onToggleAll(!allSelected),
                    child: Text(allSelected ? 'Bekor qilish' : 'Hammasi'),
                  ),
                  if (folderPath != null && onFolderAction != null)
                    PopupMenuButton<String>(
                      tooltip: 'Papka amallari',
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onSelected:
                          (action) => onFolderAction!(folderPath!, action),
                      itemBuilder:
                          (context) => <PopupMenuEntry<String>>[
                            if (!isMain)
                              const PopupMenuItem<String>(
                                value: 'main',
                                child: ListTile(
                                  leading: Icon(Icons.star_outline_rounded),
                                  title: Text('Asosiy papka qilish'),
                                ),
                              ),
                            const PopupMenuItem<String>(
                              value: 'remove',
                              child: ListTile(
                                leading: Icon(Icons.playlist_remove_rounded),
                                title: Text('Ro\u2019yxatdan olib tashlash'),
                              ),
                            ),
                          ],
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final file in files.take(60))
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
            if (files.length > 60)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'va yana ${files.length - 60} ta fayl '
                  '("Hammasi" tugmasi ularni ham belgilaydi)',
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
