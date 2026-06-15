
import 'package:flutter/cupertino.dart';
import 'package:mesh/app.dart';
import 'package:mesh/pages/meeting/room_page_viewmodel.dart';
import 'package:mesh/pages/meeting_lobby/meeting_lobby_page_viewmodel.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoomPageViewmodel()),
        ChangeNotifierProvider(create: (_) => MeetingLobbyPageViewmodel())
      ],
      child: const App(),
    ),
  );
}