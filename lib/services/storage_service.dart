import 'package:hive_flutter/hive_flutter.dart';

import '../models/playlist.dart';
import '../models/song.dart';

/// Lokal baza (Hive) bilan ishlash. Internet yoki login talab qilinmaydi —
/// barcha ma'lumot faqat telefonda saqlanadi.
///
/// Qo'shiq va playlistlar `Map` sifatida saqlanadi, shuning uchun
/// `build_runner` / TypeAdapter generatsiyasi kerak emas.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _songsBoxName = 'songs';
  static const String _playlistsBoxName = 'playlists';
  static const String _settingsBoxName = 'settings';

  late Box _songsBox;
  late Box _playlistsBox;
  late Box _settingsBox;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _songsBox = await Hive.openBox(_songsBoxName);
    _playlistsBox = await Hive.openBox(_playlistsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _ready = true;
  }

  // ------------------------------------------------------------- qo'shiqlar

  List<Song> loadSongs() {
    final result = <Song>[];
    for (final value in _songsBox.values) {
      if (value is Map) {
        try {
          result.add(Song.fromMap(value));
        } catch (_) {
          // Buzilgan yozuvni o'tkazib yuboramiz.
        }
      }
    }
    return result;
  }

  Future<void> saveSong(Song song) => _songsBox.put(song.id, song.toMap());

  Future<void> saveSongs(Iterable<Song> songs) {
    final entries = <String, Map<String, dynamic>>{
      for (final song in songs) song.id: song.toMap(),
    };
    return _songsBox.putAll(entries);
  }

  Future<void> deleteSong(String songId) => _songsBox.delete(songId);

  // ------------------------------------------------------------ playlistlar

  List<Playlist> loadPlaylists() {
    final result = <Playlist>[];
    for (final value in _playlistsBox.values) {
      if (value is Map) {
        try {
          result.add(Playlist.fromMap(value));
        } catch (_) {
          // Buzilgan yozuvni o'tkazib yuboramiz.
        }
      }
    }
    return result;
  }

  Future<void> savePlaylist(Playlist playlist) =>
      _playlistsBox.put(playlist.id, playlist.toMap());

  Future<void> deletePlaylist(String playlistId) =>
      _playlistsBox.delete(playlistId);

  // --------------------------------------------------------------- sozlamalar

  T? setting<T>(String key) {
    final value = _settingsBox.get(key);
    return value is T ? value : null;
  }

  Future<void> putSetting(String key, Object? value) =>
      _settingsBox.put(key, value);
}
