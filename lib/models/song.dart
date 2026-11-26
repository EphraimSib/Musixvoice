class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artUrl; // online artwork
  final String? url; // online stream
  final String? filePath; // path on the phone (used for folders)
  final String? genre;
  final int? localId; // Android MediaStore id
  final int? albumId;
  final int? durationMs;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artUrl,
    this.url,
    this.filePath,
    this.genre,
    this.localId,
    this.albumId,
    this.durationMs,
  });

  bool get isLocal => localId != null;

  /// Address the audio player opens.
  String get playUri =>
      isLocal ? 'content://media/external/audio/media/$localId' : url!;

  /// Folder the file lives in (only for songs on the phone).
  String? get folder {
    final p = filePath;
    if (p == null) return null;
    final i = p.lastIndexOf('/');
    return i <= 0 ? null : p.substring(0, i);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'artUrl': artUrl,
        'url': url,
        'filePath': filePath,
        'genre': genre,
        'localId': localId,
        'albumId': albumId,
        'durationMs': durationMs,
      };

  factory Song.fromJson(Map<String, dynamic> j) => Song(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: (j['artist'] as String?) ?? 'Unknown artist',
        album: j['album'] as String?,
        artUrl: j['artUrl'] as String?,
        url: j['url'] as String?,
        filePath: j['filePath'] as String?,
        genre: j['genre'] as String?,
        localId: (j['localId'] as num?)?.toInt(),
        albumId: (j['albumId'] as num?)?.toInt(),
        durationMs: (j['durationMs'] as num?)?.toInt(),
      );
}
