import 'package:calling_app/config/agora_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/call_provider.dart';


class CallScreen extends StatefulWidget {
  final String userName;
  final String userRole; // "Doctor" or "Patient"
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

class _CallScreenState extends State<CallScreen> {
  // ==================== AGORA CONFIGURATION ====================
  // IMPORTANT: Replace with your actual Agora credentials
  // static const String appId = "YOUR_AGORA_APP_ID";
  // static const String token = "YOUR_TEMPORARY_TOKEN"; // Can be null for testing
  // static const String channelName = "test_channel_001";

  // ==================== AGORA ENGINE ====================
  RtcEngine? _engine;
  bool _isEngineInitialized = false;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  // ==================== AGORA INITIALIZATION ====================
  // CRITICAL: This runs ONCE in initState, NOT in build()
  Future<void> _initializeAgora() async {
    try {
      // Step 1: Request permissions
      await _requestPermissions();

      // Step 2: Create Agora engine (ONCE!)
      _engine = createAgoraRtcEngine();

      // Step 3: Initialize with AppID
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Step 4: Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Local user joined channel: ${connection.channelId}');
            setState(() {
              _isJoined = true;
            });
            // Start call timer when successfully joined
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

      // Step 5: Enable audio
      await _engine!.enableAudio();

      // Step 6: Enable video if video call
      if (widget.isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        // For audio calls, enable speaker by default
        await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      }

      // Step 7: Set client role as BROADCASTER (both users can send/receive)
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      setState(() {
        _isEngineInitialized = true;
      });

      // Step 8: Join channel
      await _joinChannel();

    } catch (e) {
      debugPrint('❌ Agora initialization error: $e');
      _showErrorDialog('Failed to initialize call: $e');
    }
  }

  // ==================== PERMISSIONS ====================
  Future<void> _requestPermissions() async {
    if (widget.isVideoCall) {
      await [Permission.microphone, Permission.camera].request();
    } else {
      await [Permission.microphone].request();
    }
  }

  // ==================== JOIN CHANNEL ====================
  Future<void> _joinChannel() async {
    if (_engine == null) return;

    try {
      // Join with UID 0 (Agora will auto-assign)
      await _engine!.joinChannel(
        // token: token.isEmpty ? null : token,
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

      debugPrint('📞 Joining channel: ${AgoraConfig.channelName}');
    } catch (e) {
      debugPrint('❌ Join channel error: $e');
    }
  }

  // ==================== LEAVE CHANNEL & CLEANUP ====================
  Future<void> _leaveChannel() async {
    if (_engine == null) return;

    try {
      // Stop timer
      context.read<CallProvider>().stopTimer();

      // Leave channel
      await _engine!.leaveChannel();

      // Stop preview if video call
      if (widget.isVideoCall) {
        await _engine!.stopPreview();
      }

      debugPrint('📴 Left channel');
    } catch (e) {
      debugPrint('❌ Leave channel error: $e');
    }
  }

  // ==================== DISPOSE ====================
  @override
  void dispose() {
    _disposeAgora();
    super.dispose();
  }

  Future<void> _disposeAgora() async {
    try {
      // Release engine (ONLY on dispose)
      await _engine?.release();
      _engine = null;
      debugPrint('🗑️ Agora engine disposed');
    } catch (e) {
      debugPrint('❌ Dispose error: $e');
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

  Future<void> _endCall() async {
    await _leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
          Text(
            'Connecting...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCallUI() {
    return Consumer<CallProvider>(
      builder: (context, callProvider, child) {
        return Stack(
          children: [
            // Remote video (full screen) or avatar
            if (widget.isVideoCall && callProvider.isRemoteUserJoined)
              _buildRemoteVideo()
            else
              _buildUserAvatar(),

            // Local video preview (PiP)
            if (widget.isVideoCall && callProvider.isVideoEnabled)
              _buildLocalVideoPreview(),

            // Top bar (name, duration)
            _buildTopBar(callProvider),

            // Bottom controls
            _buildBottomControls(callProvider),
          ],
        );
      },
    );
  }

  // Remote video view
  Widget _buildRemoteVideo() {
    final remoteUid = context.read<CallProvider>().remoteUid;

    return SizedBox.expand(
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: remoteUid),
          connection: const RtcConnection(channelId: AgoraConfig.channelName),
        ),
      ),
    );
  }

  // Local video preview (small floating window)
  Widget _buildLocalVideoPreview() {
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
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
    );
  }

  // User avatar (when no video)
  Widget _buildUserAvatar() {
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userRole,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Top bar
  Widget _buildTopBar(CallProvider provider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              provider.isRemoteUserJoined
                  ? provider.callDuration
                  : 'Calling...',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom controls
  Widget _buildBottomControls(CallProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: provider.isMuted ? Icons.mic_off : Icons.mic,
              label: provider.isMuted ? 'Unmute' : 'Mute',
              onPressed: _toggleMute,
              isActive: !provider.isMuted,
            ),

            // Video button (only for video calls)
            if (widget.isVideoCall)
              _buildControlButton(
                icon: provider.isVideoEnabled
                    ? Icons.videocam
                    : Icons.videocam_off,
                label: provider.isVideoEnabled ? 'Camera' : 'Camera Off',
                onPressed: _toggleVideo,
                isActive: provider.isVideoEnabled,
              ),

            // Speaker button (only for audio calls)
            if (!widget.isVideoCall)
              _buildControlButton(
                icon: provider.isSpeakerEnabled
                    ? Icons.volume_up
                    : Icons.volume_off,
                label: provider.isSpeakerEnabled ? 'Speaker' : 'Speaker Off',
                onPressed: _toggleSpeaker,
                isActive: provider.isSpeakerEnabled,
              ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              label: 'End',
              onPressed: _endCall,
              backgroundColor: Colors.red,
              isActive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: backgroundColor ??
              (isActive ? Colors.white.withOpacity(0.3) : Colors.grey[800]),
          elevation: 0,
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
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