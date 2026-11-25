import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MvTheme {
  final String id;
  final String name;
  final List<Color> background; // 3-stop gradient
  final Color accent;
  final Color accent2;
  final Color glass; // glass panel tint
  final Color glassBorder;
  final Color text;
  final Color subtext;

  const MvTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.accent,
    required this.accent2,
    this.glass = const Color(0x2EFFFFFF),
    this.glassBorder = const Color(0x40FFFFFF),
    this.text = Colors.white,
    this.subtext = const Color(0xB3FFFFFF),
  });
}

class MvThemes {
  static const aurora = MvTheme(
    id: 'aurora',
    name: 'Aurora',
    background: [Color(0xFFA9B4F7), Color(0xFF8C7BE8), Color(0xFF6A58D0)],
    accent: Color(0xFFD7C6FF),
    accent2: Color(0xFF8FD6FF),
  );
  static const neon = MvTheme(
    id: 'neon',
    name: 'Neon Grid',
    background: [Color(0xFF07020F), Color(0xFF1B0B3D), Color(0xFF08394D)],
    accent: Color(0xFF00F5D4),
    accent2: Color(0xFFFF2BD6),
    glass: Color(0x1FFFFFFF),
    glassBorder: Color(0x3300F5D4),
  );
  static const sunset = MvTheme(
    id: 'sunset',
    name: 'Sunset',
    background: [Color(0xFFFF9A8B), Color(0xFFD4509B), Color(0xFF5B2A86)],
    accent: Color(0xFFFFD27D),
    accent2: Color(0xFFFFFFFF),
  );
  static const emerald = MvTheme(
    id: 'emerald',
    name: 'Emerald',
    background: [Color(0xFF021B1A), Color(0xFF053B33), Color(0xFF0B6B55)],
    accent: Color(0xFF5CFFB1),
    accent2: Color(0xFFB8FFE3),
    glass: Color(0x1FFFFFFF),
  );
  static const midnight = MvTheme(
    id: 'midnight',
    name: 'Midnight',
    background: [Color(0xFF0B1020), Color(0xFF141B3A), Color(0xFF1F2A5C)],
    accent: Color(0xFF7AA2FF),
    accent2: Color(0xFFB9C8FF),
    glass: Color(0x1AFFFFFF),
  );
  static const rose = MvTheme(
    id: 'rose',
    name: 'Rose Quartz',
    background: [Color(0xFFF8B6D2), Color(0xFFC084FC), Color(0xFF7C5CFF)],
    accent: Color(0xFFFFE3F1),
    accent2: Color(0xFFFFFFFF),
  );
  static const solar = MvTheme(
    id: 'solar',
    name: 'Solar',
    background: [Color(0xFF140A00), Color(0xFF3A1D00), Color(0xFF7A4300)],
    accent: Color(0xFFFFB347),
    accent2: Color(0xFFFFE0A3),
    glass: Color(0x1AFFFFFF),
  );

  static const all = [aurora, neon, sunset, emerald, midnight, rose, solar];

  static MvTheme byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => aurora);
}

class ThemeController extends ChangeNotifier {
  MvTheme theme = MvThemes.aurora;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    theme = MvThemes.byId(prefs.getString('theme'));
  }

  Future<void> set(MvTheme t) async {
    theme = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', t.id);
  }
}

/// Gives every widget below access to the current theme and rebuilds it
/// when the theme (or any setting passed as [extra]) changes.
class ThemeScope extends InheritedNotifier<Listenable> {
  final ThemeController controller;

  ThemeScope({
    super.key,
    required this.controller,
    required Listenable extra,
    required super.child,
  }) : super(notifier: Listenable.merge([controller, extra]));

  static MvTheme of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ThemeScope>()!
      .controller
      .theme;
}
