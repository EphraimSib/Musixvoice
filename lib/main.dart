import 'services/player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'screens/ai_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'services/device_media.dart';
import 'services/services.dart';
import 'theme/app_themes.dart';
import 'widgets/glass.dart';
import 'widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.musixvoice.playback',
    androidNotificationChannelName: 'Musixvoice playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'drawable/ic_notification',
  );
  await Future.wait([
    themeController.load(),
    settings.load(),
    library.load(),
    ai.load(),
  ]);
  await DeviceMedia.init();
  player = PlayerService(
    withEffects: settings.eqEnabled || settings.loudnessGain > 0,
  );
  library.settings = settings;
  player.settings = settings;
  player.onTrackStarted = library.recordPlay;
  player.applySettings();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MusixvoiceApp());
}

class MusixvoiceApp extends StatelessWidget {
  const MusixvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: themeController,
      extra: settings,
      child: Builder(
        builder: (context) {
          final t = ThemeScope.of(context);
          return MaterialApp(
            title: 'Musixvoice',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              fontFamily: 'NotoSans',
              colorScheme: ColorScheme.fromSeed(
                seedColor: t.accent,
                brightness: Brightness.dark,
              ).copyWith(primary: t.accent, onPrimary: t.background[2]),
              scaffoldBackgroundColor: Colors.transparent,
              chipTheme: ChipThemeData(
                backgroundColor: t.glass,
                selectedColor: Colors.white.withOpacity(0.3),
                labelStyle: TextStyle(color: t.text),
                secondaryLabelStyle: TextStyle(color: t.text),
                checkmarkColor: t.text,
                side: BorderSide(color: t.glassBorder),
                shape: const StadiumBorder(),
              ),
            ),
            home: const Shell(),
          );
        },
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  static const _pages = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    LibraryScreen(),
    AiScreen(),
  ];

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
    (Icons.library_music_outlined, Icons.library_music_rounded, 'Library'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'AI'),
  ];

  @override
  void initState() {
    super.initState();
    // Ask for music access on first run, then read the music on the phone.
    WidgetsBinding.instance.addPostFrameCallback((_) => library.initAccess());
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeScope.of(context);
    final visible = <int>[
      0,
      if (settings.showExploreTab) 1,
      2,
      if (settings.showAiTab) 3,
    ];
    return Scaffold(
      body: AppBackground(
        child: ValueListenableBuilder<int>(
          valueListenable: navIndex,
          builder: (context, index, _) => Stack(
            children: [
              IndexedStack(index: index, children: _pages),
              Positioned(
                left: 14,
                right: 14,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (settings.showMiniPlayer) const MiniPlayer(),
                      GlassCard(
                        radius: 28,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            for (final i in visible)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => navIndex.value = i,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: index == i
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(index == i ? _items[i].$2 : _items[i].$1,
                                        color: index == i ? t.text : t.subtext),
                                    Text(_items[i].$3,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: index == i ? t.text : t.subtext)),
                                  ]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
