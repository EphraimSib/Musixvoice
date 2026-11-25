import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';
import '../widgets/glass.dart';
import '../widgets/visualizer.dart';
import 'settings_screen.dart';

void openNowPlaying(BuildContext context) {
  if (player.current == null) return;
  Navigator.of(context).push(PageRouteBuilder(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => const NowPlayingScreen(),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(anim),
      child: child,
    ),
  ));
}

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);
  double? _drag;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([player, library]),
            builder: (context, _) {
              final s = player.current;
              if (s == null) return const SizedBox.shrink();
              final fav = library.isFavorite(s);
              final circle = settings.artShape == 1;
              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                child: Column(children: [
                  Row(children: [
                    GlassIcon(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onTap: () => Navigator.pop(context)),
                    Expanded(
                      child: Column(children: [
                        Text('Now playing',
                            style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
                        Text(s.isLocal ? 'On this device' : 'Online',
                            style: TextStyle(color: t.subtext, fontSize: 12)),
                      ]),
                    ),
                    GlassIcon(
                        icon: Icons.palette_rounded,
                        onTap: () => showThemePicker(context)),
                  ]),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final viz = settings.visualizerOn;
                        final room = c.maxHeight - (viz ? 76 : 16);
                        final size = (room < c.maxWidth ? room : c.maxWidth)
                            .clamp(120.0, 340.0)
                            .toDouble();
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, child) {
                                final glow = settings.animations && player.playing
                                    ? 0.25 + _pulse.value * 0.35
                                    : 0.15;
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(circle ? size / 2 : 34),
                                    boxShadow: [
                                      BoxShadow(
                                          color: t.accent.withOpacity(glow),
                                          blurRadius: 50,
                                          spreadRadius: 4),
                                    ],
                                  ),
                                  child: child,
                                );
                              },
                              child: Artwork(
                                  song: s,
                                  size: size,
                                  radius: circle ? size / 2 : 32),
                            ),
                            if (viz) ...[
                              const SizedBox(height: 14),
                              AudioVisualizer(
                                playing: player.playing,
                                color: t.accent,
                                color2: t.accent2,
                                style: settings.visualizerStyle,
                                bars: settings.visualizerBars,
                                height: 50,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(s.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: t.subtext, fontSize: 15)),
                        ],
                      ),
                    ),
                    GlassIcon(
                      icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: fav ? t.accent : t.text,
                      onTap: () => library.toggleFavorite(s),
                    ),
                  ]),
                  if (player.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(player.error!,
                          style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 13)),
                    ),
                  const SizedBox(height: 14),
                  _SeekBar(
                    onDrag: (v) => setState(() => _drag = v),
                    drag: _drag,
                    onEnd: (v) {
                      player.seek(Duration(milliseconds: v.round()));
                      setState(() => _drag = null);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: player.toggleShuffle,
                        icon: Icon(Icons.shuffle_rounded,
                            color: player.shuffle ? t.accent : t.subtext),
                      ),
                      IconButton(
                        iconSize: 36,
                        onPressed: player.previous,
                        icon: Icon(Icons.skip_previous_rounded, color: t.text),
                      ),
                      GestureDetector(
                        onTap: player.toggle,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: player.loading
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(strokeWidth: 3))
                              : Icon(
                                  player.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 42,
                                  color: t.background[2]),
                        ),
                      ),
                      IconButton(
                        iconSize: 36,
                        onPressed: player.next,
                        icon: Icon(Icons.skip_next_rounded, color: t.text),
                      ),
                      IconButton(
                        onPressed: player.cycleLoop,
                        icon: Icon(
                            player.loop == LoopMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: player.loop == LoopMode.off ? t.subtext : t.accent),
                      ),
                    ],
                  ),
                  if (settings.showQuickBar) ...[
                    const SizedBox(height: 14),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showQueue(context),
                            icon: Icon(Icons.queue_music_rounded, color: t.text),
                            label: Text('Up next', style: TextStyle(color: t.text)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              exploreRequest.value = ExploreRequest(
                                  genre: s.genre,
                                  query: s.genre == null ? s.artist : null);
                              navIndex.value = 1;
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.auto_awesome_rounded, color: t.accent),
                            label: Text('More like this', style: TextStyle(color: t.text)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final t = ThemeScope.of(ctx);
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.background[1].withOpacity(0.97),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: player.queue.length,
            itemBuilder: (_, i) {
              final q = player.queue[i];
              final cur = i == player.index;
              return ListTile(
                leading: Artwork(song: q, size: 44, radius: 10),
                title: Text(q.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cur ? t.accent : t.text)),
                subtitle: Text(q.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.subtext)),
                onTap: () {
                  player.playIndex(i);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _SeekBar extends StatelessWidget {
  final double? drag;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onEnd;
  const _SeekBar({required this.drag, required this.onDrag, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durSnap) {
        final total = (durSnap.data ?? Duration.zero).inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, posSnap) {
            final pos = (posSnap.data ?? Duration.zero).inMilliseconds.toDouble();
            final value = (drag ?? pos).clamp(0.0, total > 0 ? total : 1.0).toDouble();
            return Column(children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  activeTrackColor: t.accent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: t.accent.withOpacity(0.2),
                ),
                child: Slider(
                  min: 0,
                  max: total > 0 ? total : 1,
                  value: value,
                  onChanged: total > 0 ? onDrag : null,
                  onChangeEnd: onEnd,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatDuration(Duration(milliseconds: value.round())),
                        style: TextStyle(color: t.subtext, fontSize: 12)),
                    Text(formatDuration(Duration(milliseconds: total.round())),
                        style: TextStyle(color: t.subtext, fontSize: 12)),
                  ],
                ),
              ),
            ]);
          },
        );
      },
    );
  }
}
