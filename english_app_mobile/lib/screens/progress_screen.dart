import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../config/api_config.dart';
import 'quiz_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _progress;
  List<dynamic> _recentTopics = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await dio.get("${ApiConfig.baseUrl}/api/progressions/me");
      final data = res.data;
      setState(() {
        _progress = data is Map<String, dynamic> ? Map<String, dynamic>.from(data) : null;
        _recentTopics = (data?['recentTopics'] is List) ? List<Map<String, dynamic>>.from(data['recentTopics']) : <dynamic>[];
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retryTopic(dynamic topic) async {
    final id = topic['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    final done = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizScreen(topicId: id)),
    );
    if (done == true) {
      await _loadProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Progress', style: GoogleFonts.poppins())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
        onRefresh: _loadProgress,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummary(),
            const SizedBox(height: 12),
            Text('Recent Topics', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._recentTopics.map((t) => _topicTile(t)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final total = _progress?['totalScore'] ?? _progress?['total'] ?? 0;
    final completed = _progress?['completedLessons'] ?? _progress?['completed'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Completed: $completed • Score: $total', style: GoogleFonts.poppins(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicTile(dynamic t) {
    final title = t['title']?.toString() ?? 'Topic';
    final id = t['_id']?.toString() ?? '';
    return Card(
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        trailing: ElevatedButton(
          onPressed: id.isEmpty ? null : () => _retryTopic(t),
          child: const Text('Retry'),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error ?? 'Error', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: _loadProgress, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]),
    ),
  );
}
