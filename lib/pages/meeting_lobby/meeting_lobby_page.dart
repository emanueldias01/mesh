import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mesh/ui/text_styles.dart';

class MeetingLobbyPage extends StatelessWidget {
  const MeetingLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mesh", style: AppTextStyles.mediumText),
      ),

      body: Center(
        child: Text("Meeting Lobby", style: AppTextStyles.bigText),
      ),
    );
  }
}