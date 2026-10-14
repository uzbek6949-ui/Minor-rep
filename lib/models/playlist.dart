/// Foydalanuvchi yaratgan playlist.
class Playlist {
  Playlist({
    required this.id,
    required this.name,
    List<String>? songIds,
    DateTime? createdAt,
  }) : songIds = songIds ?? <String>[],
       createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;

  /// Playlistdagi qo'shiqlar tartibi ([Song.id] ro'yxati).
  final List<String> songIds;

  final DateTime createdAt;

  int get length => songIds.length;

  bool contains(String songId) => songIds.contains(songId);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'songIds': songIds,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  static Playlist fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    return Playlist(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      songIds:
          ((map['songIds'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  @override
  bool operator ==(Object other) => other is Playlist && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
