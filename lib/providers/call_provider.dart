import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/agora_config.dart';

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

class CallProvider extends ChangeNotifier {
  // Call state
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = true;
  bool _isRemoteUserJoined = false;
  int _remoteUid = 0;

  // Call timer
  int _callDurationSeconds = 0;
  Timer? _timer;

  // Getters
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  bool get isRemoteUserJoined => _isRemoteUserJoined;
  int get remoteUid => _remoteUid;
  String get callDuration => _formatDuration(_callDurationSeconds);

  // Start call timer
  void startTimer() {
    _callDurationSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDurationSeconds++;
      notifyListeners();
    });
  }

  // Stop call timer
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
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

  // Toggle speaker
  void toggleSpeaker() {
    _isSpeakerEnabled = !_isSpeakerEnabled;
    notifyListeners();
  }

  // Remote user joined
  void onRemoteUserJoined(int uid) {
    _isRemoteUserJoined = true;
    _remoteUid = uid;
    notifyListeners();
  }

  // Remote user left
  void onRemoteUserLeft() {
    _isRemoteUserJoined = false;
    _remoteUid = 0;
    notifyListeners();
  }

  // Format duration (hh:mm:ss)
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
    _remoteUid = 0;
    _callDurationSeconds = 0;
    stopTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}