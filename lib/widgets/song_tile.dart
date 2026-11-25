import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';
import 'glass.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const SongTile({super.key, required this.song, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: settings.compactList ? 6 : 10),
      child: ListenableBuilder(
        listenable: Listenable.merge([player, library]),
        builder: (context, _) {
          final isCurrent = player.current?.id == song.id;
          final fav = library.isFavorite(song);
          final compact = settings.compactList;
          return GlassCard(
            padding: EdgeInsets.all(compact ? 6 : 10),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Row(
              children: [
                Artwork(song: song, size: compact ? 40 : 52, radius: compact ? 10 : 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isCurrent ? t.accent : t.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(children: [
                        if (song.isLocal)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.download_done_rounded,
                                size: 14, color: t.subtext),
                          ),
                        Expanded(
                          child: Text(song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: t.subtext, fontSize: 13)),
                        ),
                      ]),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => library.toggleFavorite(song),
                  icon: Icon(
                      fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: fav ? t.accent : t.subtext),
                ),
                IconButton(
                  onPressed: () => showAddToPlaylist(context, song),
                  icon: Icon(Icons.playlist_add_rounded, color: t.subtext),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> showAddToPlaylist(BuildContext context, Song song) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final t = ThemeScope.of(ctx);
      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.background[1].withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: library,
            builder: (context, _) => ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Add to playlist',
                      style: TextStyle(
                          color: t.text, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                ListTile(
                  leading: Icon(Icons.add_rounded, color: t.accent),
                  title: Text('New playlist', style: TextStyle(color: t.text)),
                  onTap: () async {
                    final name = await askName(ctx, 'New playlist');
                    if (name != null && name.trim().isNotEmpty) {
                      await library.createPlaylist(name);
                      await library.addToPlaylist(name.trim(), song);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                ),
                for (final name in library.playlists.keys)
                  ListTile(
                    leading: Icon(Icons.queue_music_rounded, color: t.subtext),
                    title: Text(name, style: TextStyle(color: t.text)),
                    onTap: () async {
                      await library.addToPlaylist(name, song);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<String?> askName(BuildContext context, String title) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, maxLength: 40),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Create')),
      ],
    ),
  );
}

/// Bottom sheet showing a list of songs (an album, artist or playlist).
void showSongList(BuildContext context, String title, List<Song> songs) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final t = ThemeScope.of(ctx);
      return Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.background[1].withOpacity(0.97),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: t.text, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            if (songs.isNotEmpty)
              IconButton(
                onPressed: () {
                  player.playQueue(songs, 0);
                  Navigator.pop(ctx);
                },
                icon: Icon(Icons.play_circle_fill_rounded, color: t.accent, size: 36),
              ),
          ]),
          Text('${songs.length} songs', style: TextStyle(color: t.subtext, fontSize: 12)),
          const SizedBox(height: 10),
          Expanded(
            child: songs.isEmpty
                ? Center(
                    child: Text('Empty. Add songs with the playlist button on any song.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.subtext)))
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (_, i) => SongTile(
                      song: songs[i],
                      onTap: () {
                        player.playQueue(songs, i);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
          ),
        ]),
      );
    },
  );
}
