import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/ai_service.dart';
import '../services/device_media.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';
import '../widgets/glass.dart';
import '../widgets/visualizer.dart';

// ---------------------------------------------------------------- themes

void showThemePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final t = ThemeScope.of(ctx);
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.background[1].withOpacity(0.97),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const SafeArea(child: ThemeGrid()),
      );
    },
  );
}

class ThemeGrid extends StatelessWidget {
  const ThemeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Themes',
              style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final th in MvThemes.all)
                GestureDetector(
                  onTap: () => themeController.set(th),
                  child: SizedBox(
                    width: 76,
                    child: Column(children: [
                      Container(
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: th.background),
                          border: Border.all(
                              color: th.id == t.id ? Colors.white : Colors.white24,
                              width: th.id == t.id ? 3 : 1),
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: th.accent,
                                boxShadow: [
                                  BoxShadow(
                                      color: th.accent.withOpacity(0.7), blurRadius: 12)
                                ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(th.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.subtext, fontSize: 12)),
                    ]),
                  ),
                ),
            ],
          ),
        ]);
  }
}

// ------------------------------------------------------- settings home

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _items = <(IconData, String, String)>[
    (Icons.palette_outlined, 'Look & Feel', 'Themes, Colors, Animations'),
    (Icons.graphic_eq_rounded, 'Visualizer', 'Style, Type & Customization'),
    (Icons.volume_up_rounded, 'Audio', 'Equalizer, Speed, Loudness'),
    (Icons.dashboard_customize_outlined, 'User Interface', 'Customize UI, Tabs, Styles etc.'),
    (Icons.smartphone_rounded, 'Full Player', 'Customize Now Playing Screen'),
    (Icons.folder_outlined, 'Files & Folder', 'Music access, Include or Exclude Folder'),
    (Icons.tune_rounded, 'Advanced', 'Sleep timer, Reset, Advanced Options'),
    (Icons.auto_awesome_outlined, 'AI Assistant', 'API key for taste analysis & mood mixes'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(children: [
                GlassIcon(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context)),
                const SizedBox(width: 14),
                Text('Settings',
                    style: TextStyle(
                        color: t.text, fontSize: 26, fontWeight: FontWeight.w700)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final it = _items[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SettingsPage(index: i, title: it.$2))),
                      child: Row(children: [
                        Icon(it.$1, color: t.accent, size: 30),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.$2,
                                    style: TextStyle(
                                        color: t.text,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(it.$3,
                                    style: TextStyle(color: t.subtext, fontSize: 13)),
                              ]),
                        ),
                        Icon(Icons.chevron_right_rounded, color: t.subtext),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final int index;
  final String title;
  const SettingsPage({super.key, required this.index, required this.title});

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(children: [
                GlassIcon(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: t.text, fontSize: 24, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([settings, library, player]),
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  children: _body(context),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    switch (index) {
      case 0:
        return _lookAndFeel(context);
      case 1:
        return _visualizer(context);
      case 2:
        return _audio(context);
      case 3:
        return _userInterface(context);
      case 4:
        return _fullPlayer(context);
      case 5:
        return _files(context);
      case 6:
        return _advanced(context);
      default:
        return [const _AiKeyCard()];
    }
  }

  // ---- pages ----

  List<Widget> _lookAndFeel(BuildContext c) => [
        const GlassCard(child: ThemeGrid()),
        _gap,
        _slider(c, 'Glass blur', '${settings.blur.round()}', settings.blur, 0, 30, 30,
            (v) => settings.update(() => settings.blur = v)),
        _gap,
        _switch(c, 'Background glow', 'Soft coloured light behind the screens',
            settings.glow, (v) => settings.update(() => settings.glow = v)),
        _gap,
        _switch(c, 'Animations', 'Pulsing glow around the cover while playing',
            settings.animations, (v) => settings.update(() => settings.animations = v)),
      ];

  List<Widget> _visualizer(BuildContext c) {
    final t = ThemeScope.of(c);
    return [
      _switch(c, 'Show visualizer', 'On the Now Playing screen',
          settings.visualizerOn, (v) => settings.update(() => settings.visualizerOn = v)),
      _gap,
      _choice(c, 'Style', const ['Bars', 'Wave', 'Dots'], settings.visualizerStyle,
          (i) => settings.update(() => settings.visualizerStyle = i)),
      _gap,
      _slider(c, 'Detail', '${settings.visualizerBars}', settings.visualizerBars.toDouble(),
          12, 48, 36, (v) => settings.update(() => settings.visualizerBars = v.round())),
      _gap,
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Preview',
              style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          AudioVisualizer(
            playing: true,
            color: t.accent,
            color2: t.accent2,
            style: settings.visualizerStyle,
            bars: settings.visualizerBars,
            height: 60,
          ),
          const SizedBox(height: 6),
          Text('The visualizer moves while music plays. It does not read the sound itself.',
              style: TextStyle(color: t.subtext, fontSize: 12)),
        ]),
      ),
    ];
  }

  List<Widget> _audio(BuildContext c) => [
        _slider(c, 'Playback speed', '${settings.speed.toStringAsFixed(2)}x',
            settings.speed, 0.5, 2.0, 30, (v) {
          settings.update(() => settings.speed = double.parse(v.toStringAsFixed(2)));
        }, onEnd: (_) => player.applySettings()),
        _gap,
        _switch(c, 'Skip silence', 'Jump over quiet gaps in songs', settings.skipSilence,
            (v) {
          settings.update(() => settings.skipSilence = v);
          player.applySettings();
        }),
        _gap,
        _slider(c, 'Loudness boost', '+${settings.loudnessGain.toStringAsFixed(1)} dB',
            settings.loudnessGain, 0, 6, 12,
            (v) => settings.update(() => settings.loudnessGain = v),
            onEnd: (_) => player.applySettings()),
        _gap,
        _switch(c, 'Equalizer', 'Shape the sound with the bands below', settings.eqEnabled,
            (v) {
          settings.update(() => settings.eqEnabled = v);
          player.applySettings();
        }),
        _gap,
        const _EqualizerCard(),
      ];

  List<Widget> _userInterface(BuildContext c) => [
        _switch(c, 'Explore tab', 'Online search and genres', settings.showExploreTab,
            (v) => settings.update(() => settings.showExploreTab = v)),
        _gap,
        _switch(c, 'AI tab', 'Taste profile and mood mixes', settings.showAiTab,
            (v) => settings.update(() => settings.showAiTab = v)),
        _gap,
        _switch(c, 'Compact song list', 'Smaller rows so more songs fit',
            settings.compactList, (v) => settings.update(() => settings.compactList = v)),
        _gap,
        _switch(c, 'Mini player', 'Small player above the tab bar', settings.showMiniPlayer,
            (v) => settings.update(() => settings.showMiniPlayer = v)),
      ];

  List<Widget> _fullPlayer(BuildContext c) => [
        _choice(c, 'Cover shape', const ['Rounded', 'Circle'], settings.artShape,
            (i) => settings.update(() => settings.artShape = i)),
        _gap,
        _switch(c, 'Show visualizer', 'Under the cover', settings.visualizerOn,
            (v) => settings.update(() => settings.visualizerOn = v)),
        _gap,
        _switch(c, 'Quick actions', '"Up next" and "More like this" bar',
            settings.showQuickBar, (v) => settings.update(() => settings.showQuickBar = v)),
      ];

  List<Widget> _files(BuildContext c) {
    final t = ThemeScope.of(c);
    final folders = library.folders.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return [
      GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(library.permission ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                color: library.permission ? t.accent : t.subtext),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  library.permission ? 'Music access allowed' : 'Music access not allowed',
                  style: TextStyle(
                      color: t.text, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
              library.permission
                  ? '${library.local.length} songs shown, ${library.allDevice.length} found on this phone.'
                  : 'Allow access so Musixvoice can play all the music on your phone.',
              style: TextStyle(color: t.subtext, fontSize: 13)),
          const SizedBox(height: 12),
          if (!library.permission) ...[
            FilledButton(
                onPressed: library.requestAccess, child: const Text('Allow music access')),
            TextButton(
                onPressed: Access.openSettings, child: const Text('Open app settings')),
          ] else
            FilledButton.icon(
              onPressed: library.scanning ? null : library.scanDevice,
              icon: library.scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              label: Text(library.scanning ? 'Scanning...' : 'Scan music again'),
            ),
        ]),
      ),
      _gap,
      _slider(c, 'Ignore short tracks', '${settings.minTrackSeconds}s',
          settings.minTrackSeconds.toDouble(), 0, 120, 24, (v) {
        settings.update(() => settings.minTrackSeconds = v.round());
      }, onEnd: (_) => library.refilter()),
      _gap,
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text('Folders (switch off to hide a folder)',
            style: TextStyle(color: t.subtext, fontSize: 13)),
      ),
      if (folders.isEmpty)
        GlassCard(
            child: Text('No music folders found yet.', style: TextStyle(color: t.subtext))),
      for (final f in folders)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              Icon(Icons.folder_outlined, color: t.subtext),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_folderName(f.key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
                  Text('${f.value} songs',
                      style: TextStyle(color: t.subtext, fontSize: 12)),
                ]),
              ),
              Switch(
                value: !settings.excludedFolders.contains(f.key),
                onChanged: (on) {
                  settings.update(() {
                    if (on) {
                      settings.excludedFolders.remove(f.key);
                    } else {
                      settings.excludedFolders.add(f.key);
                    }
                  });
                  library.refilter();
                },
              ),
            ]),
          ),
        ),
    ];
  }

  String _folderName(String path) {
    final parts = path.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[parts.length - 2]}/${parts.last}';
    return parts.isEmpty ? path : parts.last;
  }

  List<Widget> _advanced(BuildContext c) {
    final t = ThemeScope.of(c);
    final at = player.sleepAt;
    String hhmm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    const mins = [0, 15, 30, 45, 60];
    return [
      _choice(c, 'Sleep timer', const ['Off', '15 min', '30 min', '45 min', '60 min'],
          at == null ? 0 : -1, (i) {
        player.setSleepTimer(mins[i] == 0 ? null : Duration(minutes: mins[i]));
      }),
      if (at != null)
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6),
          child: Text('Music will pause at ${hhmm(at)}',
              style: TextStyle(color: t.subtext, fontSize: 13)),
        ),
      _gap,
      GlassCard(
        onTap: () async {
          if (await _confirm(c, 'Clear history?',
              'This clears recently played songs and your taste profile.')) {
            await library.clearHistory();
          }
        },
        child: Row(children: [
          Icon(Icons.history_rounded, color: t.accent),
          const SizedBox(width: 14),
          Text('Clear listening history', style: TextStyle(color: t.text)),
        ]),
      ),
      _gap,
      GlassCard(
        onTap: () async {
          if (await _confirm(c, 'Reset settings?',
              'All settings go back to default. Your songs and playlists stay.')) {
            await settings.reset();
            library.refilter();
            player.applySettings();
          }
        },
        child: Row(children: [
          Icon(Icons.restart_alt_rounded, color: t.accent),
          const SizedBox(width: 14),
          Text('Reset all settings', style: TextStyle(color: t.text)),
        ]),
      ),
      _gap,
      GlassCard(
        child: Text('Musixvoice 1.0.0\nBuilt by Ephraim Sibale',
            style: TextStyle(color: t.subtext, height: 1.5)),
      ),
    ];
  }

  // ---- building blocks ----

  static const Widget _gap = SizedBox(height: 12);

  Future<bool> _confirm(BuildContext c, String title, String text) async {
    final r = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    return r == true;
  }

  Widget _switch(BuildContext c, String title, String sub, bool value,
      ValueChanged<bool> onChanged) {
    final t = ThemeScope.of(c);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.w600)),
            Text(sub, style: TextStyle(color: t.subtext, fontSize: 12)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }

  Widget _slider(BuildContext c, String title, String label, double value, double min,
      double max, int divisions, ValueChanged<double> onChanged,
      {ValueChanged<double>? onEnd}) {
    final t = ThemeScope.of(c);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: t.text, fontSize: 16, fontWeight: FontWeight.w600))),
          Text(label, style: TextStyle(color: t.accent, fontWeight: FontWeight.w600)),
        ]),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          onChangeEnd: onEnd,
        ),
      ]),
    );
  }

  Widget _choice(BuildContext c, String title, List<String> labels, int selected,
      ValueChanged<int> onSelect) {
    final t = ThemeScope.of(c);
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < labels.length; i++)
            ChoiceChip(
              label: Text(labels[i]),
              selected: selected == i,
              onSelected: (_) => onSelect(i),
            ),
        ]),
      ]),
    );
  }
}

