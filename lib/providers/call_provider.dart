import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../config/agora_config.dart';

class CallProvider extends ChangeNotifier {
  late RtcEngine engine;
  int? remoteUid;
  bool isJoined = false;
  bool isMuted = false;
  bool isVideoOn = true;

  Duration callDuration = Duration.zero;
  Timer? _timer;

  Future<void> initAgora(bool isVideoCall) async {
    engine = createAgoraRtcEngine();

    await engine.initialize(
      RtcEngineContext(appId: AgoraConfig.appId),
    );

    if (isVideoCall) {
      await engine.enableVideo();
    } else {
      await engine.disableVideo();
      await engine.enableAudio();
    }

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          isJoined = true;
          _startTimer();
          notifyListeners();
        },
        onUserJoined: (connection, uid, elapsed) {
          remoteUid = uid;
          notifyListeners();
        },
        onUserOffline: (connection,uid,reason) {
          remoteUid = null;
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
}
