import 'package:permission_handler/permission_handler.dart';

class Utils {
  static Future<void> requestCallPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }
}
