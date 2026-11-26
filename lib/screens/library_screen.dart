import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';
import '../widgets/glass.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _tabs = ['Songs', 'Albums', 'Artists', 'Favorites', 'Playlists'];
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([library, settings]),
        builder: (context, _) {
          final (count, builder) = _content(context, t);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('My library',
                        style: TextStyle(
                            color: t.text, fontSize: 28, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tabs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ChoiceChip(
                          label: Text(_tabs[i]),
                          selected: _tab == i,
                          onSelected: (_) => setState(() {
                            _tab = i;
                            _query = '';
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_tab == 0 || _tab == 3) _searchBox(t),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, kBottomPad),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(builder, childCount: count),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBox(MvTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TextField(
          key: ValueKey('search$_tab'),
          style: TextStyle(color: t.text),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search in this list',
            hintStyle: TextStyle(color: t.subtext),
            icon: Icon(Icons.search_rounded, color: t.subtext),
          ),
        ),
      ),
    );
  }

  List<Song> _filter(List<Song> songs) {
    if (_query.isEmpty) return songs;
    return songs
        .where((s) =>
            s.title.toLowerCase().contains(_query) ||
            s.artist.toLowerCase().contains(_query) ||
            (s.album ?? '').toLowerCase().contains(_query))
        .toList();
  }

  Widget _message(MvTheme t, String text, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: TextStyle(color: t.subtext, height: 1.4)),
          if (action != null) ...[const SizedBox(height: 10), action],
        ]),
      ),
    );
  }

  (int, IndexedWidgetBuilder) _content(BuildContext context, MvTheme t) {
    switch (_tab) {
      case 0:
        if (!library.permission) {
          return (
            1,
            (_, __) => _message(
                  t,
                  'Allow Musixvoice to read the music on your phone and everything shows up here.',
                  action: FilledButton(
                      onPressed: library.requestAccess,
                      child: const Text('Allow music access')),
                )
          );
        }
        if (library.scanning && library.local.isEmpty) {
          return (
            1,
            (_, __) => const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(strokeWidth: 3)))
          );
        }
        final songs = _filter(library.local);
        if (songs.isEmpty) {
          return (
            1,
            (_, __) => _message(
                  t,
                  library.scanError ??
                      (library.allDevice.isEmpty
                          ? 'No music found on this phone yet.'
                          : 'No songs match. Check Settings > Files & Folder.'),
                  action: TextButton(
                      onPressed: library.scanDevice, child: const Text('Scan again')),
                )
          );
        }
        return (
          songs.length,
          (_, i) => SongTile(song: songs[i], onTap: () => player.playQueue(songs, i)),
        );
      case 1:
        return _groups(t, library.albums, 'No albums yet.');
      case 2:
        return _groups(t, library.artists, 'No artists yet.');
      case 3:
        final favs = _filter(library.favorites);
        if (favs.isEmpty) {
          return (
            1,
            (_, __) => _message(t, 'Tap the heart on a song to save it here.')
          );
        }
        return (
          favs.length,
          (_, i) => SongTile(song: favs[i], onTap: () => player.playQueue(favs, i)),
        );
      default:
        final names = library.playlists.keys.toList();
        return (
          names.length + 1,
          (ctx, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  onTap: () async {
                    final name = await askName(ctx, 'New playlist');
                    if (name != null) await library.createPlaylist(name);
                  },
                  child: Row(children: [
                    Icon(Icons.add_rounded, color: t.accent, size: 30),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Create new playlist',
                          style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
                      Text('Build your own collection',
                          style: TextStyle(color: t.subtext, fontSize: 12)),
                    ]),
                  ]),
                ),
              );
            }
            final name = names[i - 1];
            final songs = library.playlists[name] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                blur: 0,
                onTap: () => showSongList(ctx, name, songs),
                child: Row(children: [
                  Artwork(song: songs.isEmpty ? null : songs.first, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name,
                          style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
                      Text('${songs.length} songs',
                          style: TextStyle(color: t.subtext, fontSize: 12)),
                    ]),
                  ),
                  IconButton(
                    onPressed: songs.isEmpty ? null : () => player.playQueue(songs, 0),
                    icon: Icon(Icons.play_circle_fill_rounded, color: t.accent, size: 34),
                  ),
                  IconButton(
                    onPressed: () => library.deletePlaylist(name),
                    icon: Icon(Icons.delete_outline_rounded, color: t.subtext),
                  ),
                ]),
              ),
            );
          },
        );
    }
  }

  (int, IndexedWidgetBuilder) _groups(
      MvTheme t, Map<String, List<Song>> groups, String empty) {
    if (groups.isEmpty) {
      return (1, (_, __) => _message(t, empty));
    }
    final names = groups.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return (
      names.length,
      (ctx, i) {
        final name = names[i];
        final songs = groups[name]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            blur: 0,
            padding: const EdgeInsets.all(10),
            onTap: () => showSongList(ctx, name, songs),
            child: Row(children: [
              Artwork(song: songs.first, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
                  Text('${songs.length} songs',
                      style: TextStyle(color: t.subtext, fontSize: 12)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: t.subtext),
            ]),
          ),
        );
      },
    );
  }
}
