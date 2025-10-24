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
  Map<String, dynamic>? _progress; // from /api/progressions/me
  List<dynamic> _recentTopics = [];
  List<dynamic> _lessonsProgress = []; // from /api/lessons/progress/me

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        dio.get("${ApiConfig.baseUrl}/api/progressions/me"),
        dio.get("${ApiConfig.baseUrl}/api/lessons/progress/me"),
      ]);

      final progRes = responses[0];
      final lessonsRes = responses[1];

      final progData = progRes.data;
      final lessonsData = lessonsRes.data;

      setState(() {
        _progress = progData is Map<String, dynamic> ? Map<String, dynamic>.from(progData) : null;
        _recentTopics = (progData?['recentTopics'] is List)
            ? List<Map<String, dynamic>>.from(progData['recentTopics'])
            : <dynamic>[];

        // lessonsData expected { items: [...] }
        if (lessonsData is Map && lessonsData['items'] is List) {
          _lessonsProgress = List<dynamic>.from(lessonsData['items']);
        } else if (lessonsData is List) {
          _lessonsProgress = List<dynamic>.from(lessonsData);
        } else {
          _lessonsProgress = <dynamic>[];
        }
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Open quiz for retry
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

  // compute overall percent across lessons weighted by totalQuestions
  double get _overallPercent {
    int totalQ = 0;
    int totalCorrect = 0;
    for (final l in _lessonsProgress) {
      final tq = (l['totalQuestions'] is int) ? l['totalQuestions'] as int : int.tryParse(l['totalQuestions']?.toString() ?? '0') ?? 0;
      final tc = (l['totalCorrect'] is int) ? l['totalCorrect'] as int : int.tryParse(l['totalCorrect']?.toString() ?? '0') ?? 0;
      totalQ += tq;
      totalCorrect += tc;
    }
    if (totalQ == 0) return 0.0;
    return (totalCorrect / totalQ) * 100.0;
  }

  int get _completedLessonsCount {
    if (_progress != null) {
      final cls = _progress!['completedLessons'];
      if (cls is List) return cls.length;
      if (cls is int) return cls;
    }
    // fallback count from lessonsProgress
    return _lessonsProgress.where((l) => (l['isCompleted'] == true)).length;
  }

  Widget _buildSummaryCard() {
    final overall = _overallPercent;
    final completed = _completedLessonsCount;
    final totalLessons = _lessonsProgress.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade600, Colors.purple.shade300]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // circular percent
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: (overall / 100).clamp(0.0, 1.0),
                  strokeWidth: 10,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white24,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${overall.round()}%', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Progress', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Progress', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Completed $completed of $totalLessons lessons', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (overall / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text('${overall.round()}%', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTile(dynamic l) {
    final title = (l['title'] ?? 'Lesson').toString();
    final percentRaw = l['percent'] ?? 0;
    final percent = (percentRaw is int) ? percentRaw : int.tryParse(percentRaw.toString()) ?? 0;
    final totalQ = (l['totalQuestions'] is int) ? l['totalQuestions'] as int : int.tryParse(l['totalQuestions']?.toString() ?? '0') ?? 0;
    final totalC = (l['totalCorrect'] is int) ? l['totalCorrect'] as int : int.tryParse(l['totalCorrect']?.toString() ?? '0') ?? 0;
    final completed = l['isCompleted'] == true;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: $totalC / $totalQ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (percent / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        color: completed ? Colors.green : Colors.purple,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: completed ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$percent%', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTopicTile(dynamic t) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress', style: GoogleFonts.poppins()),
        backgroundColor: Colors.purple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadProgress,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      Text('Lessons', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (_lessonsProgress.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('No lesson progress yet', style: GoogleFonts.poppins(color: Colors.black54)),
                        )
                      else
                        ..._lessonsProgress.map((l) => _buildLessonTile(l)).toList(),
                      const SizedBox(height: 16),
                      Text('Recent Topics', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (_recentTopics.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('No recent topics', style: GoogleFonts.poppins(color: Colors.black54)),
                        )
                      else
                        ..._recentTopics.map((t) => _buildRecentTopicTile(t)).toList(),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
    );
  }
}
