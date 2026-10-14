import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Audio fayldan o'qilgan teglar.
class AudioTags {
  AudioTags({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.lyrics,
    this.durationMs,
    this.artwork,
    this.artworkExtension,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final String? lyrics;
  final int? durationMs;
  final Uint8List? artwork;
  final String? artworkExtension;

  static AudioTags empty() => AudioTags();
}

class _TagBuilder {
  String? title;
  String? artist;
  String? album;
  String? genre;
  String? lyrics;
  int? durationMs;
  Uint8List? artwork;
  String? artworkExtension;
  int artworkType = -1;

  AudioTags build() => AudioTags(
    title: _clean(title),
    artist: _clean(artist),
    album: _clean(album),
    genre: _clean(genre),
    lyrics: _clean(lyrics),
    durationMs: durationMs,
    artwork: artwork,
    artworkExtension: artworkExtension,
  );

  static String? _clean(String? value) {
    if (value == null) return null;
    final trimmed = value.replaceAll('\u0000', '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// ID3v2 (2.2 / 2.3 / 2.4) va ID3v1 teglarini o'qiydigan sof Dart parser.
///
/// Tashqi paketga bog'liq emas — shu sababli iOS va Android'da bir xil ishlaydi.
class Id3Reader {
  /// Teglarni o'qiydi. Xatolik bo'lsa bo'sh natija qaytaradi (hech qachon
  /// istisno tashlamaydi) — chunki metadata ixtiyoriy ma'lumot.
  static Future<AudioTags> read(File file) async {
    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final builder = _TagBuilder();
      await _readV2(raf, builder);
      await _readV1(raf, builder);
      return builder.build();
    } catch (_) {
      return AudioTags.empty();
    } finally {
      try {
        await raf?.close();
      } catch (_) {
        // e'tiborsiz
      }
    }
  }

  // --------------------------------------------------------------- ID3v2

  static Future<void> _readV2(RandomAccessFile raf, _TagBuilder out) async {
    await raf.setPosition(0);
    final header = await raf.read(10);
    if (header.length < 10) return;
    if (header[0] != 0x49 || header[1] != 0x44 || header[2] != 0x33) return;

    final major = header[3];
    final flags = header[5];
    final size = _synchSafe(header, 6);
    if (size <= 0 || size > 64 * 1024 * 1024) return;

    // Fayl kutilganidan qisqa bo'lsa — o'qilgani bilan ishlaymiz.
    final body = await raf.read(size);
    if (body.isEmpty) return;

    // Kengaytirilgan sarlavha bo'lsa — o'tkazib yuboramiz.
    var start = 0;
    final hasExtendedHeader = (flags & 0x40) != 0;
    if (hasExtendedHeader && major >= 3 && body.length > 4) {
      final extSize =
          major >= 4 ? _synchSafe(body, 0) : _bigEndian(body, 0, 4) + 4;
      if (extSize > 0 && extSize < body.length) start = extSize;
    }

    _parseFrames(body, start, major, out);
  }

  static void _parseFrames(
    Uint8List body,
    int start,
    int major,
    _TagBuilder out,
  ) {
    final idLength = major >= 3 ? 4 : 3;
    final sizeLength = major >= 3 ? 4 : 3;
    final flagsLength = major >= 3 ? 2 : 0;
    final headerLength = idLength + sizeLength + flagsLength;

    var pos = start;
    while (pos + headerLength <= body.length) {
      if (body[pos] == 0) break; // padding boshlandi

      final id = latin1.decode(
        body.sublist(pos, pos + idLength),
        allowInvalid: true,
      );

      var frameSize =
          major >= 4
              ? _synchSafe(body, pos + idLength)
              : _bigEndian(body, pos + idLength, sizeLength);

      // Ba'zi ID3v2.4 fayllar o'lchamni synchsafe emas, oddiy yozadi.
      if (major >= 4 &&
          (frameSize <= 0 || pos + headerLength + frameSize > body.length)) {
        frameSize = _bigEndian(body, pos + idLength, sizeLength);
      }

      pos += headerLength;
      if (frameSize <= 0 || pos + frameSize > body.length) break;

      final data = body.sublist(pos, pos + frameSize);
      _handleFrame(id, data, out);
      pos += frameSize;
    }
  }

  static void _handleFrame(String id, Uint8List data, _TagBuilder out) {
    if (data.isEmpty) return;
    switch (id) {
      case 'TIT2':
      case 'TT2':
        out.title ??= _decodeTextFrame(data);
        break;
      case 'TPE1':
      case 'TP1':
        out.artist ??= _decodeTextFrame(data);
        break;
      case 'TALB':
      case 'TAL':
        out.album ??= _decodeTextFrame(data);
        break;
      case 'TCON':
      case 'TCO':
        out.genre ??= _normalizeGenre(_decodeTextFrame(data));
        break;
      case 'TLEN':
      case 'TLE':
        final raw = _decodeTextFrame(data);
        final parsed = int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
        if (parsed != null && parsed > 0) out.durationMs ??= parsed;
        break;
      case 'USLT':
      case 'ULT':
        out.lyrics ??= _decodeLyricsFrame(data);
        break;
      case 'APIC':
        _handleApic(data, out);
        break;
      case 'PIC':
        _handlePicV22(data, out);
        break;
      default:
        break;
    }
  }

  static void _handleApic(Uint8List data, _TagBuilder out) {
    final encoding = data[0];
    var pos = 1;

    final mimeEnd = _indexOfZero(data, pos, 1);
    if (mimeEnd < 0) return;
    final mime =
        latin1
            .decode(data.sublist(pos, mimeEnd), allowInvalid: true)
            .toLowerCase();
    pos = mimeEnd + 1;
    if (pos >= data.length) return;

    final pictureType = data[pos];
    pos += 1;
    pos = _skipTerminated(data, pos, encoding);
    if (pos < 0 || pos >= data.length) return;

    _storeArtwork(
      data.sublist(pos),
      _extensionFromMime(mime),
      pictureType,
      out,
    );
  }

  static void _handlePicV22(Uint8List data, _TagBuilder out) {
    if (data.length < 6) return;
    final encoding = data[0];
    final format =
        latin1.decode(data.sublist(1, 4), allowInvalid: true).toLowerCase();
    final pictureType = data[4];
    var pos = _skipTerminated(data, 5, encoding);
    if (pos < 0 || pos >= data.length) return;

    _storeArtwork(
      data.sublist(pos),
      format.contains('png') ? 'png' : 'jpg',
      pictureType,
      out,
    );
  }

  static void _storeArtwork(
    Uint8List bytes,
    String extension,
    int pictureType,
    _TagBuilder out,
  ) {
    if (bytes.isEmpty) return;
    // Oldingi rasm "front cover" bo'lsa, uni almashtirmaymiz.
    if (out.artwork != null && out.artworkType == 3) return;
    out.artwork = bytes;
    out.artworkExtension = extension;
    out.artworkType = pictureType;
  }

  // --------------------------------------------------------------- ID3v1

  static Future<void> _readV1(RandomAccessFile raf, _TagBuilder out) async {
    if (out.title != null && out.artist != null && out.album != null) return;

    final length = await raf.length();
    if (length < 128) return;
    await raf.setPosition(length - 128);
    final tag = await raf.read(128);
    if (tag.length < 128) return;
    if (tag[0] != 0x54 || tag[1] != 0x41 || tag[2] != 0x47) return; // 'TAG'

    String field(int from, int to) =>
        latin1.decode(tag.sublist(from, to), allowInvalid: true);

    out.title ??= field(3, 33);
    out.artist ??= field(33, 63);
    out.album ??= field(63, 93);
    out.genre ??= _genreById(tag[127]);
  }

  // ----------------------------------------------------------- yordamchi

  static String _decodeTextFrame(Uint8List data) {
    final encoding = data[0];
    return _decode(data.sublist(1), encoding);
  }

  static String _decodeLyricsFrame(Uint8List data) {
    if (data.length < 5) return '';
    final encoding = data[0];
    // data[1..3] — til kodi (masalan "uzb"), keyin tavsif (descriptor).
    final start = _skipTerminated(data, 4, encoding);
    if (start < 0 || start >= data.length) return '';
    return _decode(data.sublist(start), encoding).replaceAll('\r\n', '\n');
  }

  static String _decode(Uint8List bytes, int encoding) {
    switch (encoding) {
      case 1:
        return _decodeUtf16(bytes, bigEndianDefault: false);
      case 2:
        return _decodeUtf16(bytes, bigEndianDefault: true);
      case 3:
        return utf8.decode(bytes, allowMalformed: true);
      case 0:
      default:
        return latin1.decode(bytes, allowInvalid: true);
    }
  }

  static String _decodeUtf16(
    Uint8List bytes, {
    required bool bigEndianDefault,
  }) {
    if (bytes.length < 2) return '';
    var offset = 0;
    var bigEndian = bigEndianDefault;
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      bigEndian = false;
      offset = 2;
    } else if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      bigEndian = true;
      offset = 2;
    }

    final units = <int>[];
    for (var i = offset; i + 1 < bytes.length; i += 2) {
      final unit =
          bigEndian
              ? (bytes[i] << 8) | bytes[i + 1]
              : (bytes[i + 1] << 8) | bytes[i];
      if (unit == 0) break;
      units.add(unit);
    }
    return String.fromCharCodes(units);
  }

  /// Null bilan tugaydigan matnni o'tkazib yuboradi va keyingi indeksni qaytaradi.
  static int _skipTerminated(Uint8List data, int from, int encoding) {
    final step = (encoding == 1 || encoding == 2) ? 2 : 1;
    final end = _indexOfZero(data, from, step);
    if (end < 0) return -1;
    return end + step;
  }

  static int _indexOfZero(Uint8List data, int from, int step) {
    for (var i = from; i + step - 1 < data.length; i += step) {
      if (step == 1) {
        if (data[i] == 0) return i;
      } else if (data[i] == 0 && data[i + 1] == 0) {
        return i;
      }
    }
    return -1;
  }

  static int _synchSafe(Uint8List bytes, int offset) {
    if (offset + 3 >= bytes.length) return 0;
    return ((bytes[offset] & 0x7F) << 21) |
        ((bytes[offset + 1] & 0x7F) << 14) |
        ((bytes[offset + 2] & 0x7F) << 7) |
        (bytes[offset + 3] & 0x7F);
  }

  static int _bigEndian(Uint8List bytes, int offset, int length) {
    if (offset + length > bytes.length) return 0;
    var value = 0;
    for (var i = 0; i < length; i++) {
      value = (value << 8) | bytes[offset + i];
    }
    return value;
  }

  static String _extensionFromMime(String mime) {
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    return 'jpg';
  }

  /// "(13)" yoki "(13)Pop" ko'rinishidagi janrni odam o'qiydigan ko'rinishga keltiradi.
  static String _normalizeGenre(String raw) {
    final match = RegExp(r'^\((\d+)\)\s*(.*)$').firstMatch(raw.trim());
    if (match == null) return raw;
    final rest = match.group(2) ?? '';
    if (rest.trim().isNotEmpty) return rest.trim();
    return _genreById(int.tryParse(match.group(1) ?? '') ?? -1) ?? raw;
  }

  static String? _genreById(int id) {
    if (id < 0 || id >= _id3v1Genres.length) return null;
    return _id3v1Genres[id];
  }

  static const List<String> _id3v1Genres = <String>[
    'Blues',
    'Classic Rock',
    'Country',
    'Dance',
    'Disco',
    'Funk',
    'Grunge',
    'Hip-Hop',
    'Jazz',
    'Metal',
    'New Age',
    'Oldies',
    'Other',
    'Pop',
    'R&B',
    'Rap',
    'Reggae',
    'Rock',
    'Techno',
    'Industrial',
    'Alternative',
    'Ska',
    'Death Metal',
    'Pranks',
    'Soundtrack',
    'Euro-Techno',
    'Ambient',
    'Trip-Hop',
    'Vocal',
    'Jazz+Funk',
    'Fusion',
    'Trance',
    'Classical',
    'Instrumental',
    'Acid',
    'House',
    'Game',
    'Sound Clip',
    'Gospel',
    'Noise',
    'Alternative Rock',
    'Bass',
    'Soul',
    'Punk',
    'Space',
    'Meditative',
    'Instrumental Pop',
    'Instrumental Rock',
    'Ethnic',
    'Gothic',
    'Darkwave',
    'Techno-Industrial',
    'Electronic',
    'Pop-Folk',
    'Eurodance',
    'Dream',
    'Southern Rock',
    'Comedy',
    'Cult',
    'Gangsta',
    'Top 40',
    'Christian Rap',
    'Pop/Funk',
    'Jungle',
    'Native American',
    'Cabaret',
    'New Wave',
    'Psychedelic',
    'Rave',
    'Showtunes',
    'Trailer',
    'Lo-Fi',
    'Tribal',
    'Acid Punk',
    'Acid Jazz',
    'Polka',
    'Retro',
    'Musical',
    'Rock & Roll',
    'Hard Rock',
  ];
}
