// class AgoraConfig {
//   static const String appId = "bfaa17edba57489bbb0c6066128e3856";
//   static const String channelName = "doctor_appointment_call";
//   static const String token = "007eJxTYFh1YhWT8VP5C7+yeZT3fRLr2fWGwajhatLDyRxJM1ZnqAUpMCSlJSYamqemJCWamptYWCYlJRkkmxmYmRkaWaQaW5iaTVTPy2wIZGTo9wlkZGSAQBBfnCElP7kkvyg+saAgPzOvJDc1ryQ+OTEnh4EBAAWiJts=";
// }


// class AgoraConfig {
//   static const String appId = "bfaa17edba57489bbb0c6066128e3856";
//   static const String channelName = "doctor-appointment-app";
//   static const String token = '007eJxTYChrtlyiqnrvVMqyVS67DZQ6LKYvV59Y8XN346vozd0SaTMVGJLSEhMNzVNTkhJNzU0sLJOSkgySzQzMzAyNLFKNLUzNvl/PyWwIZGRYepKVgREKQXwxhpT85JL8It3EgoL8zLyS3NS8EhCbgQEAGI0npA==';
// }

class AgoraConfig {
  // Your Agora App ID
  static const String appId = "bfaa17edba57489bbb0c6066128e3856";

  // Channel name - MUST be same on both devices
  static const String channelName = "doctor_appointment_call";

  // For testing, use empty token (testing mode) or null
  // Tokens are UID-specific, so static tokens cause issues
  static const String token = "007eJxTYMh5b9TK1J9pcW+P53khd2Ovv2e9tr+L+7NnWZDy/vrrW7wVGJLSEhMNzVNTkhJNzU0sLJOSkgySzQzMzAyNLFKNLUzNdMvzMxsCGRmMD9UzMTJAIIgvzpCSn1ySXxSfWFCQn5lXkpuaVxKfnJiTw8AAAGqdKEA="; // Set to null for testing mode

// IMPORTANT: Each device will get auto-assigned UID by Agora (uid: 0)
// This allows both devices to join successfully
}
