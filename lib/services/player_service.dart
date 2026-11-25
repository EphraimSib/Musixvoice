import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';
import 'settings_service.dart';

class PlayerService extends ChangeNotifier {
  final AndroidEqualizer equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer loudness = AndroidLoudnessEnhancer();
  late final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [loudness, equalizer]),
  );

  AppSettings? settings;
  List<Song> queue = [];
  int index = -1;
  bool playing = false;
  bool loading = false;
  bool shuffle = false;
  LoopMode loop = LoopMode.off;
  String? error;
  DateTime? sleepAt;
  Timer? _sleepTimer;
  String? _lastRecorded;
  bool _eqApplied = false;

  void Function(Song)? onTrackStarted;

  Song? get current => (index >= 0 && index < queue.length) ? queue[index] : null;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;

  PlayerService() {
    _player.playerStateStream.listen((s) {
      playing = s.playing;
      loading = s.processingState == ProcessingState.loading ||
          s.processingState == ProcessingState.buffering;
      notifyListeners();
    });
    _player.currentIndexStream.listen((i) {
      if (i == null || i < 0 || i >= queue.length) return;
      index = i;
      final s = queue[i];
      if (_lastRecorded != s.id) {
        _lastRecorded = s.id;
        onTrackStarted?.call(s);
      }
      notifyListeners();
    });
    _player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      error = 'Could not play this song. Check your connection and try again.';
      notifyListeners();
    });
  }

  Uri? _art(Song s) {
    if (s.artUrl != null) return Uri.tryParse(s.artUrl!);
    if (s.isLocal && s.albumId != null) {
      return Uri.parse('content://media/external/audio/albumart/${s.albumId}');
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

  Future<void> playQueue(List<Song> songs, int start) async {
    if (songs.isEmpty) return;
    queue = List.of(songs);
    index = start;
    error = null;
    _lastRecorded = null;
    notifyListeners();
    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: queue.map(_source).toList()),
        initialIndex: start,
        initialPosition: Duration.zero,
      );
      unawaited(_player.play());
      unawaited(_applyEq());
    } catch (_) {
      error = 'Could not play "${songs[start].title}".';
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (current == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero, index: 0);
      }
      unawaited(_player.play());
    }
  }

  Future<void> next() => _player.seekToNext();

  Future<void> previous() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  Future<void> seek(Duration d) => _player.seek(d);

  Future<void> playIndex(int i) async {
    await _player.seek(Duration.zero, index: i);
    unawaited(_player.play());
  }

  Future<void> toggleShuffle() async {
    shuffle = !shuffle;
    notifyListeners();
    await _player.setShuffleModeEnabled(shuffle);
    if (shuffle) await _player.shuffle();
  }

  Future<void> cycleLoop() async {
    loop = switch (loop) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    notifyListeners();
    await _player.setLoopMode(loop);
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
    try {
      await loudness.setEnabled(s.loudnessGain > 0);
      await loudness.setTargetGain(s.loudnessGain);
      await equalizer.setEnabled(s.eqEnabled);
    } catch (_) {}
  }

  Future<void> _applyEq() async {
    final s = settings;
    if (s == null || _eqApplied || s.eqGains.isEmpty) return;
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
