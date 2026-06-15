import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:mesh/pages/meeting/room_page_viewmodel.dart';
import 'package:mesh/pages/meeting/room_page_arguments.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  bool _initialized = false;
  bool _chatOpen = false;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as RoomPageArguments;
      context.read<RoomPageViewmodel>().connectRoom(args.roomId, args.userId);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    for (final r in _remoteRenderers.values) {
      r.dispose();
    }
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _syncRenderers(RoomPageViewmodel viewmodel) async {
    if (_localRenderer.srcObject != viewmodel.localStream) {
      _localRenderer.srcObject = viewmodel.localStream;
    }

    for (final entry in viewmodel.remoteStreams.entries) {
      if (!_remoteRenderers.containsKey(entry.key)) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = entry.value;
        _remoteRenderers[entry.key] = renderer;
      } else if (_remoteRenderers[entry.key]!.srcObject != entry.value) {
        _remoteRenderers[entry.key]!.srcObject = entry.value;
      }
    }

    final toRemove = _remoteRenderers.keys
        .where((id) => !viewmodel.remoteStreams.containsKey(id))
        .toList();
    for (final id in toRemove) {
      await _remoteRenderers[id]?.dispose();
      _remoteRenderers.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as RoomPageArguments;
    final viewmodel = context.watch<RoomPageViewmodel>();

    _syncRenderers(viewmodel);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Room: ${args.roomId}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            viewmodel.disconnectFromRoom();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_chatOpen ? Icons.chat_bubble : Icons.chat_bubble_outline),
            onPressed: () => setState(() => _chatOpen = !_chatOpen),
          ),
        ],
      ),
      body: viewmodel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      _buildVideoGrid(viewmodel),
                      if (viewmodel.errorMessage.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 8,
                          child: Material(
                            color: Colors.red.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                viewmodel.errorMessage,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_chatOpen)
                  SizedBox(
                    width: 300,
                    child: _buildChatPanel(viewmodel),
                  ),
              ],
            ),
      bottomNavigationBar: viewmodel.isLoading
          ? null
          : _buildControlBar(viewmodel),
    );
  }

  Widget _buildVideoGrid(RoomPageViewmodel viewmodel) {
    final tiles = <Widget>[
      _videoTile(
        renderer: _localRenderer,
        label: "You",
        isMuted: !viewmodel.isAudioEnabled,
        showPlaceholder: !viewmodel.isVideoEnabled,
        mirror: true,
      ),
    ];

    for (final entry in viewmodel.remoteStreams.entries) {
      final renderer = _remoteRenderers[entry.key];
      if (renderer == null) continue;
      tiles.add(
        _videoTile(
          renderer: renderer,
          label: entry.key,
          isMuted: false,
          showPlaceholder: false,
          mirror: false,
        ),
      );
    }

    final count = tiles.length;
    int crossAxisCount;
    if (count <= 1) {
      crossAxisCount = 1;
    } else if (count <= 4) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 4 / 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: count,
        itemBuilder: (context, index) => tiles[index],
      ),
    );
  }

  Widget _videoTile({
    required RTCVideoRenderer renderer,
    required String label,
    required bool isMuted,
    required bool showPlaceholder,
    required bool mirror,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: const Color(0xFF1F1F1F),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!showPlaceholder)
              RTCVideoView(
                renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: mirror,
              )
            else
              const Center(
                child: Icon(Icons.person, size: 64, color: Colors.white54),
              ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Row(
                children: [
                  if (isMuted)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.mic_off, size: 16, color: Colors.white),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel(RoomPageViewmodel viewmodel) {
    return Container(
      color: const Color(0xFF202124),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: const Text(
              "Chat",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: viewmodel.mensagens.isEmpty
                ? const Center(
                    child: Text(
                      "Not message yet",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: viewmodel.mensagens.length,
                    itemBuilder: (context, index) {
                      final msg = viewmodel.mensagens[index];
                      final isSystem = msg.from == "system";
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: isSystem
                            ? Text(
                                msg.text,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.from,
                                    style: const TextStyle(
                                      color: Colors.lightBlueAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    msg.text,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write a message",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendChat(viewmodel),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendChat(viewmodel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendChat(RoomPageViewmodel viewmodel) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    viewmodel.enviarMensagem(text);
    _chatController.clear();
  }

  Widget _buildControlBar(RoomPageViewmodel viewmodel) {
    return Container(
      color: const Color(0xFF202124),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            icon: viewmodel.isAudioEnabled ? Icons.mic : Icons.mic_off,
            active: viewmodel.isAudioEnabled,
            onPressed: () => viewmodel.toggleAudio(),
          ),
          const SizedBox(width: 16),
          _controlButton(
            icon: viewmodel.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            active: viewmodel.isVideoEnabled,
            onPressed: () => viewmodel.toggleVideo(),
          ),
          const SizedBox(width: 16),
          _controlButton(
            icon: Icons.call_end,
            active: false,
            color: Colors.red,
            onPressed: () {
              viewmodel.disconnectFromRoom();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required bool active,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: color ?? (active ? Colors.white24 : Colors.white10),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}