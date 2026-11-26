import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';
import '../widgets/glass.dart';
import '../widgets/song_tile.dart';
import 'settings_screen.dart';

const _categories = <(String, IconData, String)>[
  ('Pop', Icons.music_note_rounded, 'Pop'),
  ('Lo-Fi', Icons.cloud_rounded, 'Lo-Fi'),
  ('Electronic', Icons.bolt_rounded, 'Electronic'),
  ('Hip-Hop', Icons.mic_external_on_rounded, 'Hip-Hop/Rap'),
  ('Ambient', Icons.spa_rounded, 'Ambient'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Song>> _trending = audius.trending();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, kBottomPad),
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_greeting, style: TextStyle(color: t.subtext, fontSize: 15)),
                Text('Musixvoice',
                    style: TextStyle(
                        color: t.text, fontSize: 30, fontWeight: FontWeight.w700)),
              ]),
            ),
            GlassIcon(
              icon: Icons.tune_rounded,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ]),
          const SizedBox(height: 18),
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () => navIndex.value = 1,
            child: Row(children: [
              Icon(Icons.search_rounded, color: t.subtext),
              const SizedBox(width: 10),
              Text('Search songs, artists...', style: TextStyle(color: t.subtext)),
            ]),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Song>>(
            future: _trending,
            builder: (context, snap) => _HeroCard(
              songs: snap.data,
              loading: snap.connectionState != ConnectionState.done,
              failed: snap.hasError,
              onRetry: () => setState(() => _trending = audius.trending()),
            ),
          ),
          const SizedBox(height: 24),
          Text('Categories',
              style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final c = _categories[i];
                return GestureDetector(
                  onTap: () {
                    exploreRequest.value = ExploreRequest(genre: c.$3);
                    navIndex.value = 1;
                  },
                  child: SizedBox(
                    width: 68,
                    child: Column(children: [
                      GlassCard(
                        radius: 34,
                        padding: EdgeInsets.zero,
                        child: SizedBox(
                            width: 60,
                            height: 60,
                            child: Icon(c.$2, color: t.accent)),
                      ),
                      const SizedBox(height: 6),
                      Text(c.$1, style: TextStyle(color: t.text, fontSize: 12)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text('Recently played',
              style: TextStyle(color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: library,
            builder: (context, _) {
              if (library.recent.isEmpty) {
                return GlassCard(
                  child: Text(
                      'Nothing yet. Play something from Explore or add songs from your phone in Library.',
                      style: TextStyle(color: t.subtext)),
                );
              }
              final items = library.recent.take(6).toList();
              return Column(children: [
                for (var i = 0; i < items.length; i++)
                  SongTile(song: items[i], onTap: () => player.playQueue(items, i)),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final List<Song>? songs;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  const _HeroCard(
      {required this.songs,
      required this.loading,
      required this.failed,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    final list = songs ?? const <Song>[];
    final pick = list.isEmpty ? null : list.first;

    if (pick == null) {
      return GlassCard(
        radius: 26,
        padding: const EdgeInsets.all(22),
        child: SizedBox(
          height: 120,
          child: Center(
            child: loading
                ? const CircularProgressIndicator(strokeWidth: 3)
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                        failed
                            ? 'You are offline. Your imported songs still play from Library.'
                            : 'No trending songs right now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.subtext)),
                    TextButton(onPressed: onRetry, child: const Text('Try again')),
                  ]),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(children: [
        Positioned.fill(child: Artwork(song: pick, size: 400, radius: 0)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
              ),
            ),
          ),
        ),
        Container(
          height: 210,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Trending this week',
                  style: TextStyle(color: t.accent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pick.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.1)),
                    Text(pick.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70)),
                  ]),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => player.playQueue(list, 0),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration:
                        const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.play_arrow_rounded,
                        color: t.background[2], size: 34),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
