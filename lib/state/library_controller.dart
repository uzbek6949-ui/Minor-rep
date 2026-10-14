import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../services/metadata_service.dart';
import '../services/storage_service.dart';

enum SongSort { titleAsc, artistAsc, recentlyAdded, durationDesc }

/// Qo'shiqlar va playlistlar kutubxonasi — yuklash, saqlash, qidirish.
class LibraryController extends ChangeNotifier {
  LibraryController({StorageService? storage, MetadataService? metadata})
    : _storage = storage ?? StorageService.instance,
      _metadata = metadata ?? MetadataService.instance;

  static const List<String> supportedExtensions = <String>[
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'opus',
    'aiff',
    'wma',
  ];

  final StorageService _storage;
  final MetadataService _metadata;
  final Uuid _uuid = const Uuid();

  final List<Song> _songs = <Song>[];
  final List<Playlist> _playlists = <Playlist>[];

  bool _loading = true;
  bool _importing = false;
  int _importDone = 0;
  int _importTotal = 0;
  SongSort _sort = SongSort.titleAsc;
  String? _genreFilter;

  bool get isLoading => _loading;
  bool get isImporting => _importing;
  int get importDone => _importDone;
  int get importTotal => _importTotal;
  SongSort get sort => _sort;
  String? get genreFilter => _genreFilter;

  /// Barcha qo'shiqlar — tanlangan tartib va janr filtri bo'yicha.
  List<Song> get songs => _applyView(_songs);

  /// Filtrsiz, xom ro'yxat (playlist ichini to'ldirishda kerak).
  List<Song> get allSongs => List<Song>.unmodifiable(_songs);

