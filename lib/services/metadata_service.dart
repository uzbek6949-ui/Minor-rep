import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'id3_reader.dart';

/// Audio fayldan nom, ijrochi, albom rasmi va davomiylikni aniqlaydi.
class MetadataService {
  MetadataService._();

  static final MetadataService instance = MetadataService._();

  Directory? _artworkDir;

  /// Albom rasmlari saqlanadigan ilova papkasi.
  Future<Directory> artworkDirectory() async {
    final cached = _artworkDir;
    if (cached != null) return cached;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'artwork'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _artworkDir = dir;
    return dir;
  }

  /// Ilova ichida saqlanadigan audio fayllar papkasi (import qilinganda).
  Future<Directory> musicDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'music'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Faylni o'qib, [ExtractedMetadata] qaytaradi.
  ///
  /// [songId] — albom rasmini saqlash uchun fayl nomi sifatida ishlatiladi.
  Future<ExtractedMetadata> extract(String filePath, String songId) async {
    final file = File(filePath);
    final tags = await Id3Reader.read(file);

    String? artworkPath;
    final artwork = tags.artwork;
    if (artwork != null && artwork.isNotEmpty) {
      artworkPath = await saveArtwork(artwork, songId, tags.artworkExtension);
    }

    var durationMs = tags.durationMs ?? 0;
    if (durationMs <= 0) {
      durationMs = await _probeDuration(filePath);
    }

    return ExtractedMetadata(
      title: tags.title ?? _titleFromFileName(filePath),
      artist: tags.artist ?? '',
      album: tags.album ?? '',
      genre: tags.genre ?? '',
      lyrics: tags.lyrics,
      durationMs: durationMs,
      artworkPath: artworkPath,
    );
  }

  /// Rasm baytlarini ilova papkasiga saqlab, yo'lini qaytaradi.
  Future<String?> saveArtwork(
    Uint8List bytes,
    String songId,
    String? extension,
  ) async {
    try {
      final dir = await artworkDirectory();
      final file = File(p.join(dir.path, '$songId.${extension ?? 'jpg'}'));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Tashqi rasm faylini (foydalanuvchi tanlagan) ilova papkasiga ko'chiradi.
  Future<String?> importArtworkFile(String sourcePath, String songId) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final extension = p.extension(sourcePath).replaceFirst('.', '');
      return saveArtwork(
        bytes,
        songId,
        extension.isEmpty ? 'jpg' : extension.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Teglarda davomiylik bo'lmasa — pleer orqali aniqlaymiz.
  Future<int> _probeDuration(String filePath) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(filePath);
      return duration?.inMilliseconds ?? 0;
    } catch (_) {
      return 0;
    } finally {
      await player.dispose();
    }
  }

  static String _titleFromFileName(String filePath) {
    final name = p.basenameWithoutExtension(filePath).trim();
    return name.isEmpty ? 'Nomsiz qo’shiq' : name;
  }
}

class ExtractedMetadata {
  ExtractedMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.durationMs,
    this.lyrics,
    this.artworkPath,
  });

  final String title;
  final String artist;
  final String album;
  final String genre;
  final int durationMs;
  final String? lyrics;
  final String? artworkPath;
}
