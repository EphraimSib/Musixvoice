import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

/// Talks to Android's media library (all music stored on the phone).
class DeviceMedia {
  static const _channel = MethodChannel('musixvoice/media');
  static final Map<String, Future<String?>> _thumbs = {};

  static Future<List<Song>> scan() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('scan') ?? [];
    final songs = <Song>[];
    for (final e in raw) {
      final m = Map<String, dynamic>.from(e as Map);
      final id = (m['id'] as num).toInt();
      var artist = (m['artist'] as String?) ?? '';
      if (artist.isEmpty || artist == '<unknown>') artist = 'Unknown artist';
      var album = (m['album'] as String?) ?? '';
      if (album.isEmpty || album == '<unknown>') album = 'Unknown album';
      songs.add(Song(
        id: 'device:$id',
        title: (m['title'] as String?) ?? 'Untitled',
        artist: artist,
        album: album,
        filePath: m['path'] as String?,
        localId: id,
        albumId: (m['albumId'] as num?)?.toInt(),
        durationMs: (m['duration'] as num?)?.toInt(),
      ));
    }
    return songs;
  }

  /// Cover art file path for a song on the phone (null if it has none).
  static Future<String?> thumb(Song s) {
    if (!s.isLocal) return Future.value(null);
    return _thumbs.putIfAbsent(s.id, () async {
      try {
        return await _channel.invokeMethod<String>(
            'thumb', {'id': s.localId, 'albumId': s.albumId ?? 0});
      } catch (_) {
        return null;
      }
    });
  }
}

class Access {
  static Future<bool> hasMusic() async =>
      (await Permission.audio.status).isGranted ||
      (await Permission.storage.status).isGranted;

  /// Asks for music access (and notifications, so the lock-screen player shows).
  static Future<bool> request() async {
    final r = await [Permission.audio, Permission.storage, Permission.notification]
        .request();
    return r[Permission.audio]?.isGranted == true ||
        r[Permission.storage]?.isGranted == true;
  }

  static Future<void> openSettings() => openAppSettings();
}
