import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatMessage {
  final String from;
  final String text;
  ChatMessage({required this.from, required this.text});
}

class RoomPageViewmodel extends ChangeNotifier with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  String _roomId = "";
  String _userId = "";
  String _serverAddress = "";

  bool isLoading = false;
  String errorMessage = "";

  final List<ChatMessage> mensagens = [];

  MediaStream? localStream;
  bool isAudioEnabled = true;
  bool isVideoEnabled = true;
  bool _wasVideoEnabledBeforeBackground = true;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> remoteStreams = {};

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  RoomPageViewmodel() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool get isConnected => _channel != null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (localStream == null || !isConnected) return;

    if (state == AppLifecycleState.paused) {
      _wasVideoEnabledBeforeBackground = isVideoEnabled;
      if (isVideoEnabled) {
        _setVideoTrackEnabled(false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasVideoEnabledBeforeBackground) {
        _setVideoTrackEnabled(true);
      }
      notifyListeners();
    }
  }

  void _setVideoTrackEnabled(bool enabled) {
    localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
    isVideoEnabled = enabled;
    notifyListeners();
  }

  Future<void> connectRoom(String serverAddres,String roomId, String userId) async {
    isLoading = true;
    errorMessage = "";
    notifyListeners();

    _serverAddress = serverAddres;
    _roomId = roomId;
    _userId = userId;

    try {
      await _initLocalMedia();

      final wsBaseUrl = serverAddres
          .replaceAll('http://', 'ws://')
          .replaceAll('https://', 'wss://');
      final url = Uri.parse('$wsBaseUrl/ws/rooms/$roomId?userId=$userId');

      _channel = WebSocketChannel.connect(url);
      isLoading = false;
      notifyListeners();

      _channel!.stream.listen(
        (data) => _handleSignal(data),
        onError: (error) {
          errorMessage = "Erro na conexão.";
          disconnectFromRoom();
        },
        onDone: () {
          disconnectFromRoom();
        },
      );
    } catch (e) {
      isLoading = false;
      errorMessage = "Falha ao conectar: $e";
      _channel = null;
      notifyListeners();
    }
  }

  Future<void> _initLocalMedia() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
    });
    localStream = stream;
  }

  void _handleSignal(dynamic data) async {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      final payload = msg['payload']; 

      switch (type) {
        case 'existing-users':
          final List<dynamic> ids = payload as List<dynamic>;
          for (final peerId in ids) {
            await _createPeerConnection(peerId as String, isOfferer: true);
          }
          break;

        case 'user-joined':
          final peerId = msg['from'] as String;
          mensagens.add(ChatMessage(from: "system", text: "$peerId joined in room"));
          notifyListeners();
          break;

        case 'user-left':
          final peerId = msg['from'] as String;
          mensagens.add(ChatMessage(from: "system", text: "$peerId left the room"));
          await _removePeer(peerId);
          break;

        case 'chat':
          final from = msg['from'] as String;
          final chatPayload = payload as Map<String, dynamic>;
          mensagens.add(ChatMessage(from: from, text: chatPayload['text'] as String));
          notifyListeners();
          break;

        case 'offer':
          await _handleOffer(msg['from'] as String, payload as Map<String, dynamic>);
          break;

        case 'answer':
          await _handleAnswer(msg['from'] as String, payload as Map<String, dynamic>);
          break;

        case 'ice-candidate':
          await _handleRemoteIceCandidate(msg['from'] as String, payload as Map<String, dynamic>);
          break;
      }
    } catch (e) {
      debugPrint("Erro ao processar mensagem: $e");
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId, {required bool isOfferer}) async {
    final pc = await createPeerConnection(_iceServers);
    _peerConnections[peerId] = pc;

    localStream?.getTracks().forEach((track) {
      pc.addTrack(track, localStream!);
    });

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStreams[peerId] = event.streams[0];
        notifyListeners();
      }
    };

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      _sendSignal('ice-candidate', peerId, {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _removePeer(peerId);
      }
    };

    if (isOfferer) {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _sendSignal('offer', peerId, {
        'sdp': offer.sdp,
        'type': offer.type,
      });
    }

    return pc;
  }

  Future<void> _handleOffer(String peerId, Map<String, dynamic> payload) async {
    final pc = await _createPeerConnection(peerId, isOfferer: false);

    await pc.setRemoteDescription(
      RTCSessionDescription(payload['sdp'] as String, payload['type'] as String),
    );

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _sendSignal('answer', peerId, {
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  Future<void> _handleAnswer(String peerId, Map<String, dynamic> payload) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    await pc.setRemoteDescription(
      RTCSessionDescription(payload['sdp'] as String, payload['type'] as String),
    );
  }

  Future<void> _handleRemoteIceCandidate(String peerId, Map<String, dynamic> payload) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;

    await pc.addCandidate(RTCIceCandidate(
      payload['candidate'] as String?,
      payload['sdpMid'] as String?,
      payload['sdpMLineIndex'] as int?,
    ));
  }

  Future<void> _removePeer(String peerId) async {
    final pc = _peerConnections.remove(peerId);
    await pc?.close();
    remoteStreams.remove(peerId);
    notifyListeners();
  }

  void _sendSignal(String type, String to, Map<String, dynamic> payload) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': type,
      'to': to,
      'payload': payload, 
    }));
  }

  void enviarMensagem(String texto) {
    if (_channel == null || texto.trim().isEmpty) return;

    _channel!.sink.add(jsonEncode({
      'type': 'chat',
      'payload': {'text': texto}, 
    }));
  }

  Future<void> toggleAudio() async {
    if (localStream == null) return;
    isAudioEnabled = !isAudioEnabled;
    for (final track in localStream!.getAudioTracks()) {
      track.enabled = isAudioEnabled;
    }
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    if (localStream == null) return;
    isVideoEnabled = !isVideoEnabled;
    for (final track in localStream!.getVideoTracks()) {
      track.enabled = isVideoEnabled;
    }
    notifyListeners();
  }

  Future<void> disconnectFromRoom() async {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    remoteStreams.clear();

    await localStream?.dispose();
    localStream = null;

    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnectFromRoom();
    super.dispose();
  }
}