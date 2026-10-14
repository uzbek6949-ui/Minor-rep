import 'package:flutter_test/flutter_test.dart';
import 'package:minor_rep/models/playlist.dart';
import 'package:minor_rep/models/song.dart';

void main() {
  group('Song', () {
    final song = Song(
      id: 'song-1',
      filePath: '/music/track.mp3',
      title: 'Yulduzlar',
      artist: 'Ijrochi',
      album: 'Tungi albom',
      genre: 'Pop',
      durationMs: 215000,
      lyrics: 'Birinchi qator\nIkkinchi qator',
      addedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    test('map orqali saqlanadi va tiklanadi', () {
      final restored = Song.fromMap(song.toMap());
      expect(restored.id, song.id);
      expect(restored.title, song.title);
      expect(restored.artist, song.artist);
      expect(restored.album, song.album);
      expect(restored.genre, song.genre);
      expect(restored.durationMs, song.durationMs);
      expect(restored.lyrics, song.lyrics);
      expect(restored.addedAt, song.addedAt);
      expect(restored, song); // id bo'yicha tenglik
    });

    test('yetishmayotgan maydonlar xavfsiz standart qiymat oladi', () {
      final restored = Song.fromMap(<String, dynamic>{
        'id': 'x',
        'filePath': '/a.mp3',
      });
      expect(restored.title, '');
      expect(restored.durationMs, 0);
      expect(restored.isFavorite, isFalse);
      expect(restored.hasLyrics, isFalse);
    });

    test('hasLyrics faqat boʻsh boʻlmagan matnda true', () {
      expect(song.hasLyrics, isTrue);
      expect(song.copyWith(lyrics: '   ').hasLyrics, isFalse);
    });

    test('displayArtist boʻsh ijrochini almashtiradi', () {
      expect(song.copyWith(artist: '').displayArtist, isNotEmpty);
      expect(song.copyWith(artist: '').displayArtist, isNot('Ijrochi'));
    });

    test('searchIndex barcha maydonlarni qamrab oladi', () {
      expect(song.searchIndex, contains('yulduzlar'));
      expect(song.searchIndex, contains('ijrochi'));
      expect(song.searchIndex, contains('tungi albom'));
      expect(song.searchIndex, contains('pop'));
    });

    test('duration millisekunddan hisoblanadi', () {
      expect(song.duration, const Duration(milliseconds: 215000));
    });
  });

  group('Playlist', () {
    test('map orqali saqlanadi va tiklanadi', () {
      final playlist = Playlist(
        id: 'pl-1',
        name: 'Kechqurun',
        songIds: <String>['a', 'b'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      final restored = Playlist.fromMap(playlist.toMap());
      expect(restored.name, 'Kechqurun');
      expect(restored.songIds, <String>['a', 'b']);
      expect(restored.length, 2);
      expect(restored.contains('b'), isTrue);
      expect(restored.contains('c'), isFalse);
      expect(restored.createdAt, playlist.createdAt);
    });
  });
}
