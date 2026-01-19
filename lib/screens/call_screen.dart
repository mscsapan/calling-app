import 'package:calling_app/config/agora_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/call_provider.dart';


class CallScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final bool isVideoCall;
  final String? profileImageUrl;

  const CallScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.isVideoCall,
    this.profileImageUrl,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  // ==================== AGORA CONFIGURATION ====================
  static const String appId = AgoraConfig.appId;
  static const String token =''; // AgoraConfig.token
  static const String channelName = AgoraConfig.channelName;

  // ==================== AGORA ENGINE ====================
  RtcEngine? _engine;
  bool _isEngineInitialized = false;
  bool _isJoined = false;

  // ==================== DRAGGABLE VIDEO PREVIEW ====================
  Offset _localVideoPosition = const Offset(0, 0);
  bool _isDragging = false;

  // Animation controller for smooth preview entry
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAgora();
    _setInitialVideoPosition();
  }

  // ==================== ANIMATIONS ====================
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  void _setInitialVideoPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _localVideoPosition = Offset(size.width - 140, 100);
      });
    });
  }

  // ==================== AGORA INITIALIZATION ====================
  Future<void> _initializeAgora() async {
    try {
      await _requestPermissions();

      _engine = createAgoraRtcEngine();

      await _engine?.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Local user joined: ${connection.channelId}');
            setState(() => _isJoined = true);
            context.read<CallProvider>().startTimer();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('✅ Remote user joined: $remoteUid');
            context.read<CallProvider>().onRemoteUserJoined(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('❌ Remote user left: $remoteUid');
            context.read<CallProvider>().onRemoteUserLeft();
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora Error: $err - $msg');
          },
        ),
      );

      await _engine?.enableAudio();

      if (widget.isVideoCall) {
        await _engine?.enableVideo();
        await _engine?.startPreview();
      } else {
        await _engine?.setDefaultAudioRouteToSpeakerphone(true);
      }

      await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      setState(() => _isEngineInitialized = true);

      await _joinChannel();

    } catch (e) {
      debugPrint('❌ Agora init error: $e');
      _showErrorDialog('Failed to initialize: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (widget.isVideoCall) {
      await [Permission.microphone, Permission.camera].request();
    } else {
      await [Permission.microphone].request();
    }
  }

  Future<void> _joinChannel() async {
    if (_engine == null) return;

    try {
      await _engine?.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
        ),
      );

      debugPrint('📞 Joining channel: $channelName');
    } catch (e) {
      debugPrint('❌ Join error: $e');
    }
  }

  // ==================== CALL CONTROLS ====================
  Future<void> _toggleMute() async {
    final provider = context.read<CallProvider>();
    await _engine?.muteLocalAudioStream(!provider.isMuted);
    provider.toggleMute();
  }

  Future<void> _toggleVideo() async {
    final provider = context.read<CallProvider>();
    await _engine?.muteLocalVideoStream(!provider.isVideoEnabled);
    provider.toggleVideo();
  }

  Future<void> _toggleSpeaker() async {
    final provider = context.read<CallProvider>();
    await _engine?.setEnableSpeakerphone(!provider.isSpeakerEnabled);
    provider.toggleSpeaker();
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
    context.read<CallProvider>().toggleCamera();
  }

  Future<void> _endCall() async {
    await _leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _leaveChannel() async {
    if (_engine == null) return;

    try {
      context.read<CallProvider>().stopTimer();
      await _engine!.leaveChannel();
      if (widget.isVideoCall) await _engine!.stopPreview();
      debugPrint('📴 Left channel');
    } catch (e) {
      debugPrint('❌ Leave error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _disposeAgora();
    super.dispose();
  }

  Future<void> _disposeAgora() async {
    try {
      await _engine?.release();
      _engine = null;
      debugPrint('🗑️ Agora disposed');
    } catch (e) {
      debugPrint('❌ Dispose error: $e');
    }
  }

  // ==================== DRAGGABLE LOGIC ====================
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _localVideoPosition += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _snapToNearestCorner();
    });
  }

  void _snapToNearestCorner() {
    final size = MediaQuery.of(context).size;
    final previewWidth = 120.0;
    final previewHeight = 160.0;
    final padding = 16.0;

    // Calculate distances to each corner
    final topLeft = Offset(padding, 100.0);
    final topRight = Offset(size.width - previewWidth - padding, 100.0);
    final bottomLeft = Offset(padding, size.height - previewHeight - 150.0);
    final bottomRight = Offset(size.width - previewWidth - padding, size.height - previewHeight - 150.0);

    final corners = [topLeft, topRight, bottomLeft, bottomRight];

    // Find nearest corner
    Offset nearest = corners[0];
    double minDistance = (_localVideoPosition - corners[0]).distance;

    for (var corner in corners) {
      double distance = (_localVideoPosition - corner).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearest = corner;
      }
    }

    setState(() {
      _localVideoPosition = nearest;
    });
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: _isEngineInitialized
            ? _buildCallUI()
            : _buildLoadingUI(),
      ),
    );
  }

  Widget _buildLoadingUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Connecting...', style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildCallUI() {
    return Consumer<CallProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () => provider.toggleUIVisibility(),
          child: Stack(
            children: [
              // Background: Local video (before remote joins) or Remote video (after remote joins)
              widget.isVideoCall
                  ? (provider.isRemoteUserJoined
                  ? _buildRemoteVideoFullScreen()
                  : _buildLocalVideoFullScreen())
                  : _buildAudioCallBackground(),

              // Draggable local video preview (only when remote user joined and video enabled)
              if (widget.isVideoCall &&
                  provider.isRemoteUserJoined &&
                  provider.isVideoEnabled)
                _buildDraggableLocalPreview(),

              // Top bar (animated)
              _buildAnimatedTopBar(provider),

              // Bottom controls (animated)
              _buildAnimatedBottomControls(provider),
            ],
          ),
        );
      },
    );
  }

  // Full screen local video (before remote joins)
  Widget _buildLocalVideoFullScreen() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox.expand(
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Full screen remote video
  Widget _buildRemoteVideoFullScreen() {
    final remoteUid = context.read<CallProvider>().remoteUid;

    return SizedBox.expand(
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: remoteUid),
          connection: const RtcConnection(channelId: channelName),
        ),
      ),
    );
  }

  // Draggable local video preview (PiP style)
  Widget _buildDraggableLocalPreview() {
    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: _localVideoPosition.dx,
      top: _localVideoPosition.dy,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Audio call background
  Widget _buildAudioCallBackground() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[800],
            backgroundImage: widget.profileImageUrl != null
                ? NetworkImage(widget.profileImageUrl!)
                : null,
            child: widget.profileImageUrl == null
                ? Text(
              widget.userName[0].toUpperCase(),
              style: const TextStyle(fontSize: 48, color: Colors.white),
            )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.userName,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userRole,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Animated top bar
  Widget _buildAnimatedTopBar(CallProvider provider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: provider.isUIVisible ? 0 : -100,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[700],
              backgroundImage: widget.profileImageUrl != null
                  ? NetworkImage(widget.profileImageUrl!)
                  : null,
              child: widget.profileImageUrl == null
                  ? Text(widget.userName[0].toUpperCase(), style: const TextStyle(fontSize: 18))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    provider.isRemoteUserJoined ? provider.callDuration : 'Calling...',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Animated bottom controls
  Widget _buildAnimatedBottomControls(CallProvider provider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: provider.isUIVisible ? 0 : -200,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: widget.isVideoCall
            ? _buildVideoCallControls(provider)
            : _buildAudioCallControls(provider),
      ),
    );
  }

  Widget _buildVideoCallControls(CallProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: provider.isMuted ? Icons.mic_off : Icons.mic,
          onPressed: _toggleMute,
          isActive: !provider.isMuted,
        ),
        _buildControlButton(
          icon: provider.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
          onPressed: _toggleVideo,
          isActive: provider.isVideoEnabled,
        ),
        _buildControlButton(
          icon: Icons.cameraswitch,
          onPressed: _switchCamera,
          isActive: true,
        ),
        _buildControlButton(
          icon: Icons.call_end,
          onPressed: _endCall,
          backgroundColor: Colors.red,
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildAudioCallControls(CallProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: provider.isMuted ? Icons.mic_off : Icons.mic,
          onPressed: _toggleMute,
          isActive: !provider.isMuted,
        ),
        _buildControlButton(
          icon: provider.isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
          onPressed: _toggleSpeaker,
          isActive: provider.isSpeakerEnabled,
        ),
        _buildControlButton(
          icon: Icons.call_end,
          onPressed: _endCall,
          backgroundColor: Colors.red,
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    required bool isActive,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ??
          (isActive ? Colors.white.withOpacity(0.3) : Colors.grey[800]),
      elevation: 0,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}