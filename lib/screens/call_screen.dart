import 'package:calling_app/config/agora_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class CallScreen extends StatefulWidget {
  final bool isVideoCall;
  final String name;
  final String imageUrl;

  const CallScreen({
    super.key,
    required this.isVideoCall,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {

  late CallProvider callProvider;

  @override
  void initState() {
    _initAgoraCall();
    super.initState();
  }

  void _initAgoraCall() {
    callProvider = Provider.of<CallProvider>(context,listen: false);
    // callProvider = CallProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callProvider.initAgora(widget.isVideoCall);
    });

  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (_, provider, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              /// Remote Video
              if (provider.remoteUid != null && widget.isVideoCall)
                AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: provider.engine,
                    canvas: VideoCanvas(uid: provider.remoteUid),
                    connection: const RtcConnection(
                      channelId: AgoraConfig.channelName,
                    ),
                  ),
                ),

              /// Local Video (small)
              if (widget.isVideoCall)
                Positioned(
                  top: 40,
                  right: 20,
                  child: SizedBox(
                    width: 120,
                    height: 160,
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: provider.engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),

              /// Top Info
              Positioned(
                top: 40,
                left: 20,
                child: Row(
                  children: [
                    // CircleAvatar(child: Image.network(imageUrl)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name,
                            style: const TextStyle(color: Colors.white)),
                        Text(
                          provider.callDuration.toString().split('.').first,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              /// Bottom Controls
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        provider.isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                      onPressed: provider.toggleMute,
                    ),
                    IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.red),
                      iconSize: 50,
                      onPressed: () async {
                        await provider.endCall();
                        Navigator.pop(context);
                      },
                    ),
                    if (widget.isVideoCall)
                      IconButton(
                        icon: Icon(
                          provider.isVideoOn
                              ? Icons.videocam
                              : Icons.videocam_off,
                          color: Colors.white,
                        ),
                        onPressed: provider.toggleVideo,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
