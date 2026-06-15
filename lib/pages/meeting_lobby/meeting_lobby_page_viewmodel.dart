
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mesh/constants/env.dart';

class MeetingLobbyPageViewmodel extends ChangeNotifier{
  final meetingCodeController = TextEditingController();
  final callerIdController = TextEditingController();

  bool isLoading = false;

  String errorMessage = "";


  Future<bool> joinRoom() async {
  isLoading = true;
  errorMessage = "";
  notifyListeners();

  if (callerIdController.text.isEmpty) {
    errorMessage = "Your caller ID is empty";
    isLoading = false;
    notifyListeners();
    return false;
  }

  try {
    final url = Uri.parse('${Env.apiUrl}/rooms/${meetingCodeController.text}');
    
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      isLoading = false;
      errorMessage = "";
      notifyListeners();
      return true;
    } else if (response.statusCode == 404) {
      isLoading = false;
      meetingCodeController.text = "";
      errorMessage = "No rooms found";
      notifyListeners();
      return false;
    } else {
      isLoading = false;
      meetingCodeController.text = "";
      errorMessage = "Internal Server error: ${response.statusCode}";
      notifyListeners();
      return false;
    }
  } catch (error) {
    isLoading = false;
    meetingCodeController.text = "";
    errorMessage = "Connection error. Please try again.";
    notifyListeners();
    return false;
  }
}


  Future<bool> createRoom() async {
    isLoading = true;
    notifyListeners();
    errorMessage = "";

    if (callerIdController.text.isEmpty) {
      errorMessage = "Your caller ID is empty";
      isLoading = false;
      notifyListeners();
      return false;
    }
    
    try {
      final url = Uri.parse('${Env.apiUrl}/rooms');

      final response = await http.post(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) {
        isLoading = false;
        errorMessage = "";
        notifyListeners();
        return true;
      } else {
        isLoading = false;
        meetingCodeController.text = "";
        errorMessage = "Internal Server error: ${response.statusCode}";
        notifyListeners();
        return false;
      }
    } catch (error) {
      isLoading = false;
      meetingCodeController.text = "";
      errorMessage = "Connection error. Please try again.";
      notifyListeners();
      return false;
    }
  }
}