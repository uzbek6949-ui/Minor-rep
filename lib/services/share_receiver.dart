import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../state/library_controller.dart';

/// Boshqa ilovalardan ("Ulashish" tugmasi orqali) kelgan audio fayllarni
/// qabul qiladi — masalan Telegramdagi qo'shiqni Minor Rep'ga yuborish.
class ShareReceiver {
  ShareReceiver._();

  static final ShareReceiver instance = ShareReceiver._();

  StreamSubscription<List<SharedMediaFile>>? _subscription;
  bool _started = false;

  /// [onFiles] — qabul qilingan fayl yo'llari (audio bo'lmaganlari olib tashlangan).
  void start(Future<void> Function(List<String> paths) onFiles) {
    if (_started) return;
    _started = true;

    // Ilova ochiq turganda kelgan fayllar.
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _handle(files, onFiles),
      onError: (Object _) {},
    );

    // Ilova "Ulashish" orqali yopiq holatdan ochilgan bo'lsa.
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((files) async {
          await _handle(files, onFiles);
          // Bir marta ishlatilgandan keyin tozalaymiz, aks holda qayta ochilganda
          // o'sha fayl yana qo'shilishga urinadi.
          ReceiveSharingIntent.instance.reset();
        })
        .catchError((Object _) {});
  }

  Future<void> _handle(
    List<SharedMediaFile> files,
    Future<void> Function(List<String> paths) onFiles,
  ) async {
    final paths =
        files
            .map((file) => file.path)
            .where((path) => path.trim().isNotEmpty)
            .where((path) {
              final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
              return LibraryController.supportedExtensions.contains(ext);
            })
            .toList();
    if (paths.isEmpty) return;
    await onFiles(paths);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
