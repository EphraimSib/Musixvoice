import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every user setting. Changing any value saves it and refreshes the app.
class AppSettings extends ChangeNotifier {
  // Look & Feel
  double blur = 18;
  bool glow = true;
  bool animations = true;

  // Visualizer
  bool visualizerOn = true;
  int visualizerStyle = 0; // 0 bars, 1 wave, 2 dots
  int visualizerBars = 24;

  // Audio
  double speed = 1.0;
  bool skipSilence = false;
  double loudnessGain = 0; // dB
  bool eqEnabled = false;
  List<double> eqGains = [];

  // User interface
  bool showExploreTab = true;
  bool showAiTab = true;
  bool compactList = false;
  bool showMiniPlayer = true;

  // Full player
  int artShape = 0; // 0 rounded, 1 circle
  bool showQuickBar = true;

  // Files & folders
  int minTrackSeconds = 15;
  Set<String> excludedFolders = {};

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString('settings');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      blur = (m['blur'] as num?)?.toDouble() ?? blur;
      glow = m['glow'] as bool? ?? glow;
      animations = m['animations'] as bool? ?? animations;
      visualizerOn = m['visualizerOn'] as bool? ?? visualizerOn;
      visualizerStyle = m['visualizerStyle'] as int? ?? visualizerStyle;
      visualizerBars = m['visualizerBars'] as int? ?? visualizerBars;
      speed = (m['speed'] as num?)?.toDouble() ?? speed;
      skipSilence = m['skipSilence'] as bool? ?? skipSilence;
      loudnessGain = (m['loudnessGain'] as num?)?.toDouble() ?? loudnessGain;
      eqEnabled = m['eqEnabled'] as bool? ?? eqEnabled;
      eqGains = ((m['eqGains'] as List?) ?? []).map((e) => (e as num).toDouble()).toList();
      showExploreTab = m['showExploreTab'] as bool? ?? showExploreTab;
      showAiTab = m['showAiTab'] as bool? ?? showAiTab;
      compactList = m['compactList'] as bool? ?? compactList;
      showMiniPlayer = m['showMiniPlayer'] as bool? ?? showMiniPlayer;
      artShape = m['artShape'] as int? ?? artShape;
      showQuickBar = m['showQuickBar'] as bool? ?? showQuickBar;
      minTrackSeconds = m['minTrackSeconds'] as int? ?? minTrackSeconds;
      excludedFolders = ((m['excludedFolders'] as List?) ?? []).cast<String>().toSet();
    } catch (_) {}
  }

  /// Run a change, then save and refresh everything that shows settings.
  void update(void Function() change) {
    change();
    notifyListeners();
    _save();
  }

  Future<void> reset() async {
    blur = 18;
    glow = true;
    animations = true;
    visualizerOn = true;
    visualizerStyle = 0;
    visualizerBars = 24;
    speed = 1.0;
    skipSilence = false;
    loudnessGain = 0;
    eqEnabled = false;
    eqGains = [];
    showExploreTab = true;
    showAiTab = true;
    compactList = false;
    showMiniPlayer = true;
    artShape = 0;
    showQuickBar = true;
    minTrackSeconds = 15;
    excludedFolders = {};
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setString(
        'settings',
        jsonEncode({
          'blur': blur,
          'glow': glow,
          'animations': animations,
          'visualizerOn': visualizerOn,
          'visualizerStyle': visualizerStyle,
          'visualizerBars': visualizerBars,
          'speed': speed,
          'skipSilence': skipSilence,
          'loudnessGain': loudnessGain,
          'eqEnabled': eqEnabled,
          'eqGains': eqGains,
          'showExploreTab': showExploreTab,
          'showAiTab': showAiTab,
          'compactList': compactList,
          'showMiniPlayer': showMiniPlayer,
          'artShape': artShape,
          'showQuickBar': showQuickBar,
          'minTrackSeconds': minTrackSeconds,
          'excludedFolders': excludedFolders.toList(),
        }));
  }
}
