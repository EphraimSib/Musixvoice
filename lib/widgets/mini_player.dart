import 'package:flutter/material.dart';
import '../screens/now_playing_screen.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';
import 'glass.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final s = player.current;
        if (s == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(8),
            onTap: () => openNowPlaying(context),
            child: Row(children: [
              Artwork(song: s, size: 44, radius: 12),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: t.text, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(player.error ?? s.artist,
                        maxLines: player.error != null ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.subtext, fontSize: 12)),
                  ],
                ),
              ),
              if (player.loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                IconButton(
                  onPressed: player.toggle,
                  icon: Icon(
                      player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: t.text,
                      size: 30),
                ),
              IconButton(
                onPressed: player.next,
                icon: Icon(Icons.skip_next_rounded, color: t.text),
              ),
            ]),
          ),
        );
      },
    );
  }
}
