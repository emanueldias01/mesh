
import 'package:flutter/material.dart';

class MeetingLobbyPageViewmodel extends ChangeNotifier{
  final meetingCodeController = TextEditingController();

  bool isLoading = false;

  String errorMessage = "";


  Future<bool> joinMeeting() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if(meetingCodeController.text == "12345") {
      isLoading = false;
      errorMessage = "";
      notifyListeners();
        
      return true;
    }else {
      isLoading = false;
      meetingCodeController.text = "";
      notifyListeners();
      errorMessage = "No rooms found";
      return false;
    }

  }
}