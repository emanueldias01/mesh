import 'package:flutter/material.dart';
import 'package:mesh/pages/meeting/room_page_arguments.dart';

class RoomPage extends StatelessWidget {
  const RoomPage({super.key});

  @override
  Widget build(BuildContext context) {

    final args = ModalRoute.of(context)!.settings.arguments as RoomPageArguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(args.roomId),
      ),
    );
  }
}