import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';
import 'device_media.dart';
import 'settings_service.dart';

/// Plays music one song at a time. The full queue lives in this class; the
/// audio engine (and the lock-screen player) only ever receives the current
/// song plus its direct previous and next song.
class PlayerService extends ChangeNotifier {
  final AndroidEqualizer equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer loudness = AndroidLoudnessEnhancer();

  /// Equalizer and loudness only exist when they were switched on before the
  /// app started (they are attached to the audio engine at creation).
  final bool withEffects;
  late final AudioPlayer _player = AudioPlayer(
    audioPipeline:
        withEffects ? AudioPipeline(androidAudioEffects: [loudness, equalizer]) : null,
  );
  bool get effectsActive => withEffects;

  AppSettings? settings;

  List<Song> _orig = []; // queue in its original order
  List<Song> _full = []; // queue in play order (shuffled when shuffle is on)
  List<Song> get queue => _full;
  int index = -1; // position in [queue]

  bool playing = false;
  bool loading = false;
  bool shuffle = false;
  LoopMode loop = LoopMode.off;
  String? error;
  DateTime? sleepAt;

  Timer? _sleepTimer;
  String? _lastRecorded;
  bool _eqApplied = false;
  final _rand = Random();

  // The small window currently loaded in the audio engine.
  ConcatenatingAudioSource? _concat;
  List<int> _win = []; // queue positions of the loaded songs
  bool _busy = false;
  Future<void> _chain = Future.value();

  void Function(Song)? onTrackStarted;

  Song? get current => (index >= 0 && index < _full.length) ? _full[index] : null;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;

