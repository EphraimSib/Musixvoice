import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';
import '../widgets/glass.dart';
import '../widgets/song_tile.dart';

const _genres = [
  'Trending', 'Pop', 'Lo-Fi', 'Electronic', 'Hip-Hop/Rap', 'Ambient', 'Jazz', 'R&B/Soul', 'Rock', 'Chill'
];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _controller = TextEditingController();
  List<Song> _results = [];
  bool _loading = false;
  String? _error;
  String _label = 'Trending';

  @override
  void initState() {
    super.initState();
    exploreRequest.addListener(_onRequest);
    _onRequest();
    if (_results.isEmpty && !_loading) _run(() => audius.trending(), 'Trending');
  }

  @override
  void dispose() {
    exploreRequest.removeListener(_onRequest);
    _controller.dispose();
    super.dispose();
  }

  void _onRequest() {
    final r = exploreRequest.value;
    if (r == null) return;
    exploreRequest.value = null;
    if (r.query != null && r.query!.isNotEmpty) {
      _controller.text = r.query!;
      _search(r.query!);
    } else if (r.genre != null) {
      _controller.clear();
      _genre(r.genre!);
    }
  }

  Future<void> _run(Future<List<Song>> Function() job, String label) async {
    setState(() {
      _loading = true;
      _error = null;
      _label = label;
    });
    try {
      final r = await job();
      if (!mounted) return;
      setState(() {
        _results = r;
        if (r.isEmpty) _error = 'No songs found. Try different words.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _error = 'Could not reach the music service. Check your internet connection.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String q) {
    if (q.trim().isEmpty) return;
    _run(() => audius.search(q.trim()), 'Results for "${q.trim()}"');
  }

  void _genre(String g) => _run(
      () => g == 'Trending' ? audius.trending() : audius.trending(genre: g), g);

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Explore',
                style: TextStyle(color: t.text, fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GlassCard(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: t.text),
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search songs, artists...',
                  hintStyle: TextStyle(color: t.subtext),
                  icon: Icon(Icons.search_rounded, color: t.subtext),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _genres.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(_genres[i]),
                  selected: _label == _genres[i],
                  onSelected: (_) {
                    _controller.clear();
                    _genre(_genres[i]);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: t.subtext)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, kBottomPad),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => SongTile(
                        song: _results[i],
                        onTap: () => player.playQueue(_results, i),
                      ),
                    ),
        ),
      ]),
    );
  }
}
