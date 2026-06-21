import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:mesh/pages/room/room_page_viewmodel.dart';
import 'package:mesh/pages/room/room_page_arguments.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  bool _initialized = false;
  bool _chatOpen = false;

  final TextEditingController _chatController = TextEditingController();

 @override
void didChangeDependencies() {
  super.didChangeDependencies();

  if (!_initialized) {
    _initialized = true;

    final args =
        ModalRoute.of(context)!.settings.arguments as RoomPageArguments;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<RoomPageViewmodel>().connectRoom(
        args.serverAddress,
        args.roomId,
        args.userId,
      );
    });
  }
}

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as RoomPageArguments;
    final viewmodel = context.watch<RoomPageViewmodel>();

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
  debugPrint(
    'REMOTE STREAMS UI => ${viewmodel.remoteStreams.length}',
  );
    final tiles = <Widget>[];

    // Local Video
    if (viewmodel.localStream != null) {
      tiles.add(StreamVideoTile(
        key: const ValueKey('local'),
        stream: viewmodel.localStream!,
        label: "You",
        isMuted: !viewmodel.isAudioEnabled,
        showPlaceholder: !viewmodel.isVideoEnabled,
        mirror: true,
      ));
    }

    // Remote Videos
    for (final entry in viewmodel.remoteStreams.entries) {
      debugPrint("CRIANDO TILE REMOTO => ${entry.key}");

      tiles.add(StreamVideoTile(
        key: ValueKey(entry.key),
        stream: entry.value,
        label: entry.key,
        isMuted: false,
        showPlaceholder: false,
        mirror: false,
      ));
    }

    final count = tiles.length;
    int crossAxisCount = 1;
    if (count > 1 && count <= 4) {
      crossAxisCount = 2;
    } else if (count > 4) {
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
    return SafeArea(child: Container(
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
    ));
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

class StreamVideoTile extends StatefulWidget {
  final MediaStream stream;
  final String label;
  final bool isMuted;
  final bool showPlaceholder;
  final bool mirror;

  const StreamVideoTile({
    super.key,
    required this.stream,
    required this.label,
    required this.isMuted,
    required this.showPlaceholder,
    required this.mirror,
  });

  @override
  State<StreamVideoTile> createState() => _StreamVideoTileState();
}

class _StreamVideoTileState extends State<StreamVideoTile> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _renderer.initialize();

    _renderer.onFirstFrameRendered = () {
      debugPrint("FIRST FRAME => ${widget.label}");
    };

    _renderer.onResize = () {
      debugPrint(
        "RESIZE => ${widget.label} "
        "${_renderer.videoWidth}x${_renderer.videoHeight}",
      );
    };

    _renderer.srcObject = widget.stream;

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void didUpdateWidget(covariant StreamVideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _renderer.srcObject = widget.stream;
    }
  }

  @override
  void dispose() {
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: const Color(0xFF1F1F1F),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: const Color(0xFF1F1F1F),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!widget.showPlaceholder)
              RTCVideoView(
                _renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: widget.mirror,
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
                  if (widget.isMuted)
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
                      widget.label,
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
}