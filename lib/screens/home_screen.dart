import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';
import 'call_screen.dart';
import 'incoming_call_screen.dart';

/*
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Appointment Call Demo'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // App Logo/Title
          const Icon(Icons.local_hospital, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Agora RTC Call Demo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Test Audio & Video Calls',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),

          // Doctor Profile Card
          _buildProfileCard(
            name: 'Dr. Sarah Johnson',
            role: 'Cardiologist',
            imageUrl: null,
          ),

          const SizedBox(height: 32),

          // Call Buttons
          const Text(
            'Start a call as:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Patient - Video Call
          _buildCallButton(
            context: context,
            label: 'Patient - Video Call',
            icon: Icons.videocam,
            color: Colors.blue,
            onPressed: () => _startCall(
              context,
              userName: 'John Doe',
              userRole: 'Patient',
              isVideoCall: true,
            ),
          ),

          const SizedBox(height: 12),

          // Patient - Audio Call
          _buildCallButton(
            context: context,
            label: 'Patient - Audio Call',
            icon: Icons.call,
            color: Colors.green,
            onPressed: () => _startCall(
              context,
              userName: 'John Doe',
              userRole: 'Patient',
              isVideoCall: false,
            ),
          ),

          const SizedBox(height: 12),

          // Doctor - Video Call
          _buildCallButton(
            context: context,
            label: 'Doctor - Video Call',
            icon: Icons.videocam,
            color: Colors.purple,
            onPressed: () => _startCall(
              context,
              userName: 'Dr. Sarah Johnson',
              userRole: 'Doctor',
              isVideoCall: true,
            ),
          ),

          const SizedBox(height: 12),

          // Doctor - Audio Call
          _buildCallButton(
            context: context,
            label: 'Doctor - Audio Call',
            icon: Icons.call,
            color: Colors.orange,
            onPressed: () => _startCall(
              context,
              userName: 'Dr. Sarah Johnson',
              userRole: 'Doctor',
              isVideoCall: false,
            ),
          ),

          const SizedBox(height: 32),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[900]),
                    const SizedBox(width: 8),
                    Text(
                      'Testing Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Open app on 2 devices\n'
                  '2. Both join same channel\n'
                  '3. Test audio/video controls\n'
                  '4. Check call timer & UI',
                  style: TextStyle(fontSize: 13, color: Colors.amber[900]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String role,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[300],
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Text(
                    name[0],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startCall(
    BuildContext context, {
    required String userName,
    required String userRole,
    required bool isVideoCall,
  }) {
    // Reset provider state before new call
    context.read<CallProvider>().reset();

    // Navigate to call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          userName: userName,
          userRole: userRole,
          isVideoCall: isVideoCall,
        ),
      ),
    );
  }
}
*/


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Appointment Call'),
        centerTitle: true,
      ),
      body: ListView(
      padding: const EdgeInsets.all(24.0),

        children: [
          const Icon(
            Icons.local_hospital,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Agora RTC Call Demo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time Audio & Video Calls',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),

          _buildProfileCard(
            name: 'Dr. Sarah Johnson',
            role: 'Cardiologist',
            imageUrl: null,
          ),

          const SizedBox(height: 32),

          const Text(
            'Make a call (Caller):',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildCallButton(
            context: context,
            label: 'Patient - Video Call',
            icon: Icons.videocam,
            color: Colors.blue,
            onPressed: () => _makeCall(
              context,
              userName: 'John Doe',
              userRole: 'Patient',
              isVideoCall: true,
            ),
          ),

          const SizedBox(height: 12),

          _buildCallButton(
            context: context,
            label: 'Patient - Audio Call',
            icon: Icons.call,
            color: Colors.green,
            onPressed: () => _makeCall(
              context,
              userName: 'John Doe',
              userRole: 'Patient',
              isVideoCall: false,
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Receive a call (Receiver):',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildCallButton(
            context: context,
            label: 'Doctor - Incoming Video Call',
            icon: Icons.videocam,
            color: Colors.purple,
            onPressed: () => _receiveCall(
              context,
              callerName: 'Dr. Sarah Johnson',
              callerRole: 'Doctor',
              isVideoCall: true,
            ),
          ),

          const SizedBox(height: 12),

          _buildCallButton(
            context: context,
            label: 'Doctor - Incoming Audio Call',
            icon: Icons.call,
            color: Colors.orange,
            onPressed: () => _receiveCall(
              context,
              callerName: 'Dr. Sarah Johnson',
              callerRole: 'Doctor',
              isVideoCall: false,
            ),
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[900]),
                    const SizedBox(width: 8),
                    Text(
                      'Testing Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Caller: Use "Make a call" buttons\n'
                      '• Receiver: Use "Receive a call" buttons\n'
                      '• Receiver sees incoming call screen\n'
                      '• Accept to start conversation\n'
                      '• Timer starts when both connected',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String role,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[300],
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Text(
              name[0],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _makeCall(
      BuildContext context, {
        required String userName,
        required String userRole,
        required bool isVideoCall,
      }) {
    context.read<CallProvider>().reset();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          userName: userName,
          userRole: userRole,
          isVideoCall: isVideoCall,
        ),
      ),
    );
  }

  void _receiveCall(
      BuildContext context, {
        required String callerName,
        required String callerRole,
        required bool isVideoCall,
      }) {
    context.read<CallProvider>().reset();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(
          callerName: callerName,
          callerRole: callerRole,
          isVideoCall: isVideoCall,
        ),
      ),
    );
  }
}
