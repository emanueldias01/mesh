import 'package:flutter/cupertino.dart';
import 'package:mesh/pages/meeting_lobby/meeting_lobby_page.dart';
import 'package:mesh/pages/splash/splash_page.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    "/splash" : (context) => const SplashPage(),
    "/meeting_lobby": (context) => const MeetingLobbyPage()
  };
}