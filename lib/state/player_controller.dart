import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

import '../models/song.dart';

/// Progress bar uchun bitta oqimga jamlangan holat.
class PositionData {
  const PositionData({
    required this.position,
    required this.buffered,
    required this.duration,
  });

  final Duration position;
  final Duration buffered;
  final Duration duration;

  static const PositionData zero = PositionData(
    position: Duration.zero,
    buffered: Duration.zero,
    duration: Duration.zero,
  );
}

/// Pleer: play/pause, keyingi/oldingi, shuffle, repeat, progress.
///
/// Fon rejimi `just_audio_background` orqali ta'minlanadi — ekran
/// o'chirilganda ham musiqa davom etadi va bildirishnoma orqali boshqariladi.
class PlayerController extends ChangeNotifier {
  PlayerController() {
    _attachListeners();
  }

  final AudioPlayer _player = AudioPlayer();

  List<Song> _queue = <Song>[];
  String _queueLabel = '';
  String? _queueSourceId;

  AudioPlayer get player => _player;
  List<Song> get queue => List<Song>.unmodifiable(_queue);
  String get queueLabel => _queueLabel;
  String? get queueSourceId => _queueSourceId;

  int? get currentIndex => _player.currentIndex;

  Song? get currentSong {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _queue.length) return null;
    return _queue[index];
  }

  bool get hasQueue => _queue.isNotEmpty;
  bool get isPlaying => _player.playing;
  bool get shuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, buffered, duration) => PositionData(
          position: position,
          buffered: buffered,
          duration: duration ?? Duration.zero,
        ),
      );

  void _attachListeners() {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((_) => notifyListeners());
    _player.shuffleModeEnabledStream.listen((_) => notifyListeners());
    _player.loopModeStream.listen((_) => notifyListeners());
    _player.sequenceStateStream.listen((_) => notifyListeners());
  }

  // ------------------------------------------------------------ navbat (queue)

  /// Qo'shiqlar ro'yxatini navbatga qo'yib, [startIndex]dan boshlab ijro etadi.
  Future<void> playQueue(
    List<Song> songs, {
    int startIndex = 0,
    String label = '',
    String? sourceId,
  }) async {
    if (songs.isEmpty) return;

    var index = startIndex;
    if (index < 0 || index >= songs.length) index = 0;

    _queue = List<Song>.from(songs);
    _queueLabel = label;
    _queueSourceId = sourceId;
    notifyListeners();

    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: _queue.map(_toAudioSource).toList()),
        initialIndex: index,
        initialPosition: Duration.zero,
      );
      await _player.play();
    } catch (_) {
      // Fayl o'qilmasa — ijro boshlanmaydi, lekin ilova yiqilmaydi.
    }
  }

  /// Bitta qo'shiqni ijro etish (navbat sifatida butun ro'yxat saqlanadi).
  Future<void> playSong(
    Song song, {
    List<Song>? inList,
    String label = '',
    String? sourceId,
  }) {
    final list = (inList == null || inList.isEmpty) ? <Song>[song] : inList;
    final index = list.indexWhere((item) => item.id == song.id);
    return playQueue(
      list,
      startIndex: index < 0 ? 0 : index,
      label: label,
      sourceId: sourceId,
    );
  }

  AudioSource _toAudioSource(Song song) {
    final artworkPath = song.artworkPath;
    return AudioSource.uri(
      Uri.file(song.filePath),
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.displayArtist,
        album: song.album.trim().isEmpty ? 'Minor Rep' : song.album,
        duration: song.durationMs > 0 ? song.duration : null,
        artUri: artworkPath == null ? null : Uri.file(artworkPath),
      ),
    );
  }

  // --------------------------------------------------------------- boshqaruv

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> stop() async {
    await _player.stop();
    _queue = <Song>[];
    _queueLabel = '';
    _queueSourceId = null;
    notifyListeners();
  }

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_queue.isNotEmpty) {
      // Oxirgi qo'shiq — boshiga qaytamiz.
      await _player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> previous() async {
    // 3 sekunddan keyin "oldingi" tugmasi qo'shiqni boshidan boshlaydi.
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> seekToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  Future<void> toggleShuffle() async {
    final enable = !_player.shuffleModeEnabled;
    if (enable) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enable);
  }

  /// off -> all -> one -> off
  Future<void> cycleRepeatMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Kutubxonadan o'chirilgan qo'shiqni navbatdan ham olib tashlash.
  Future<void> handleSongRemoved(String songId) async {
    if (!_queue.any((song) => song.id == songId)) return;
    if (_queue.length == 1) {
      await stop();
      return;
    }
    final remaining = _queue.where((song) => song.id != songId).toList();
    final current = currentSong;
    final nextIndex =
        current == null || current.id == songId
            ? 0
            : remaining.indexWhere((song) => song.id == current.id);
    final wasPlaying = _player.playing;
    await playQueue(
      remaining,
      startIndex: nextIndex < 0 ? 0 : nextIndex,
      label: _queueLabel,
      sourceId: _queueSourceId,
    );
    if (!wasPlaying) await _player.pause();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
