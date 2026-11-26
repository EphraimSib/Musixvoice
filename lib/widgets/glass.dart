import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/device_media.dart';
import '../services/services.dart';
import '../theme/app_themes.dart';

/// Space kept free at the bottom of scrolling pages for the mini player + nav bar.
const double kBottomPad = 190;

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: t.background,
        ),
      ),
      child: Stack(
        children: [
          if (settings.glow) ...[
            Positioned(
              top: -80,
              right: -60,
              child: _Glow(color: t.accent.withOpacity(0.35), size: 280),
            ),
            Positioned(
              bottom: 120,
              left: -90,
              child: _Glow(color: t.accent2.withOpacity(0.25), size: 300),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      );
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double? blur;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.blur,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    final r = BorderRadius.circular(radius);
    final b = blur ?? settings.blur;
    final panel = Material(
      color: t.glass,
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: BorderSide(color: t.glassBorder),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: r,
        child: Padding(padding: padding, child: child),
      ),
    );
    return ClipRRect(
      borderRadius: r,
      child: b <= 0
          ? panel
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: b, sigmaY: b),
              child: panel,
            ),
    );
  }
}

/// Round glass icon button.
class GlassIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  const GlassIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    return GlassCard(
      radius: size / 2,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: color ?? t.text, size: size * 0.5),
      ),
    );
  }
}

/// Cover art: real artwork if there is one, otherwise a generated gradient.
class Artwork extends StatelessWidget {
  final Song? song;
  final double size;
  final double radius;
  const Artwork({super.key, required this.song, this.size = 56, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    final seed = (song?.title ?? 'musixvoice').hashCode;
    final h1 = (seed % 360).abs().toDouble();
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, h1, 0.7, 0.55).toColor(),
            HSLColor.fromAHSL(1, (h1 + 60) % 360, 0.7, 0.35).toColor(),
          ],
        ),
      ),
      child: Icon(Icons.music_note_rounded,
          color: Colors.white.withOpacity(0.85), size: size * 0.42),
    );
    final url = song?.artUrl;
    Widget content;
    if (song != null && song!.isLocal) {
      content = FutureBuilder<String?>(
        future: DeviceMedia.thumb(song!),
        builder: (context, snap) {
          final path = snap.data;
          if (path == null) return fallback;
          return Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 2).round(),
            errorBuilder: (_, __, ___) => fallback,
          );
        },
      );
    } else if (url == null) {
      content = fallback;
    } else {
      content = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, p) => p == null ? child : fallback,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: content),
    );
  }
}

String formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
