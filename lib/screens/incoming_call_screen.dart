import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';
import 'call_screen.dart';
import 'dart:async';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerRole;
  final bool isVideoCall;
  final String? profileImageUrl;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerRole,
    required this.isVideoCall,
    this.profileImageUrl,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _ringTimer;
  int _ringCount = 0;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _startRinging();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _startRinging() {
    // Simulate ringing for 30 seconds, then auto-reject
    _ringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _ringCount++;
      if (_ringCount >= 30) {
        _rejectCall();
      }
    });
  }

  void _acceptCall() {
    _ringTimer?.cancel();
    context.read<CallProvider>().reset();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          userName: widget.callerName,
          userRole: widget.callerRole,
          isVideoCall: widget.isVideoCall,
          profileImageUrl: widget.profileImageUrl,
        ),
      ),
    );
  }

  void _rejectCall() {
    _ringTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top section with caller info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Caller profile picture with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.isVideoCall
                                    ? Colors.blue.withOpacity(0.5)
                                    : Colors.green.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: widget.profileImageUrl != null
                                ? NetworkImage(widget.profileImageUrl!)
                                : null,
                            child: widget.profileImageUrl == null
                                ? Text(
                              widget.callerName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 60,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Caller name
                  Text(
                    widget.callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Caller role
                  Text(
                    widget.callerRole,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Call type indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isVideoCall ? Icons.videocam : Icons.call,
                        color: widget.isVideoCall ? Colors.blue : Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isVideoCall
                            ? 'Incoming Video Call...'
                            : 'Incoming Audio Call...',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 48, left: 32, right: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  _buildCallButton(
                    icon: Icons.call_end,
                    label: 'Decline',
                    color: Colors.red,
                    onPressed: _rejectCall,
                  ),

                  // Accept button
                  _buildCallButton(
                    icon: widget.isVideoCall ? Icons.videocam : Icons.call,
                    label: 'Accept',
                    color: Colors.green,
                    onPressed: _acceptCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: '$label-button', // Unique hero tag
          onPressed: onPressed,
          backgroundColor: color,
          elevation: 8,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}