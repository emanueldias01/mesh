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

class _TileConfig {
  final String id;
  final MediaStream stream;
  final String label;
  final bool isMuted;
  final bool showPlaceholder;
  final bool mirror;

  _TileConfig({
    required this.id,
    required this.stream,
    required this.label,
    required this.isMuted,
    required this.showPlaceholder,
    required this.mirror,
  });
}

class _RoomPageState extends State<RoomPage> {
  bool _initialized = false;
  bool _chatOpen = false;
  String? _expandedTileId;

  final TextEditingController _chatController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;

      final args = ModalRoute.of(context)!.settings.arguments as RoomPageArguments;

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
                      _buildVideoArea(viewmodel),
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
      bottomNavigationBar: viewmodel.isLoading ? null : _buildControlBar(viewmodel),
    );
  }

  List<_TileConfig> _buildTileConfigs(RoomPageViewmodel viewmodel) {
    final tiles = <_TileConfig>[];

    if (viewmodel.localStream != null) {
      tiles.add(_TileConfig(
        id: 'local_camera',
        stream: viewmodel.localStream!,
        label: "You",
        isMuted: !viewmodel.isAudioEnabled,
        showPlaceholder: !viewmodel.isVideoEnabled,
        mirror: true,
      ));
    }

    if (viewmodel.screenStream != null) {
      tiles.add(_TileConfig(
        id: 'local_screen',
        stream: viewmodel.screenStream!,
        label: "You (Screen)",
        isMuted: true,
        showPlaceholder: false,
        mirror: false,
      ));
    }

    for (final entry in viewmodel.remoteStreams.entries) {
      final peerId = entry.key.split('_').first;
      tiles.add(_TileConfig(
        id: entry.key,
        stream: entry.value,
        label: peerId,
        isMuted: false,
        showPlaceholder: false,
        mirror: false,
      ));
    }

    return tiles;
  }

  Widget _buildVideoArea(RoomPageViewmodel viewmodel) {
    final tiles = _buildTileConfigs(viewmodel);

    if (tiles.isEmpty) return const SizedBox.shrink();

    final expandedId = tiles.any((t) => t.id == _expandedTileId) ? _expandedTileId : null;

    if (expandedId != null) {
      final tile = tiles.firstWhere((t) => t.id == expandedId);
      return ExpandedVideoView(
        key: ValueKey('expanded_${tile.id}'),
        stream: tile.stream,
        label: tile.label,
        showPlaceholder: tile.showPlaceholder,
        mirror: tile.mirror,
        onClose: () => setState(() => _expandedTileId = null),
      );
    }

    return _buildGrid(tiles);
  }

  Widget _buildGrid(List<_TileConfig> tiles) {
    final count = tiles.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isPortrait = constraints.maxHeight > constraints.maxWidth;
        int columns = 1;

        if (count == 1) {
          columns = 1;
        } else if (count == 2) {
          columns = isPortrait ? 1 : 2;
        } else if (count <= 4) {
          columns = 2;
        } else if (count <= 6) {
          columns = isPortrait ? 2 : 3;
        } else if (count <= 9) {
          columns = isPortrait ? 2 : 3;
        } else {
          columns = isPortrait ? 3 : 4;
        }

        int rows = (count / columns).ceil();

        const double padding = 8.0;
        const double spacing = 4.0;

        double availableWidth = constraints.maxWidth - padding - (spacing * (columns - 1));
        double availableHeight = constraints.maxHeight - padding - (spacing * (rows - 1));

        double itemWidth = availableWidth / columns;
        double itemHeight = availableHeight / rows;
        double childAspectRatio = itemWidth / itemHeight;

        return Padding(
          padding: const EdgeInsets.all(padding / 2),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: childAspectRatio.isFinite && childAspectRatio > 0 ? childAspectRatio : 1.0,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: count,
            itemBuilder: (context, index) {
              final tile = tiles[index];
              return GestureDetector(
                onTap: () => setState(() => _expandedTileId = tile.id),
                child: StreamVideoTile(
                  key: ValueKey(tile.id),
                  stream: tile.stream,
                  label: tile.label,
                  isMuted: tile.isMuted,
                  showPlaceholder: tile.showPlaceholder,
                  mirror: tile.mirror,
                ),
              );
            },
          ),
        );
      },
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
    return SafeArea(
      child: Container(
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
              icon: viewmodel.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              active: viewmodel.isScreenSharing,
              color: viewmodel.isScreenSharing ? Colors.blueAccent : null,
              onPressed: () => viewmodel.toggleScreenShare(),
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
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.fullscreen, size: 16, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandedVideoView extends StatefulWidget {
  final MediaStream stream;
  final String label;
  final bool showPlaceholder;
  final bool mirror;
  final VoidCallback onClose;

  const ExpandedVideoView({
    super.key,
    required this.stream,
    required this.label,
    required this.showPlaceholder,
    required this.mirror,
    required this.onClose,
  });

  @override
  State<ExpandedVideoView> createState() => _ExpandedVideoViewState();
}

class _ExpandedVideoViewState extends State<ExpandedVideoView> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final TransformationController _transformationController = TransformationController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _renderer.initialize();
    _renderer.srcObject = widget.stream;
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ExpandedVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _renderer.srcObject = widget.stream;
    }
  }

  @override
  void dispose() {
    _renderer.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_initialized)
            const Center(child: CircularProgressIndicator())
          else
            GestureDetector(
              onDoubleTap: _resetZoom,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 5.0,
                child: widget.showPlaceholder
                    ? const Center(
                        child: Icon(Icons.person, size: 120, color: Colors.white54),
                      )
                    : RTCVideoView(
                        _renderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                        mirror: widget.mirror,
                      ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}