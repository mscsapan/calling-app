import 'dart:async';

import 'package:flutter/material.dart';

/*class CallProvider extends ChangeNotifier {
  late RtcEngine engine;
  int? remoteUid;
  bool isJoined = false;
  bool isMuted = false;
  bool isVideoOn = true;

  Duration callDuration = Duration.zero;
  Timer? _timer;

  Future<void> initAgora(bool isVideoCall) async {
    debugPrint("called initAgora");

    engine = createAgoraRtcEngine();

    await engine.initialize(
      RtcEngineContext(appId: AgoraConfig.appId,channelProfile: ChannelProfileType.channelProfileCommunication),
    );

    await engine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );

    await engine.enableAudio();

    if (isVideoCall) {
      await engine.enableVideo();
      await engine.startPreview();
    }

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          debugPrint("JOINED CHANNEL");
          notifyListeners();
        },
        onUserJoined: (_, uid, __) {
          debugPrint("REMOTE USER JOINED: $uid");
          remoteUid = uid;
          notifyListeners();
        },
      ),
    );

    await engine.joinChannel(
      token: AgoraConfig.token,
      channelId: AgoraConfig.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }



  void toggleMute() {
    isMuted = !isMuted;
    engine.muteLocalAudioStream(isMuted);
    notifyListeners();
  }

  void toggleVideo() {
    isVideoOn = !isVideoOn;
    engine.muteLocalVideoStream(!isVideoOn);
    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  Future<void> endCall() async {
    _timer?.cancel();
    await engine.leaveChannel();
    await engine.release();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.microphone, Permission.phone,
    ].request();

    permissions.forEach((permission, status) {
      if (status != PermissionStatus.granted) {
        debugPrint('⚠️ Permission $permission not granted: $status');
      }
    });
  }
}*/

enum CallStatus {
  calling,      // Initiating call
  ringing,      // Receiving call
  connecting,   // Accepting call
  connected,    // Call in progress
  ended         // Call ended
}

class CallProvider extends ChangeNotifier {
  // Call state
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = true;
  bool _isRemoteUserJoined = false;
  bool _isFrontCamera = true;
  bool _isRemoteVideoEnabled = true;  // Track remote user's video state
  int _remoteUid = 0;

  // Call status
  CallStatus _callStatus = CallStatus.calling;

  // UI visibility state
  bool _isUIVisible = false;  // Initially hidden
  Timer? _uiTimer;

  // Call type
  bool _isVideoCall = true;

  // Call timer
  int _callDurationSeconds = 0;
  Timer? _callTimer;

  // Getters
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  bool get isRemoteUserJoined => _isRemoteUserJoined;
  bool get isFrontCamera => _isFrontCamera;
  bool get isUIVisible => _isUIVisible;
  bool get isVideoCall => _isVideoCall;
  bool get isRemoteVideoEnabled => _isRemoteVideoEnabled;
  int get remoteUid => _remoteUid;
  CallStatus get callStatus => _callStatus;
  String get callDuration => _formatDuration(_callDurationSeconds);

  // Initialize with call type
  void initializeCallType(bool isVideo) {
    _isVideoCall = isVideo;
    _isVideoEnabled = isVideo;
    notifyListeners();
  }

  // Set call status
  void setCallStatus(CallStatus status) {
    _callStatus = status;
    notifyListeners();
  }

  // Start call timer (only when connected)
  void startTimer() {
    _callDurationSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationSeconds++;
      notifyListeners();
    });
  }

  // Stop call timer
  void stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  // Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  // Toggle video
  void toggleVideo() {
    _isVideoEnabled = !_isVideoEnabled;
    notifyListeners();
  }

  // Set remote video state
  void setRemoteVideoEnabled(bool enabled) {
    _isRemoteVideoEnabled = enabled;
    notifyListeners();
  }

  // Toggle speaker
  void toggleSpeaker() {
    _isSpeakerEnabled = !_isSpeakerEnabled;
    notifyListeners();
  }

  // Toggle camera (front/back)
  void toggleCamera() {
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }

  // Switch from audio call to video call
  void switchToVideoCall() {
    _isVideoCall = true;
    _isVideoEnabled = true;
    notifyListeners();
  }

  // Show UI with auto-hide timer (2 seconds)
  void showUI() {
    _isUIVisible = true;
    notifyListeners();
    _startUIAutoHideTimer();
  }

  // Hide UI immediately
  void hideUI() {
    _isUIVisible = false;
    _cancelUIAutoHideTimer();
    notifyListeners();
  }

  // Start auto-hide timer (2 seconds)
  void _startUIAutoHideTimer() {
    _cancelUIAutoHideTimer();
    _uiTimer = Timer(const Duration(seconds: 2), () {
      _isUIVisible = false;
      notifyListeners();
    });
  }

  // Cancel auto-hide timer
  void _cancelUIAutoHideTimer() {
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  // Remote user joined
  void onRemoteUserJoined(int uid) {
    _isRemoteUserJoined = true;
    _remoteUid = uid;
    _callStatus = CallStatus.connected;
    notifyListeners();

    // Start timer only when both users are connected
    if (_callTimer == null) {
      startTimer();
    }
  }

  // Remote user left
  void onRemoteUserLeft() {
    _isRemoteUserJoined = false;
    _remoteUid = 0;
    _callStatus = CallStatus.ended;
    stopTimer();
    notifyListeners();
  }

  // Format duration (mm:ss or hh:mm:ss)
  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Reset state
  void reset() {
    _isMuted = false;
    _isVideoEnabled = true;
    _isSpeakerEnabled = true;
    _isRemoteUserJoined = false;
    _isFrontCamera = true;
    _isUIVisible = false;
    _isVideoCall = true;
    _isRemoteVideoEnabled = true;
    _remoteUid = 0;
    _callDurationSeconds = 0;
    _callStatus = CallStatus.calling;
    stopTimer();
    _cancelUIAutoHideTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    stopTimer();
    _cancelUIAutoHideTimer();
    super.dispose();
  }
}