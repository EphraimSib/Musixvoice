import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';
import '../widgets/glass.dart';
import 'settings_screen.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _mood = TextEditingController();
  String? _vibe;
  bool _busyVibe = false;
  bool _busyMix = false;
  String? _message;

  @override
  void dispose() {
    _mood.dispose();
    super.dispose();
  }

  /// Short text describing what the user has been listening to.
  String _tasteSummary() {
    final g = library.topGenres(5);
    final genres = g.isEmpty
        ? 'no genre data yet'
        : g.map((e) => '${e.key} ${(e.value * 100).round()}%').join(', ');
    final songs = library.recent.take(10).map((s) => '${s.title} by ${s.artist}').join('; ');
    return 'Top genres: $genres. Recent songs: ${songs.isEmpty ? 'none' : songs}.';
  }

  Future<void> _discover() async {
    setState(() {
      _busyVibe = true;
      _message = null;
    });
    try {
      if (ai.hasKey) {
        final text = await ai.ask(
          _tasteSummary(),
          system:
              'You are the music taste analyst inside a music app. In 2 or 3 short sentences, describe the listener\'s music personality and name the genre they fit best. Then on a new last line write SEARCH: followed by 3 comma separated search keywords for songs they would like. Plain text only.',
        );
        setState(() => _vibe = text.split('\n').where((l) => !l.startsWith('SEARCH:')).join('\n').trim());
      } else {
        final g = library.topGenres(3);
        setState(() => _vibe = g.isEmpty
            ? 'Play a few songs from Explore and Musixvoice will learn your taste.'
            : 'You lean toward ${g.map((e) => e.key).join(', ')}. Add an AI key in Settings for a deeper read of your taste.');
      }
    } catch (e) {
      setState(() => _message = 'The AI could not answer. Check your key and connection.');
    } finally {
      if (mounted) setState(() => _busyVibe = false);
    }
  }

  Future<void> _mix(String request) async {
    setState(() {
      _busyMix = true;
      _message = null;
    });
    try {
      var query = request.trim();
      if (ai.hasKey && query.isNotEmpty) {
        final text = await ai.ask(
          'Mood: $query. ${_tasteSummary()}',
          system:
              'You turn a listener\'s mood into search keywords for a music search. Reply with exactly one line: 2 to 4 keywords separated by spaces. No punctuation, no explanation.',
        );
        query = text.split('\n').first.trim();
      }
      List<Song> songs;
      if (query.isEmpty) {
        final top = library.topGenres(1);
        songs = await audius.trending(genre: top.isEmpty ? null : top.first.key);
      } else {
        songs = await audius.search(query);
      }
      if (songs.isEmpty) {
        setState(() => _message = 'No songs found for that mood. Try other words.');
      } else {
        await player.playQueue(songs, 0);
      }
    } catch (_) {
      setState(() => _message = 'Could not build the mix. Check your connection.');
    } finally {
      if (mounted) setState(() => _busyMix = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([library, ai]),
        builder: (context, _) {
          final genres = library.topGenres(5);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, kBottomPad),
            children: [
              Text('AI',
                  style: TextStyle(color: t.text, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  ai.hasKey
                      ? 'Connected. Ask for a mood and get a mix.'
                      : 'Running on-device. Add a key in Settings for full AI.',
                  style: TextStyle(color: t.subtext)),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your taste',
                      style: TextStyle(
                          color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (genres.isEmpty)
                    Text('Genres you play will show up here.',
                        style: TextStyle(color: t.subtext))
                  else
                    for (final g in genres)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          SizedBox(
                              width: 92,
                              child: Text(g.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: t.text, fontSize: 13))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: g.value,
                                minHeight: 10,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation(t.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(g.value * 100).round()}%',
                              style: TextStyle(color: t.subtext, fontSize: 12)),
                        ]),
                      ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _busyVibe ? null : _discover,
                    icon: _busyVibe
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Discover my genre'),
                  ),
                  if (_vibe != null) ...[
                    const SizedBox(height: 12),
                    Text(_vibe!, style: TextStyle(color: t.text, height: 1.4)),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mood mix',
                      style: TextStyle(
                          color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Describe how you feel, like "rainy night drive".',
                      style: TextStyle(color: t.subtext, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mood,
                    style: TextStyle(color: t.text),
                    onSubmitted: _mix,
                    decoration: InputDecoration(
                      hintText: 'What is the mood?',
                      hintStyle: TextStyle(color: t.subtext),
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _busyMix ? null : () => _mix(_mood.text),
                        child: Text(_busyMix ? 'Building...' : 'Play my mix'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _busyMix ? null : () => _mix(''),
                      child: const Text('Surprise me'),
                    ),
                  ]),
                ]),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(_message!, style: const TextStyle(color: Color(0xFFFFB4AB))),
                ),
              if (!ai.hasKey)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsPage(index: 7, title: 'AI Assistant'))),
                    child: const Text('Add an AI key'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
