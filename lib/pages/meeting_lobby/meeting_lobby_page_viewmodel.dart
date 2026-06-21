import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mesh/database/dao/address_dao.dart';
import 'package:mesh/database/models/address.dart';

class MeetingLobbyPageViewmodel extends ChangeNotifier {
  final AddressDao _addressDao;

  final roomCodeController = TextEditingController();
  final callerIdController = TextEditingController();
  final signalServerAddressController = TextEditingController();

  List<Address> signalServers = [];
  Address? selectedServer;
  bool isLoading = false;
  bool isLoadingServers = false;
  String errorMessage = "";

  MeetingLobbyPageViewmodel(this._addressDao) {
    loadSignalServers();
  }

  Future<void> loadSignalServers() async {
    isLoadingServers = true;
    notifyListeners();

    try {
      signalServers = await _addressDao.findAllAddress();
    } catch (_) {
      signalServers = [];
    }

    isLoadingServers = false;
    notifyListeners();
  }

  Future<void> addServerAddress() async {
    final addressText = signalServerAddressController.text.trim();
    if (addressText.isEmpty) return;

    final newAddress = Address(address: addressText, id: null);
    await _addressDao.insertAddress(newAddress);
    signalServerAddressController.clear();
    await loadSignalServers();
  }

  Future<void> removeAddressById(int id) async {
    await _addressDao.deleteAddressById(id);

    if (selectedServer?.id == id) {
      selectedServer = null;
    }

    await loadSignalServers();
  }

  void selectSignalServer(Address address) {
    selectedServer = address;
    notifyListeners();
  }

  Future<bool> joinRoom() async {
    if (selectedServer == null) {
      errorMessage = "Please select a signal server address first";
      notifyListeners();
      return false;
    }

    if (callerIdController.text.isEmpty) {
      errorMessage = "Your caller ID is empty";
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = "";
    notifyListeners();

    try {
      final url = Uri.parse(
        '${selectedServer!.address}/rooms/${roomCodeController.text}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        isLoading = false;
        errorMessage = "";
        notifyListeners();
        return true;
      } else if (response.statusCode == 404) {
        isLoading = false;
        roomCodeController.text = "";
        errorMessage = "No rooms found";
        notifyListeners();
        return false;
      } else {
        isLoading = false;
        roomCodeController.text = "";
        errorMessage = "Internal Server error: ${response.statusCode}";
        notifyListeners();
        return false;
      }
    } catch (error) {
      isLoading = false;
      roomCodeController.text = "";
      errorMessage = "Connection error. Please try again.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> createRoom() async {
    if (selectedServer == null) {
      errorMessage = "Please select a signal server address first";
      notifyListeners();
      return false;
    }

    if (callerIdController.text.isEmpty) {
      errorMessage = "Your caller ID is empty";
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = "";
    notifyListeners();

    try {
      final url = Uri.parse('${selectedServer!.address}/rooms');
      final response = await http.post(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['roomId'] != null) {
          roomCodeController.text = data['roomId'].toString();
        }

        isLoading = false;
        errorMessage = "";
        notifyListeners();
        return true;
      } else {
        isLoading = false;
        roomCodeController.text = "";
        errorMessage = "Internal Server error: ${response.statusCode}";
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      roomCodeController.text = "";
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    roomCodeController.dispose();
    callerIdController.dispose();
    signalServerAddressController.dispose();
    super.dispose();
  }
}