  List<Playlist> get playlists {
    final list = List<Playlist>.from(_playlists)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<Song> get favorites =>
      _applyView(_songs.where((song) => song.isFavorite).toList());

  List<String> get availableGenres {
    final genres = <String>{};
    for (final song in _songs) {
      final genre = song.genre.trim();
      if (genre.isNotEmpty) genres.add(genre);
    }
    final list = genres.toList()..sort();
    return list;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    await _storage.init();
    _songs
      ..clear()
      ..addAll(_storage.loadSongs());
    _playlists
      ..clear()
      ..addAll(_storage.loadPlaylists());

    final savedSort = _storage.setting<int>('sort');
    if (savedSort != null &&
        savedSort >= 0 &&
        savedSort < SongSort.values.length) {
      _sort = SongSort.values[savedSort];
    }

    // Yo'qolgan (o'chirilgan) fayllarni kutubxonadan olib tashlaymiz.
    final missing = <Song>[];
    for (final song in _songs) {
      if (!File(song.filePath).existsSync()) missing.add(song);
    }
    for (final song in missing) {
      await _removeSongInternal(song, deleteFiles: false);
    }

    _loading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------- import

  /// Telefon xotirasidan audio fayllarni tanlab, kutubxonaga qo'shadi.
  ///
  /// Fayl ilova papkasiga ko'chiriladi — shunda ilova qayta ishga
  /// tushganda ham yo'l amal qiladi (ayniqsa iOS'da muhim).
  Future<ImportResult> importFromDevice({bool copyIntoApp = true}) async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
      );
    } catch (_) {
      // Ba'zi qurilmalarda `custom` tur ishlamasa — oddiy audio tanlash.
      picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
      );
    }

    if (picked == null || picked.files.isEmpty) {
      return const ImportResult(added: 0, skipped: 0, cancelled: true);
    }

    final paths =
        picked.files
            .map((file) => file.path)
            .whereType<String>()
            .where((path) => path.trim().isNotEmpty)
            .toList();

    return addFiles(paths, copyIntoApp: copyIntoApp);
  }

  /// Berilgan fayl yo'llarini kutubxonaga qo'shadi.
  Future<ImportResult> addFiles(
    List<String> paths, {
    bool copyIntoApp = true,
  }) async {
    if (paths.isEmpty) {
      return const ImportResult(added: 0, skipped: 0);
    }

    _importing = true;
    _importDone = 0;
    _importTotal = paths.length;
    notifyListeners();

    var added = 0;
    var skipped = 0;
    final imported = <Song>[];

    for (final path in paths) {
      try {
        final song = await _addSingleFile(path, copyIntoApp: copyIntoApp);
        if (song == null) {
          skipped++;
        } else {
          imported.add(song);
          added++;
        }
      } catch (_) {
        skipped++;
      }
      _importDone++;
      notifyListeners();
    }

    if (imported.isNotEmpty) {
      _songs.addAll(imported);
      await _storage.saveSongs(imported);
    }

    _importing = false;
    _importTotal = 0;
    _importDone = 0;
    notifyListeners();

    return ImportResult(added: added, skipped: skipped);
  }

  Future<Song?> _addSingleFile(
    String sourcePath, {
    required bool copyIntoApp,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final extension =
        p.extension(sourcePath).replaceFirst('.', '').toLowerCase();
    if (extension.isNotEmpty && !supportedExtensions.contains(extension)) {
      return null;
    }

    final size = await source.length();
    if (_isDuplicate(p.basename(sourcePath), size)) return null;

    final id = _uuid.v4();
    var targetPath = sourcePath;
    if (copyIntoApp) {
      targetPath = await _copyIntoApp(source);
    }

    final meta = await _metadata.extract(targetPath, id);
    return Song(
      id: id,
      filePath: targetPath,
      title: meta.title,
      artist: meta.artist,
      album: meta.album,
      genre: meta.genre,
      durationMs: meta.durationMs,
      artworkPath: meta.artworkPath,
      lyrics: meta.lyrics,
    );
  }

  Future<String> _copyIntoApp(File source) async {
    final dir = await _metadata.musicDirectory();
    var name = p.basename(source.path);
    var target = File(p.join(dir.path, name));
    var counter = 1;
    while (await target.exists()) {
      final base = p.basenameWithoutExtension(name);
      final ext = p.extension(name);
      target = File(p.join(dir.path, '$base ($counter)$ext'));
      counter++;
    }
    await source.copy(target.path);
    return target.path;
  }

  /// Shu fayl kutubxonada bormi (nomi va hajmi bo'yicha).
  bool containsFile(File file) {
    try {
      return _isDuplicate(p.basename(file.path), file.lengthSync());
    } catch (_) {
      return false;
    }
  }

  bool _isDuplicate(String fileName, int size) {
    for (final song in _songs) {
      if (p.basename(song.filePath) != fileName) continue;
      final file = File(song.filePath);
      if (file.existsSync() && file.lengthSync() == size) return true;
    }
    return false;
  }

  // --------------------------------------------------------- qo'shiq amallari

  Song? songById(String id) {
    for (final song in _songs) {
      if (song.id == id) return song;
    }
    return null;
  }

  Future<void> updateSong(
    Song song, {
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? lyrics,
    String? artworkPath,
  }) async {
    if (title != null) song.title = title.trim();
    if (artist != null) song.artist = artist.trim();
    if (album != null) song.album = album.trim();
    if (genre != null) song.genre = genre.trim();
    if (lyrics != null) song.lyrics = lyrics;
    if (artworkPath != null) song.artworkPath = artworkPath;
    await _storage.saveSong(song);
    notifyListeners();
  }

  Future<void> saveLyrics(Song song, String lyrics) =>
      updateSong(song, lyrics: lyrics);

  Future<void> toggleFavorite(Song song) async {
    song.isFavorite = !song.isFavorite;
    await _storage.saveSong(song);
    notifyListeners();
  }

  /// Qo'shiqni albom rasmi bilan ta'minlash — foydalanuvchi rasm tanlaydi.
  Future<bool> pickArtwork(Song song) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    final files = picked?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return false;
    final path = files.first.path;
    if (path == null) return false;
    final saved = await _metadata.importArtworkFile(path, song.id);
    if (saved == null) return false;
    await updateSong(song, artworkPath: saved);
    return true;
  }

  /// Qo'shiqni kutubxonadan o'chirish.
  ///
  /// [deleteFiles] — ilova papkasiga ko'chirilgan audio/rasm fayllari ham
  /// o'chiriladi. Telefon xotirasidagi asl fayl hech qachon o'chirilmaydi.
  Future<void> deleteSong(Song song, {bool deleteFiles = true}) async {
    await _removeSongInternal(song, deleteFiles: deleteFiles);
    notifyListeners();
  }

  Future<void> _removeSongInternal(
    Song song, {
    required bool deleteFiles,
  }) async {
    _songs.removeWhere((item) => item.id == song.id);
    await _storage.deleteSong(song.id);

    for (final playlist in _playlists) {
      if (playlist.songIds.remove(song.id)) {
        await _storage.savePlaylist(playlist);
      }
    }

    if (!deleteFiles) return;

    final artworkPath = song.artworkPath;
    if (artworkPath != null) {
      await _deleteQuietly(artworkPath);
    }
    final musicDir = await _metadata.musicDirectory();
    if (p.isWithin(musicDir.path, song.filePath)) {
      await _deleteQuietly(song.filePath);
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // e'tiborsiz
    }
  }

  // ------------------------------------------------------------- playlistlar

  Future<Playlist> createPlaylist(String name) async {
    final playlist = Playlist(id: _uuid.v4(), name: name.trim());
    _playlists.add(playlist);
    await _storage.savePlaylist(playlist);
    notifyListeners();
    return playlist;
  }

  Playlist? playlistById(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  Future<void> renamePlaylist(Playlist playlist, String name) async {
    playlist.name = name.trim();
    await _storage.savePlaylist(playlist);
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    _playlists.removeWhere((item) => item.id == playlist.id);
    await _storage.deletePlaylist(playlist.id);
    notifyListeners();
  }

  Future<void> addSongToPlaylist(Playlist playlist, Song song) async {
    if (playlist.contains(song.id)) return;
    playlist.songIds.add(song.id);
    await _storage.savePlaylist(playlist);
    notifyListeners();
  }

  Future<void> addSongsToPlaylist(
    Playlist playlist,
    Iterable<Song> songs,
  ) async {
    var changed = false;
    for (final song in songs) {
      if (!playlist.contains(song.id)) {
        playlist.songIds.add(song.id);
        changed = true;
      }
    }
    if (!changed) return;
    await _storage.savePlaylist(playlist);
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(Playlist playlist, String songId) async {
    if (!playlist.songIds.remove(songId)) return;
    await _storage.savePlaylist(playlist);
    notifyListeners();
  }

  Future<void> reorderPlaylist(
    Playlist playlist,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < 0 || oldIndex >= playlist.songIds.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target > playlist.songIds.length - 1) {
      target = playlist.songIds.length - 1;
    }
    final id = playlist.songIds.removeAt(oldIndex);
    playlist.songIds.insert(target, id);
    await _storage.savePlaylist(playlist);
    notifyListeners();
  }

  /// Playlistdagi qo'shiqlar — playlistda saqlangan tartibda.
  List<Song> songsOfPlaylist(Playlist playlist) {
    final result = <Song>[];
    for (final id in playlist.songIds) {
      final song = songById(id);
      if (song != null) result.add(song);
    }
    return result;
  }

  // ---------------------------------------------------------- qidiruv/filtr

  /// Nom, ijrochi, albom yoki janr bo'yicha qidiruv.
  List<Song> search(String query, {String? genre, String? playlistId}) {
    Iterable<Song> source = _songs;

    if (playlistId != null) {
      final playlist = playlistById(playlistId);
      source = playlist == null ? const <Song>[] : songsOfPlaylist(playlist);
    }

    if (genre != null && genre.trim().isNotEmpty) {
      final needle = genre.toLowerCase();
      source = source.where((song) => song.genre.toLowerCase() == needle);
    }

    final terms =
        query
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((term) => term.isNotEmpty)
            .toList();

    if (terms.isNotEmpty) {
      source = source.where((song) {
        final index = song.searchIndex;
        return terms.every(index.contains);
      });
    }

    return _sortList(source.toList());
  }

  Future<void> setSort(SongSort value) async {
    _sort = value;
    await _storage.putSetting('sort', value.index);
    notifyListeners();
  }

  void setGenreFilter(String? genre) {
    _genreFilter = (genre == null || genre.trim().isEmpty) ? null : genre;
    notifyListeners();
  }

  List<Song> _applyView(List<Song> source) {
    final genre = _genreFilter;
    final filtered =
        genre == null
            ? source
            : source
                .where(
                  (song) => song.genre.toLowerCase() == genre.toLowerCase(),
                )
                .toList();
    return _sortList(List<Song>.from(filtered));
  }

  List<Song> _sortList(List<Song> list) {
    switch (_sort) {
      case SongSort.titleAsc:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SongSort.artistAsc:
        list.sort((a, b) {
          final byArtist = a.displayArtist.toLowerCase().compareTo(
            b.displayArtist.toLowerCase(),
          );
          if (byArtist != 0) return byArtist;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
      case SongSort.recentlyAdded:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case SongSort.durationDesc:
        list.sort((a, b) => b.durationMs.compareTo(a.durationMs));
        break;
    }
    return list;
  }
}

class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    this.cancelled = false,
  });

  final int added;
  final int skipped;
  final bool cancelled;
}
