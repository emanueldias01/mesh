import 'package:flutter/material.dart';
import 'package:mesh/pages/meeting/room_page_arguments.dart';
import 'package:mesh/pages/meeting_lobby/meeting_lobby_page_viewmodel.dart';
import 'package:mesh/ui/colors.dart';
import 'package:mesh/ui/text_styles.dart';
import 'package:mesh/widgets/principal_button.dart';

class MeetingLobbyPage extends StatefulWidget {
  const MeetingLobbyPage({super.key});

  @override
  State<MeetingLobbyPage> createState() => _MeetingLobbyPageState();
}

class _MeetingLobbyPageState extends State<MeetingLobbyPage> {

  final viewmodel = MeetingLobbyPageViewmodel();

  @override
  void initState() {
    super.initState();
    viewmodel.addListener(() {
      setState(() {
        
      });
    });
  }
  @override
  void dispose() {
    viewmodel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Image.asset(
                "assets/images/logo.png",
                height: 100,
              ),

              const SizedBox(height: 30),

              Text(
                "Meeting Lobby",
                textAlign: TextAlign.center,
                style: AppTextStyles.bigText,
              ),

              const SizedBox(height: 8),

              Text(
                "Create a new room or join an existing one.",
                textAlign: TextAlign.center,
                style: AppTextStyles.mediumText.copyWith(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 50),

              Text(
                "Persnonal ID",
                style: AppTextStyles.mediumText,
              ),

              const SizedBox(height: 10),

              TextField(
                controller: viewmodel.callerIdController,
                decoration: InputDecoration(
                  hintText: "Your caller ID",
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),


              Text(
                "Meeting ID",
                style: AppTextStyles.mediumText,
              ),

              const SizedBox(height: 10),

              TextField(
                controller: viewmodel.meetingCodeController,
                decoration: InputDecoration(
                  hintText: "Enter meeting code",
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              

              PrincipalButton(
                text: "Join a Meeting",
                onTap: () async {
                  final foundMeeting = await viewmodel.joinRoom();

                  if(foundMeeting) {
                    Navigator.pushNamed(context, "/room", arguments: RoomPageArguments(roomId: viewmodel.meetingCodeController.text));
                  }else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                        viewmodel.errorMessage,
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      )
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              if (viewmodel.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "OR",
                      style: AppTextStyles.mediumText,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              OutlinedButton.icon(
                onPressed: () async {
                  final createRoom = await viewmodel.createRoom();
                  if(createRoom){
                    Navigator.pushNamed(context, "/room", arguments: RoomPageArguments(roomId: "54321"));
                  }else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(
                        "Failed to create room"
                      ))
                    );
                  }
                  
                },
                icon: const Icon(Icons.video_call),
                label: const Text("Create Meeting"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    60,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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