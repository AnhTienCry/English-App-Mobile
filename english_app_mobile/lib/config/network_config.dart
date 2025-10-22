import 'dart:io';

class NetworkConfig {
  // Auto-detect network configuration
  static String get baseUrl {
    if (Platform.isAndroid) {
      // For Android emulator - use 10.0.2.2 (localhost from emulator perspective)
      return 'http://10.0.2.2:4000';
    } else if (Platform.isIOS) {
      // For iOS simulator
      return 'http://localhost:4000';
    } else {
      // For web or other platforms
      return 'http://localhost:4000';
    }
  }
  
  // Manual configuration (uncomment and modify as needed)
  // static const String baseUrl = 'http://192.168.1.100:4000'; // Your computer's IP
  
  // Network timeout settings
  static const int connectTimeout = 10000; // 10 seconds
  static const int receiveTimeout = 10000; // 10 seconds
  static const int sendTimeout = 10000; // 10 seconds
}