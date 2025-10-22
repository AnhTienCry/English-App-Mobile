// Force configuration for immediate testing
// This file will override network_config.dart for testing purposes

class ForceConfig {
  // Force use the working URL based on debug results
  // Change this based on your debug screen results
  
  // If 10.0.2.2:4000 works (Android emulator):
  static const String baseUrl = 'http://10.0.2.2:4000';
  
  // If localhost:4000 works (iOS simulator or web):
  // static const String baseUrl = 'http://localhost:4000';
  
  // If 127.0.0.1:4000 works:
  // static const String baseUrl = 'http://127.0.0.1:4000';
  
  // If you need to use your computer's IP (real device):
  // static const String baseUrl = 'http://192.168.1.100:4000'; // Replace with your IP
}
