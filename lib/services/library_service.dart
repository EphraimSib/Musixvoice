import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'device_media.dart';
import 'settings_service.dart';

/// Songs on the phone, favorites, playlists, history and the taste profile.
class LibraryService extends ChangeNotifier {
  AppSettings? settings;

  bool permission = false;
  bool scanning = false;
  String? scanError;

  List<Song> allDevice = []; // everything Android found
  List<Song> local = []; // after the Files & Folder filters
  Map<String, List<Song>> albums = {};
  Map<String, List<Song>> artists = {};
  Map<String, int> folders = {}; // folder path -> song count

  List<Song> favorites = [];
  List<Song> recent = [];
  Map<String, List<Song>> playlists = {};
  Map<String, int> genreCounts = {};

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    favorites = _readList('favorites');
    recent = _readList('recent');
    final pl = _prefs.getString('playlists');
    if (pl != null) {
      final m = jsonDecode(pl) as Map<String, dynamic>;
      playlists = m.map((k, v) => MapEntry(
          k, (v as List).map((e) => Song.fromJson(e as Map<String, dynamic>)).toList()));
    }
    final gc = _prefs.getString('genres');
    if (gc != null) {
      genreCounts = (jsonDecode(gc) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int));
    }
  }

  List<Song> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Song.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    String enc(List<Song> l) => jsonEncode(l.map((s) => s.toJson()).toList());
    await _prefs.setString('favorites', enc(favorites));
    await _prefs.setString('recent', enc(recent));
    await _prefs.setString(
        'playlists',
        jsonEncode(playlists.map(
            (k, v) => MapEntry(k, v.map((s) => s.toJson()).toList()))));
    await _prefs.setString('genres', jsonEncode(genreCounts));
    notifyListeners();
  }

  // ---------- music on the phone ----------

  /// Checks access, asks for it once on first run, then scans.
  Future<void> initAccess() async {
    permission = await Access.hasMusic();
    final asked = _prefs.getBool('asked_access') ?? false;
    if (!permission && !asked) {
      await _prefs.setBool('asked_access', true);
      permission = await Access.request();
    }
    notifyListeners();
    if (permission) await scanDevice();
  }

  Future<void> requestAccess() async {
    permission = await Access.request();
    notifyListeners();
    if (permission) await scanDevice();
  }

  Future<void> scanDevice() async {
    scanning = true;
    scanError = null;
    notifyListeners();
    try {
      allDevice = await DeviceMedia.scan();
    } catch (_) {
      scanError = 'Could not read the music on this phone.';
    }
    scanning = false;
    refilter();
  }

  /// Applies "minimum length" and excluded folders, then rebuilds albums/artists.
  void refilter() {
    final s = settings;
    final minMs = (s?.minTrackSeconds ?? 0) * 1000;
    final excluded = s?.excludedFolders ?? <String>{};
    folders = {};
    for (final song in allDevice) {
      final f = song.folder;
      if (f != null) folders[f] = (folders[f] ?? 0) + 1;
    }
    local = allDevice.where((song) {
      if (song.durationMs != null && song.durationMs! < minMs) return false;
      final f = song.folder;
      return f == null || !excluded.contains(f);
    }).toList();
    albums = {};
    artists = {};
    for (final song in local) {
      (albums[song.album ?? 'Unknown album'] ??= []).add(song);
      (artists[song.artist] ??= []).add(song);
    }
    notifyListeners();
  }

  // ---------- favorites, playlists, history ----------

  bool isFavorite(Song s) => favorites.any((x) => x.id == s.id);

  Future<void> toggleFavorite(Song s) async {
    if (isFavorite(s)) {
      favorites.removeWhere((x) => x.id == s.id);
    } else {
      favorites.insert(0, s);
    }
    await _save();
  }

  Future<void> createPlaylist(String name) async {
    final n = name.trim();
    if (n.isEmpty || playlists.containsKey(n)) return;
    playlists[n] = [];
    await _save();
  }

  Future<void> addToPlaylist(String name, Song s) async {
    final l = playlists[name];
    if (l == null || l.any((x) => x.id == s.id)) return;
    l.add(s);
    await _save();
  }

  Future<void> deletePlaylist(String name) async {
    playlists.remove(name);
    await _save();
  }

  void recordPlay(Song s) {
    recent.removeWhere((x) => x.id == s.id);
    recent.insert(0, s);
    if (recent.length > 20) recent = recent.sublist(0, 20);
    final g = s.genre;
    if (g != null && g.isNotEmpty) genreCounts[g] = (genreCounts[g] ?? 0) + 1;
    _save();
  }

  Future<void> clearHistory() async {
    recent = [];
    genreCounts = {};
    await _save();
  }

  /// Top genres with their share of everything the user has played.
  List<MapEntry<String, double>> topGenres([int n = 5]) {
    final total = genreCounts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];
    final entries = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).map((e) => MapEntry(e.key, e.value / total)).toList();
  }
}
