import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

/// Online music from Audius (free, open music network with full-length tracks).
class AudiusService {
  static const _app = 'Musixvoice';
  String? _host;

  Future<String> _getHost() async {
    if (_host != null) return _host!;
    try {
      final r = await http
          .get(Uri.parse('https://api.audius.co'))
          .timeout(const Duration(seconds: 8));
      final list = (jsonDecode(r.body)['data'] as List).cast<String>();
      if (list.isNotEmpty) _host = list.first;
    } catch (_) {}
    return _host ??= 'https://api.audius.co';
  }

  Future<List<Song>> search(String query) =>
      _fetch('/v1/tracks/search', {'query': query, 'limit': '25'});

  Future<List<Song>> trending({String? genre}) => _fetch('/v1/tracks/trending', {
        'time': 'week',
        'limit': '25',
        if (genre != null) 'genre': genre,
      });

  Future<List<Song>> _fetch(String path, Map<String, String> params,
      {bool retry = true}) async {
    final host = await _getHost();
    try {
      final uri = Uri.parse('$host$path')
          .replace(queryParameters: {...params, 'app_name': _app});
      final r = await http.get(uri).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) throw Exception('Server error ${r.statusCode}');
      final data = (jsonDecode(r.body)['data'] as List?) ?? [];
      final songs = <Song>[];
      for (final raw in data) {
        final t = raw as Map<String, dynamic>;
        if (t['is_streamable'] == false) continue;
        final id = t['id'] as String;
        final art = t['artwork'] as Map<String, dynamic>?;
        songs.add(Song(
          id: 'audius:$id',
          title: (t['title'] as String?) ?? 'Untitled',
          artist: ((t['user'] as Map?)?['name'] as String?) ?? 'Unknown artist',
          artUrl: (art?['480x480'] ?? art?['150x150']) as String?,
          url: '$host/v1/tracks/$id/stream?app_name=$_app',
          genre: t['genre'] as String?,
        ));
      }
      return songs;
    } catch (e) {
      if (retry) {
        _host = null; // try another host once
        return _fetch(path, params, retry: false);
      }
      rethrow;
    }
  }
}
