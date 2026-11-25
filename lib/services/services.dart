import 'package:flutter/foundation.dart';
import '../theme/app_themes.dart';
import 'ai_service.dart';
import 'audius_service.dart';
import 'library_service.dart';
import 'player_service.dart';
import 'settings_service.dart';

final themeController = ThemeController();
final settings = AppSettings();
final library = LibraryService();
final player = PlayerService();
final audius = AudiusService();
final ai = AiService();

/// Bottom tab currently shown (0 Home, 1 Explore, 2 Library, 3 AI).
final navIndex = ValueNotifier<int>(0);

class ExploreRequest {
  final String? genre;
  final String? query;
  const ExploreRequest({this.genre, this.query});
}

/// Lets other screens ask Explore to run a search or genre.
final exploreRequest = ValueNotifier<ExploreRequest?>(null);