  PlayerService({this.withEffects = false}) {
    _player.playerStateStream.listen((s) {
      playing = s.playing;
      loading = s.processingState == ProcessingState.loading ||
          s.processingState == ProcessingState.buffering;
      notifyListeners();
    });
    _player.currentIndexStream.listen(_onIndexChanged);
    _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      error = 'Could not play this song. Check your connection and try again.';
      notifyListeners();
    });
  }

  // ---------- helpers ----------

  Uri? _art(Song s) {
    if (s.artUrl != null) return Uri.tryParse(s.artUrl!);
    final dir = DeviceMedia.artDir;
    if (s.isLocal && dir != null) {
      final f = File('$dir/${s.localId}.jpg');
      if (f.existsSync()) return Uri.file(f.path);
    }
    return null;
  }

  AudioSource _source(Song s) => AudioSource.uri(
        Uri.parse(s.playUri),
        tag: MediaItem(
          id: s.id,
          title: s.title,
          artist: s.artist,
          album: s.album ?? s.genre,
          artUri: _art(s),
        ),
      );

  int? _prevOf(int pos) {
    if (_full.length < 2) return null;
    if (pos > 0) return pos - 1;
    return loop == LoopMode.all ? _full.length - 1 : null;
  }

  int? _nextOf(int pos) {
    if (_full.length < 2) return null;
    if (pos < _full.length - 1) return pos + 1;
    return loop == LoopMode.all ? 0 : null;
  }

  List<Song> _shuffled(List<Song> list, Song? first) {
    final l = List<Song>.of(list)..shuffle(_rand);
    if (first != null) {
      l.removeWhere((s) => s.id == first.id);
      l.insert(0, first);
    }
    return l;
  }

  // ---------- starting playback ----------

  Future<void> playQueue(List<Song> songs, int start) async {
    if (songs.isEmpty) return;
    _orig = List.of(songs);
    if (shuffle) {
      _full = _shuffled(_orig, songs[start]);
      await _startAt(0);
    } else {
      _full = List.of(_orig);
      await _startAt(start);
    }
  }

  Future<void> playIndex(int i) => _startAt(i);

  Future<void> _startAt(int pos) async {
    if (pos < 0 || pos >= _full.length) return;
    index = pos;
    error = null;
    _lastRecorded = null;
    notifyListeners();
    final song = _full[pos];
    try {
      if (song.isLocal) await DeviceMedia.thumb(song);
      _busy = true;
      final prev = _prevOf(pos);
      final next = _nextOf(pos);
      _win = [if (prev != null) prev, pos, if (next != null) next];
      final concat = ConcatenatingAudioSource(
        children: _win.map((i) => _source(_full[i])).toList(),
      );
      _concat = concat;
      await _player.setAudioSource(
        concat,
        initialIndex: prev != null ? 1 : 0,
        initialPosition: Duration.zero,
      );
      _busy = false;
      unawaited(_player.play());
      _onIndexChanged(_player.currentIndex);
      unawaited(_applyEq());
    } catch (e) {
      _busy = false;
      final why = e.toString().replaceAll('\n', ' ');
      error = 'Could not play "${song.title}": ${why.length > 140 ? why.substring(0, 140) : why}';
      notifyListeners();
    }
  }

  // ---------- keeping the small window in step ----------

  void _onIndexChanged(int? j) {
    if (_busy || j == null || j < 0 || j >= _win.length) return;
    final pos = _win[j];
    if (pos < 0 || pos >= _full.length) return;
    final changed = pos != index;
    index = pos;
    final s = _full[pos];
    if (_lastRecorded != s.id) {
      _lastRecorded = s.id;
      onTrackStarted?.call(s);
    }
    notifyListeners();
    if (changed) _chain = _chain.then((_) => _reslide());
  }

  /// Rebuilds the previous/next songs around the one that is playing,
  /// without interrupting it.
  Future<void> _reslide() async {
    final c = _concat;
    final j = _player.currentIndex;
    if (c == null || j == null || j >= c.length) {
      _busy = false;
      return;
    }
    _busy = true;
    try {
      if (c.length > j + 1) await c.removeRange(j + 1, c.length);
      if (j > 0) await c.removeRange(0, j);
      final pos = index;
      _win = [pos];
      final next = _nextOf(pos);
      final prev = _prevOf(pos);
      if (next != null) {
        if (_full[next].isLocal) await DeviceMedia.thumb(_full[next]);
        await c.add(_source(_full[next]));
        _win.add(next);
      }
      if (prev != null) {
        await c.insert(0, _source(_full[prev]));
        _win.insert(0, prev);
      }
    } catch (_) {
      // keep playing the current song even if the window could not be updated
    } finally {
      _busy = false;
    }
  }

  // ---------- controls ----------

  Future<void> toggle() async {
    if (current == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero, index: _player.currentIndex ?? 0);
      }
      unawaited(_player.play());
    }
  }

  Future<void> next() async {
    if (_concat == null || !_player.hasNext) return;
    await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_concat == null) return;
    if (_player.position > const Duration(seconds: 3) || !_player.hasPrevious) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  Future<void> seek(Duration d) => _player.seek(d);

  Future<void> toggleShuffle() async {
    shuffle = !shuffle;
    final cur = current;
    if (_full.isNotEmpty) {
      if (shuffle) {
        _full = _shuffled(_orig, cur);
        index = 0;
      } else {
        _full = List.of(_orig);
        final i = cur == null ? 0 : _full.indexWhere((s) => s.id == cur.id);
        index = i < 0 ? 0 : i;
      }
      _busy = true; // _reslide takes over and clears this
      _chain = _chain.then((_) => _reslide());
    }
    notifyListeners();
  }

  Future<void> cycleLoop() async {
    loop = switch (loop) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    notifyListeners();
    await _player.setLoopMode(loop == LoopMode.one ? LoopMode.one : LoopMode.off);
    if (_concat != null) _chain = _chain.then((_) => _reslide());
  }

  // ---------- audio settings ----------

  Future<void> applySettings() async {
    final s = settings;
    if (s == null) return;
    try {
      await _player.setSpeed(s.speed);
    } catch (_) {}
    try {
      await _player.setSkipSilenceEnabled(s.skipSilence);
    } catch (_) {}
    if (!withEffects) return;
    try {
      await loudness.setEnabled(s.loudnessGain > 0);
      await loudness.setTargetGain(s.loudnessGain);
      await equalizer.setEnabled(s.eqEnabled);
    } catch (_) {}
  }

  Future<void> _applyEq() async {
    final s = settings;
    if (!withEffects || s == null || _eqApplied || s.eqGains.isEmpty) return;
    try {
      final p = await equalizer.parameters;
      for (var i = 0; i < p.bands.length && i < s.eqGains.length; i++) {
        await p.bands[i].setGain(s.eqGains[i]);
      }
      _eqApplied = true;
    } catch (_) {}
  }

  // ---------- sleep timer ----------

  void setSleepTimer(Duration? d) {
    _sleepTimer?.cancel();
    if (d == null) {
      sleepAt = null;
    } else {
      sleepAt = DateTime.now().add(d);
      _sleepTimer = Timer(d, () {
        _player.pause();
        sleepAt = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }
}