// ----------------------------------------------------------- equalizer

class _EqualizerCard extends StatefulWidget {
  const _EqualizerCard();

  @override
  State<_EqualizerCard> createState() => _EqualizerCardState();
}

class _EqualizerCardState extends State<_EqualizerCard> {
  Future<AndroidEqualizerParameters>? _params;

  String _hz(double f) =>
      f >= 1000 ? '${(f / 1000).toStringAsFixed(f % 1000 == 0 ? 0 : 1)} kHz' : '${f.round()} Hz';

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    if (player.current == null) {
      return GlassCard(
        child: Text('Play a song first, then the equalizer bands appear here.',
            style: TextStyle(color: t.subtext)),
      );
    }
    _params ??= player.equalizer.parameters;
    return GlassCard(
      child: FutureBuilder<AndroidEqualizerParameters>(
        future: _params,
        builder: (context, snap) {
          final p = snap.data;
          if (p == null) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2)));
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('Bands',
                      style: TextStyle(
                          color: t.text, fontSize: 16, fontWeight: FontWeight.w600))),
              TextButton(
                onPressed: () async {
                  for (final b in p.bands) {
                    await b.setGain(0);
                  }
                  settings.update(() => settings.eqGains = p.bands.map((b) => b.gain).toList());
                  setState(() {});
                },
                child: const Text('Reset'),
              ),
            ]),
            for (final b in p.bands)
              Row(children: [
                SizedBox(
                    width: 62,
                    child: Text(_hz(b.centerFrequency),
                        style: TextStyle(color: t.subtext, fontSize: 12))),
                Expanded(
                  child: Slider(
                    min: p.minDecibels,
                    max: p.maxDecibels,
                    value: b.gain.clamp(p.minDecibels, p.maxDecibels).toDouble(),
                    onChanged: (v) {
                      b.setGain(v);
                      setState(() {});
                    },
                    onChangeEnd: (_) => settings
                        .update(() => settings.eqGains = p.bands.map((x) => x.gain).toList()),
                  ),
                ),
              ]),
          ]);
        },
      ),
    );
  }
}

