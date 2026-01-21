import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/agora_config.dart';
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
  RtcEngine? _engine;
  bool _isEngineInitialized = false;
  bool _isJoined = false;
  int _localUid = 0;

  Offset _localVideoPosition = const Offset(0, 0);
  bool _isDragging = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCallProvider();
    _initializeAgora();
    _setInitialVideoPosition();
  }

  void _initializeCallProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallProvider>().initializeCallType(widget.isVideoCall);
      context.read<CallProvider>().setCallStatus(CallStatus.connecting);
    });
  }

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
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      setState(() {
        _localVideoPosition = Offset(size.width - 140, 100);
      });
    });
  }

  Future<void> _initializeAgora() async {
    try {
      debugPrint('🔵 Starting Agora initialization...');

      await _requestPermissions();

      _engine = createAgoraRtcEngine();
      debugPrint('✅ Agora engine created');

      await _engine?.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      debugPrint('✅ Agora engine initialized');

      _engine?.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Local user joined: UID=${connection.localUid}');
            if (mounted) {
              setState(() {
                _isJoined = true;
                _localUid = connection.localUid ?? 0;
              });
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('✅ Remote user joined: $remoteUid');
            if (mounted) {
              context.read<CallProvider>().onRemoteUserJoined(remoteUid);
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('❌ Remote user left: $remoteUid');
            if (mounted) {
              context.read<CallProvider>().onRemoteUserLeft();
              _endCall(); // Auto-end call when remote user leaves
            }
          },
          onRemoteVideoStateChanged: (
              RtcConnection connection,
              int remoteUid,
              RemoteVideoState state,
              RemoteVideoStateReason reason,
              int elapsed,
              ) {
            debugPrint('📹 Remote video state changed: state=$state, reason=$reason');

            if (mounted) {
              // Update remote video state
              bool isEnabled = false;

              switch (state) {
                case RemoteVideoState.remoteVideoStateStarting:
                case RemoteVideoState.remoteVideoStateDecoding:
                  isEnabled = true;
                  debugPrint('✅ Remote video is ON');
                  break;
                case RemoteVideoState.remoteVideoStateStopped:
                case RemoteVideoState.remoteVideoStateFrozen:
                  isEnabled = false;
                  debugPrint('❌ Remote video is OFF');
                  break;
                default:
                  break;
              }

              context.read<CallProvider>().setRemoteVideoEnabled(isEnabled);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora Error: $err - $msg');
          },
        ),
      );

      await _engine?.enableAudio();
      debugPrint('✅ Audio enabled');

      if (widget.isVideoCall) {
        await _engine?.enableVideo();
        await _engine?.startPreview();
        debugPrint('✅ Video enabled');
      } else {
        await _engine?.setDefaultAudioRouteToSpeakerphone(true);
        debugPrint('✅ Speaker enabled');
      }

      await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      debugPrint('✅ Client role set');

      if (mounted) {
        setState(() => _isEngineInitialized = true);
      }

      await _joinChannel();

    } catch (e) {
      debugPrint('❌ Agora init error: $e');
      if (mounted) {
        _showErrorDialog('Failed to initialize: $e');
      }
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
      debugPrint('📞 Joining channel: ${AgoraConfig.channelName}');

      await _engine?.joinChannel(
        token: AgoraConfig.token,
        channelId: AgoraConfig.channelName,
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

      debugPrint('📞 Join request sent');
    } catch (e) {
      debugPrint('❌ Join error: $e');
    }
  }

  Future<void> _toggleMute() async {
    final provider = context.read<CallProvider>();
    await _engine?.muteLocalAudioStream(!provider.isMuted);
    provider.toggleMute();
  }

  Future<void> _toggleVideo() async {
    final provider = context.read<CallProvider>();

    if (!provider.isVideoCall && !provider.isVideoEnabled) {
      await _enableVideoInAudioCall();
      return;
    }

    if (provider.isVideoEnabled) {
      // Turning OFF video
      await _engine?.muteLocalVideoStream(true);
      await _engine?.enableLocalVideo(false);

      // Stop publishing video track
      await _engine?.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: false,
        ),
      );

      debugPrint('📹 Video OFF - stopped publishing');
    } else {
      // Turning ON video
      await _engine?.enableLocalVideo(true);
      await _engine?.muteLocalVideoStream(false);

      // Start publishing video track
      await _engine?.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: true,
        ),
      );

      debugPrint('📹 Video ON - started publishing');
    }

    provider.toggleVideo();
  }

  Future<void> _enableVideoInAudioCall() async {
    try {
      await Permission.camera.request();
      await _engine?.enableVideo();
      await _engine?.startPreview();

      context.read<CallProvider>().switchToVideoCall();

      await _engine?.updateChannelMediaOptions(
        const ChannelMediaOptions(publishCameraTrack: true),
      );

      debugPrint('✅ Video enabled in audio call');
    } catch (e) {
      debugPrint('❌ Error enabling video: $e');
    }
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
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _leaveChannel() async {
    if (_engine == null) return;

    try {
      context.read<CallProvider>().stopTimer();
      context.read<CallProvider>().setCallStatus(CallStatus.ended);

      await _engine?.leaveChannel();

      final provider = context.read<CallProvider>();
      if (provider.isVideoCall) {
        await _engine?.stopPreview();
      }

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
    const previewWidth = 120.0;
    const previewHeight = 160.0;
    const padding = 16.0;

    final topLeft = const Offset(padding, 100.0);
    final topRight = Offset(size.width - previewWidth - padding, 100.0);
    final bottomLeft = Offset(padding, size.height - previewHeight - 150.0);
    final bottomRight = Offset(size.width - previewWidth - padding, size.height - previewHeight - 150.0);

    final corners = [topLeft, topRight, bottomLeft, bottomRight];

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          child: _isEngineInitialized
              ? _buildCallUI()
              : _buildLoadingUI(),
        ),
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
          onTap: () {
            debugPrint('called ${provider.isUIVisible}');
            if (provider.isUIVisible) {
              provider.hideUI();
            } else {
              provider.showUI();
            }
          },
          child: Stack(
            children: [
              provider.isVideoCall
                  ? _buildVideoBackground(provider)
                  : _buildAudioCallBackground(),

              if (provider.isVideoCall &&
                  provider.isRemoteUserJoined &&
                  provider.isVideoEnabled)
                _buildDraggableLocalPreview(),

              _buildAnimatedTopBar(provider),
              _buildAnimatedBottomControls(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoBackground(CallProvider provider) {
    if (provider.isVideoEnabled) {
      if (provider.isRemoteUserJoined) {
        // Show remote video if enabled, else show avatar
        return provider.isRemoteVideoEnabled
            ? _buildRemoteVideoFullScreen()
            : _buildAudioCallBackground();
      } else {
        return _buildLocalVideoFullScreen();
      }
    } else {
      return _buildAudioCallBackground();
    }
  }

  Widget _buildLocalVideoFullScreen() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox.expand(
              child: _engine != null
                  ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemoteVideoFullScreen() {
    final remoteUid = context.read<CallProvider>().remoteUid;

    return SizedBox.expand(
      child: _engine != null
          ? AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: remoteUid),
          connection: RtcConnection(channelId: AgoraConfig.channelName),
        ),
      )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

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
            child: _engine != null
                ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioCallBackground() {
    debugPrint('called _buildAudioCallBackground');
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
        child: provider.isVideoCall
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
          key: const ValueKey('mute-button'),
          icon: provider.isMuted ? Icons.mic_off : Icons.mic,
          onPressed: _toggleMute,
          isActive: !provider.isMuted,
        ),
        _buildControlButton(
          key: const ValueKey('video-button'),
          icon: provider.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
          onPressed: _toggleVideo,
          isActive: provider.isVideoEnabled,
        ),
        _buildControlButton(
          key: const ValueKey('camera-button'),
          icon: Icons.cameraswitch,
          onPressed: _switchCamera,
          isActive: true,
        ),
        _buildControlButton(
          key: const ValueKey('speaker-button'),
          icon: provider.isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
          onPressed: _toggleSpeaker,
          isActive: provider.isSpeakerEnabled,
        ),
        _buildControlButton(
          key: const ValueKey('end-call-button'),
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
          key: const ValueKey('mute-button-audio'),
          icon: provider.isMuted ? Icons.mic_off : Icons.mic,
          onPressed: _toggleMute,
          isActive: !provider.isMuted,
        ),
        _buildControlButton(
          key: const ValueKey('video-button-audio'),
          icon: Icons.videocam,
          onPressed: _toggleVideo,
          isActive: false,
        ),
        _buildControlButton(
          key: const ValueKey('speaker-button-audio'),
          icon: provider.isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
          onPressed: _toggleSpeaker,
          isActive: provider.isSpeakerEnabled,
        ),
        _buildControlButton(
          key: const ValueKey('end-call-button-audio'),
          icon: Icons.call_end,
          onPressed: _endCall,
          backgroundColor: Colors.red,
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    required bool isActive,
  }) {
    return FloatingActionButton(
      key: key,
      heroTag: key,
      onPressed: onPressed,
      backgroundColor: backgroundColor ??
          (isActive ? Colors.white.withOpacity(0.3) : Colors.grey[800]),
      elevation: 0,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

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