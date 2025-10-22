import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import '../config/network_config.dart';
import '../utils/network_test.dart';
import '../utils/connection_test.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      // Test basic connection
      final response = await dio.get('/health');
      setState(() {
        _status = '✅ Connection successful!\nBase URL: ${NetworkConfig.baseUrl}\nResponse: ${response.data}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Connection failed!\nBase URL: ${NetworkConfig.baseUrl}\nError: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing login...';
    });

    try {
      final response = await dio.post(ApiConfig.loginEndpoint, data: {
        'email': 'student@example.com',
        'password': '123123',
      });
      
      setState(() {
        _status = '✅ Login successful!\nUser: ${response.data['user']['email']}\nRole: ${response.data['user']['role']}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Login failed!\nError: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAllConnections() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing all connections...';
    });

    try {
      final results = await ConnectionTest.testAllUrls();
      final statusText = ConnectionTest.formatResults(results);
      
      setState(() {
        _status = statusText;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Test failed!\nError: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Base URL: ${NetworkConfig.baseUrl}'),
                    Text('Login Endpoint: ${ApiConfig.loginEndpoint}'),
                    Text('Profile Endpoint: ${ApiConfig.profileEndpoint}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLogin,
              child: const Text('Test Login'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAllConnections,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test All Connections'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _status,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