// -------------------------------------------------------------- AI key

class _AiKeyCard extends StatefulWidget {
  const _AiKeyCard();

  @override
  State<_AiKeyCard> createState() => _AiKeyCardState();
}

class _AiKeyCardState extends State<_AiKeyCard> {
  late AiProvider _provider = ai.provider;
  late final TextEditingController _key = TextEditingController(text: ai.apiKey);
  bool _saved = false;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI assistant',
            style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
            'Optional. Add your own API key to let the AI describe your taste and build mixes from a mood. The key stays on this phone. Without a key, Musixvoice still learns your genres on-device.',
            style: TextStyle(color: t.subtext, fontSize: 13)),
        const SizedBox(height: 14),
        SegmentedButton<AiProvider>(
          segments: const [
            ButtonSegment(value: AiProvider.deepseek, label: Text('DeepSeek')),
            ButtonSegment(value: AiProvider.claude, label: Text('Claude')),
          ],
          selected: {_provider},
          onSelectionChanged: (s) => setState(() {
            _provider = s.first;
            _saved = false;
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _key,
          obscureText: true,
          style: TextStyle(color: t.text),
          onChanged: (_) => setState(() => _saved = false),
          decoration: InputDecoration(
            hintText: 'API key',
            hintStyle: TextStyle(color: t.subtext),
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            await ai.save(_provider, _key.text);
            setState(() => _saved = true);
          },
          child: Text(_saved ? 'Saved' : 'Save key'),
        ),
      ]),
    );
  }
}
