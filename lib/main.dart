import 'package:flutter/cupertino.dart';
import 'package:mesh/app.dart';
import 'package:mesh/database/database.dart';
import 'package:mesh/pages/room/room_page_viewmodel.dart';
import 'package:mesh/pages/meeting_lobby/meeting_lobby_page_viewmodel.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await $FloorMeshDatabase
      .databaseBuilder('app_database.db')
      .build();

  runApp(
    MultiProvider(
      providers: [
        Provider<MeshDatabase>(create: (_) => database),
        ChangeNotifierProvider(create: (_) => RoomPageViewmodel()),
        ChangeNotifierProvider(
          create: (_) => MeetingLobbyPageViewmodel(database.addressDao),
        ),
      ],
      child: const App(),
    ),
  );
}