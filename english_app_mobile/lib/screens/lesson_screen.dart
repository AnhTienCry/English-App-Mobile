import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../api/api_client.dart';
import '../config/api_config.dart';
import 'lesson_topics_screen.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<dynamic> _lessons = [];
  late AnimationController _progressController;
  Map<String, int> _localLessonPercents = {}; // persist locally
  Set<String> _serverCompletedLessons = {}; // keep server-side completed list

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadLocalLessonPercents();
    _fetchProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalLessonPercents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('lesson_percent_'));
    for (final key in keys) {
      final lessonId = key.replaceFirst('lesson_percent_', '');
      final percent = prefs.getInt(key) ?? 0;
      _localLessonPercents[lessonId] = percent;
    }
  }

  Future<void> _saveLocalLessonPercent(String lessonId, int percent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lesson_percent_$lessonId', percent);
    _localLessonPercents[lessonId] = percent;
  }

  // new helper: tính percent cho lesson từ per-topic stats lưu local
  Future<int> _computeLocalPercentForLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('topic_stats_$lessonId');
    if (raw == null) return 0;
    try {
      final Map decoded = jsonDecode(raw) as Map;
      int sumCorrect = 0;
      int sumTotal = 0;
      decoded.forEach((topicId, mapVal) {
        if (mapVal is Map) {
          final c = (mapVal['correct'] is num) ? (mapVal['correct'] as num).toInt() : 0;
          final t = (mapVal['total'] is num) ? (mapVal['total'] as num).toInt() : 0;
          sumCorrect += c;
          sumTotal += t;
        }
      });
      if (sumTotal > 0) {
        return ((sumCorrect / sumTotal) * 100).round();
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _fetchProgress() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await dio.get("${ApiConfig.baseUrl}/api/lessons/progress/me");
      final data = res.data;
      if (data is Map && data['items'] is List) {
        final lessons = List.from(data['items']);

        // Nếu server trả progress doc (ví dụ completedLessons) => dùng để tính locked
        final serverCompletedLessons = <String>{};
        if (data['progress'] is Map && data['progress']['completedLessons'] is List) {
          for (var id in data['progress']['completedLessons']) serverCompletedLessons.add(id.toString());
        }
        // fallback: nếu each item có isCompleted flag thì collect
        for (var l in lessons) {
          final lessonId = (l['id'] ?? l['_id'] ?? '').toString();
          if ((l['isCompleted'] == true) || (l['is_completed'] == true)) serverCompletedLessons.add(lessonId);
        }

        // store to state so we can recompute locks later without refetch
        _serverCompletedLessons = serverCompletedLessons;
        for (var i = 0; i < lessons.length; i++) {
          final l = lessons[i];
          final lessonId = (l['id'] ?? l['_id'] ?? '').toString();
          final serverPercent = (l['percent'] is int)
              ? l['percent']
              : int.tryParse(l['percent']?.toString() ?? '0') ?? 0;

          final localPercentFromTopics = await _computeLocalPercentForLesson(lessonId);
          final savedLocalPercent = _localLessonPercents[lessonId] ?? 0;

          final int finalPercent = savedLocalPercent > 0
              ? savedLocalPercent
              : (localPercentFromTopics > 0 ? localPercentFromTopics : serverPercent);

          // decide completed: server explicit OR computed >=100
          final bool serverMarkedCompleted = serverCompletedLessons.contains(lessonId);
          l['percent'] = finalPercent;
          l['isCompleted'] = serverMarkedCompleted || finalPercent >= 100;

          // All lessons unlocked — user can open any lesson in any order
          l['locked'] = false;

          // persist higher local percent
          final prevLocal = _localLessonPercents[lessonId] ?? 0;
          if (finalPercent > prevLocal) await _saveLocalLessonPercent(lessonId, finalPercent);
        }

        if (mounted) setState(() => _lessons = lessons);
        _progressController.forward(from: 0);
      } else {
        setState(() => _error = "Unexpected response");
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLesson(dynamic lesson) async {
    if (lesson['locked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Lesson đang bị khóa. Hãy hoàn thành lesson trước!')),
            ],
          ),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonTopicsScreen(
          lessonId: lesson['id'],
          lessonTitle: lesson['title'] ?? 'Lesson',
        ),
      ),
    );

    if (result is Map && result.containsKey('percent') && result['lessonId'] == lesson['id']) {
      final newPercent = result['percent'] is int ? result['percent'] : int.tryParse(result['percent'].toString()) ?? 0;
      setState(() {
        final idx = _lessons.indexWhere((x) => (x['id'] ?? x['_id'] ?? '') == lesson['id']);
        if (idx != -1) {
          _lessons[idx]['percent'] = newPercent;
          if (result.containsKey('completed') && result['completed'] == true) {
            _lessons[idx]['isCompleted'] = true;
          }
        }
      });
      // save locally
      await _saveLocalLessonPercent(lesson['id'], newPercent);

      // recompute locks for whole list locally so next lesson can unlock without refetch
      _recomputeLocks();
      // trigger animation/update
      if (mounted) setState(() {});
      
      // nếu user chọn mở bài tiếp (openNext), tìm lesson kế tiếp và mở nếu đã unlocked
      if (result['openNext'] == true) {
        final idx = _lessons.indexWhere((x) => (x['id'] ?? x['_id'] ?? '') == lesson['id']);
        final nextIdx = idx + 1;
        if (nextIdx >= 0 && nextIdx < _lessons.length) {
          final nextLesson = _lessons[nextIdx];
          // nếu đã unlocked thì tự mở, nếu chưa thì recomputeLocks / không mở
          if (nextLesson['locked'] != true) {
            // delay nhỏ để UI cập nhật trước khi push
            await Future.delayed(const Duration(milliseconds: 250));
            if (mounted) await _openLesson(nextLesson);
          }
        }
      }
    } else if (result is Map && result['items'] is List) {
      setState(() => _lessons = List.from(result['items']));
      _progressController.forward(from: 0);
    } else if (result == true) {
      await _fetchProgress();
    }
  }

  // Lấy màu sắc rực rỡ cho mỗi lesson
  List<Color> _getCardColors(int index, bool completed, bool locked) {
    if (completed) {
      return [const Color(0xFF10B981), const Color(0xFF059669), const Color(0xFF047857)];
    }
    if (locked) {
      return [Colors.grey.shade400, Colors.grey.shade500];
    }

    final colorSets = [
      [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F), const Color(0xFFC44569)], // Đỏ hồng
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D), const Color(0xFF0F9B8E)], // Xanh ngọc
      [const Color(0xFFFFA502), const Color(0xFFFF793F), const Color(0xFFFF6348)], // Cam rực
      [const Color(0xFF5F27CD), const Color(0xFF6C5CE7), const Color(0xFF341F97)], // Tím đậm
      [const Color(0xFFFF6BCB), const Color(0xFFE056FD), const Color(0xFFC44BC4)], // Hồng tím
      [const Color(0xFF00D2FF), const Color(0xFF3A7BD5), const Color(0xFF0575E6)], // Xanh dương
      [const Color(0xFFFEAC5E), const Color(0xFFC779D0), const Color(0xFF4BC0C8)], // Gradient rainbow
      [const Color(0xFF26DE81), const Color(0xFF20BF6B), const Color(0xFF2AB573)], // Xanh lá sáng
    ];

    return colorSets[index % colorSets.length];
  }

  // Lấy màu cho timeline node
  List<Color> _getNodeColors(int index, bool completed, bool locked) {
    if (completed) {
      return [const Color(0xFF10B981), const Color(0xFF059669)];
    }
    if (locked) {
      return [Colors.grey.shade400, Colors.grey.shade500];
    }

    final colorSets = [
      [const Color(0xFFFF6B6B), const Color(0xFFC44569)],
      [const Color(0xFF4ECDC4), const Color(0xFF0F9B8E)],
      [const Color(0xFFFFA502), const Color(0xFFFF6348)],
      [const Color(0xFF5F27CD), const Color(0xFF341F97)],
      [const Color(0xFFFF6BCB), const Color(0xFFC44BC4)],
      [const Color(0xFF00D2FF), const Color(0xFF0575E6)],
      [const Color(0xFFFEAC5E), const Color(0xFF4BC0C8)],
      [const Color(0xFF26DE81), const Color(0xFF2AB573)],
    ];

    return colorSets[index % colorSets.length];
  }

  Widget _buildLessonCard(dynamic l, int index) {
    final title = l['title'] ?? 'Lesson';
    final desc = (l['description'] ?? '').toString();
    final completed = (l['isCompleted'] == true);
    final locked = l['locked'] == true;
    final percentRaw = l['percent'] ?? 0;
    final percent = (percentRaw is int) ? percentRaw : int.tryParse(percentRaw.toString()) ?? 0;
    final cardColors = _getCardColors(index, completed, locked);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: InkWell(
        onTap: locked ? null : () => _openLesson(l),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: cardColors[0].withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: cardColors[1].withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      locked ? Icons.lock_rounded : (completed ? Icons.check_circle_rounded : Icons.auto_stories_rounded),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.4,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                widthFactor: (percent / 100) * _progressController.value,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$percent%',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineNode(dynamic l, bool locked, int index) {
    final completed = (l['isCompleted'] == true);
    final nodeColors = _getNodeColors(index, completed, locked);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: locked ? null : () => _openLesson(l),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: nodeColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: nodeColors[0].withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: nodeColors[1].withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            completed ? Icons.check_circle_rounded : (locked ? Icons.lock_rounded : Icons.star_rounded),
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  // Tính toán offset cho hiệu ứng zigzag
  double _calculateOffset(int index) {
    final pattern = index % 4;
    switch (pattern) {
      case 0:
        return 0;
      case 1:
        return 30;
      case 2:
        return 50;
      case 3:
        return 30;
      default:
        return 0;
    }
  }

  // recompute locked state for lessons using serverCompleted + local percents (threshold 70)
  void _recomputeLocks() {
    // Unlock every lesson so user can open any lesson freely
    for (var i = 0; i < _lessons.length; i++) {
      _lessons[i]['locked'] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
                Color(0xFFF093FB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Learning Path',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _fetchProgress,
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đang tải lessons...',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '✨ Chuẩn bị hành trình học tập ✨',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      )
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade300, Colors.pink.shade300],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.purple.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _fetchProgress,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Thử lại',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchProgress,
        color: Colors.purple.shade600,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final l = _lessons[i];
                    final locked = l['locked'] == true;
                    final offset = _calculateOffset(i);
                    final isLeft = i % 2 == 0;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: isLeft ? 20 + offset : 20,
                        right: !isLeft ? 20 + offset : 20,
                        bottom: 20,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Card
                          Padding(
                            padding: EdgeInsets.only(
                              left: isLeft ? 40 : 0,
                              right: !isLeft ? 40 : 0,
                            ),
                            child: _buildLessonCard(l, i),
                          ),
                          // Timeline node
                          Positioned(
                            left: isLeft ? 0 : null,
                            right: !isLeft ? 0 : null,
                            top: 15,
                            child: _buildTimelineNode(l, locked, i),
                          ),
                          // Connecting line to previous lesson
                          if (i > 0)
                            Positioned(
                              left: isLeft ? 30 : null,
                              right: !isLeft ? 30 : null,
                              top: -20,
                              child: TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 800 + (i * 100)),
                                tween: Tween<double>(begin: 0, end: 1),
                                builder: (context, double value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: CustomPaint(
                                      size: const Size(2, 35),
                                      painter: _DashedLinePainter(
                                        color: Colors.grey.shade400,
                                        progress: value,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: _lessons.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter cho đường nét đứt
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double progress;

  _DashedLinePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startY = 0;
    final endY = size.height * progress;

    while (startY < endY) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, (startY + dashWidth).clamp(0, endY)),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}