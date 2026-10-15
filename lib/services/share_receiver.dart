import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../state/library_controller.dart';

/// Boshqa ilovalardan ("Ulashish" tugmasi orqali) kelgan narsalarni qabul
/// qiladi: audio fayllar va matn (qo'shiq so'zlari).
class ShareReceiver {
  ShareReceiver._();

  static final ShareReceiver instance = ShareReceiver._();

  StreamSubscription<List<SharedMediaFile>>? _subscription;
  bool _started = false;

  /// [onFiles] — kelgan audio fayllar yo'li.
  /// [onText] — kelgan matn (masalan Telegramdan nusxalangan qo'shiq so'zlari).
  void start(
    Future<void> Function(List<String> paths) onFiles, {
    Future<void> Function(String text)? onText,
  }) {
    if (_started) return;
    _started = true;

    // Ilova ochiq turganda kelgan narsalar.
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (items) => _handle(items, onFiles, onText),
      onError: (Object _) {},
    );

    // Ilova "Ulashish" orqali yopiq holatdan ochilgan bo'lsa.
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((items) async {
          await _handle(items, onFiles, onText);
          // Bir marta ishlatilgandan keyin tozalaymiz, aks holda ilova qayta
          // ochilganda o'sha narsa yana qo'shilishga urinadi.
          ReceiveSharingIntent.instance.reset();
        })
        .catchError((Object _) {});
  }

  Future<void> _handle(
    List<SharedMediaFile> items,
    Future<void> Function(List<String> paths) onFiles,
    Future<void> Function(String text)? onText,
  ) async {
    final paths = <String>[];
    final texts = <String>[];

    for (final item in items) {
      final isText =
          item.type == SharedMediaType.text || item.type == SharedMediaType.url;

      if (isText) {
        // Matn `message` yoki `path` maydonida kelishi mumkin.
        final value =
            (item.message?.trim().isNotEmpty ?? false)
                ? item.message!
                : item.path;
        if (value.trim().isNotEmpty) texts.add(value);
        continue;
      }

      if (item.path.trim().isEmpty) continue;
      final extension =
          p.extension(item.path).replaceFirst('.', '').toLowerCase();
      if (LibraryController.supportedExtensions.contains(extension)) {
        paths.add(item.path);
      }
    }

    if (paths.isNotEmpty) await onFiles(paths);
    if (texts.isNotEmpty && onText != null) await onText(texts.join('\n\n'));
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
