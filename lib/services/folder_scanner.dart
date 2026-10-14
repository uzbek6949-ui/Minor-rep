import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../state/library_controller.dart';

/// Telefon xotirasidagi ma'lum papkalardan audio fayllarni qidiradi.
///
/// Asosiy maqsad: Telegramda yuklab olingan musiqalarni ilovaga qo'shish.
/// Telegram fayllarni bir nechta papkaga saqlaydi (versiyasiga qarab),
/// shuning uchun hammasi tekshiriladi.
class FolderScanner {
  FolderScanner._();

  static final FolderScanner instance = FolderScanner._();

  static const String _root = '/storage/emulated/0';

  /// Qidiriladigan manbalar: nomi -> mumkin bo'lgan yo'llar.
  static const Map<String, List<String>> sources = <String, List<String>>{
    'Telegram': <String>[
      '$_root/Telegram/Telegram Audio',
      '$_root/Telegram/Telegram Documents',
      '$_root/Android/media/org.telegram.messenger/Telegram/Telegram Audio',
      '$_root/Android/media/org.telegram.messenger/Telegram/Telegram Documents',
      '$_root/Android/media/org.telegram.messenger.web/Telegram/Telegram Audio',
      '$_root/Download/Telegram',
    ],
    'Yuklamalar': <String>['$_root/Download', '$_root/Downloads'],
    'Musiqa': <String>['$_root/Music', '$_root/Movies/Music'],
    'WhatsApp': <String>[
      '$_root/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Audio',
    ],
  };

  /// Fayllarni o'qish uchun ruxsat so'raydi.
  ///
  /// Android 13+ da `READ_MEDIA_AUDIO`, undan oldingi versiyalarda
  /// `READ_EXTERNAL_STORAGE` ishlatiladi.
  Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return true;

    final audio = await Permission.audio.request();
    if (audio.isGranted) return true;

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  /// Bitta manba bo'yicha topilgan audio fayllar.
  Future<List<File>> scanSource(String source, {int maxDepth = 2}) async {
    final paths = sources[source] ?? const <String>[];
    final found = <File>[];
    final seen = <String>{};

    for (final path in paths) {
      final dir = Directory(path);
      if (!await dir.exists()) continue;
      await _collect(dir, found, seen, maxDepth);
    }

    found.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return found;
  }

  /// Barcha manbalardan qidiradi.
  Future<Map<String, List<File>>> scanAll({int maxDepth = 2}) async {
    final result = <String, List<File>>{};
    for (final source in sources.keys) {
      final files = await scanSource(source, maxDepth: maxDepth);
      if (files.isNotEmpty) result[source] = files;
    }
    return result;
  }

  Future<void> _collect(
    Directory dir,
    List<File> out,
    Set<String> seen,
    int depth,
  ) async {
    if (depth < 0) return;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final ext =
              p.extension(entity.path).replaceFirst('.', '').toLowerCase();
          if (!LibraryController.supportedExtensions.contains(ext)) continue;
          if (seen.add(entity.path)) out.add(entity);
        } else if (entity is Directory && depth > 0) {
          await _collect(entity, out, seen, depth - 1);
        }
      }
    } on FileSystemException {
      // Ruxsat berilmagan papkani jimgina o'tkazib yuboramiz.
    }
  }
}
