/// Bitta audio fayl (qo'shiq) haqidagi barcha ma'lumot.
///
/// Hive'da `Map` ko'rinishida saqlanadi — shu sababli kod generatsiyasi
/// (build_runner) talab qilinmaydi.
class Song {
  Song({
    required this.id,
    required this.filePath,
    required this.title,
    required this.artist,
    this.album = '',
    this.genre = '',
    this.durationMs = 0,
    this.artworkPath,
    this.lyrics,
    this.isFavorite = false,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Ichki, o'zgarmas identifikator.
  final String id;

  /// Telefon xotirasidagi (yoki ilova papkasidagi) audio fayl yo'li.
  final String filePath;

  String title;
  String artist;
  String album;
  String genre;

  /// Davomiyligi millisekundda. 0 — hali aniqlanmagan.
  int durationMs;

  /// Albom rasmi — ilova papkasiga saqlangan fayl yo'li.
  String? artworkPath;

  /// Qo'shiq so'zlari (keyinchalik qo'lda kiritilishi mumkin).
  String? lyrics;

  bool isFavorite;

  final DateTime addedAt;

  Duration get duration => Duration(milliseconds: durationMs);

  bool get hasLyrics => (lyrics ?? '').trim().isNotEmpty;

  String get displayArtist =>
      artist.trim().isEmpty ? 'Noma’lum ijrochi' : artist;

  /// Qidiruv uchun bir qatorga jamlangan matn.
  String get searchIndex => '$title $artist $album $genre'.toLowerCase();

  Song copyWith({
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? durationMs,
    String? artworkPath,
    String? lyrics,
    bool? isFavorite,
  }) {
    return Song(
      id: id,
      filePath: filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      durationMs: durationMs ?? this.durationMs,
      artworkPath: artworkPath ?? this.artworkPath,
      lyrics: lyrics ?? this.lyrics,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'filePath': filePath,
    'title': title,
    'artist': artist,
    'album': album,
    'genre': genre,
    'durationMs': durationMs,
    'artworkPath': artworkPath,
    'lyrics': lyrics,
    'isFavorite': isFavorite,
    'addedAt': addedAt.millisecondsSinceEpoch,
  };

  static Song fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    return Song(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      title: (map['title'] as String?) ?? '',
      artist: (map['artist'] as String?) ?? '',
      album: (map['album'] as String?) ?? '',
      genre: (map['genre'] as String?) ?? '',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      artworkPath: map['artworkPath'] as String?,
      lyrics: map['lyrics'] as String?,
      isFavorite: (map['isFavorite'] as bool?) ?? false,
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['addedAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
