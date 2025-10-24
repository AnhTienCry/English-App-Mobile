// lesson_rank_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tower_screen.dart';

class LessonRankScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  const LessonRankScreen({super.key, required this.lessonId, required this.lessonTitle});

  @override
  State<LessonRankScreen> createState() => _LessonRankScreenState();
}

class _LessonRankScreenState extends State<LessonRankScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade800,
              Colors.deepOrange.shade600,
              Colors.red.shade500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Rank Mode',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.lessonTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Header info
                      FadeTransition(
                        opacity: _controller,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve: Curves.easeOut,
                          )),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade100, Colors.red.shade100],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.shade300, width: 2),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.castle_rounded, size: 48, color: Colors.deepOrange),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chào mừng đến Rank Tower!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.deepOrange.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chinh phục từng tầng để leo rank cao hơn 🏆',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Tower Card - Nút chính để vào Tower
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.3, 1.0),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                          )),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TowerScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade600,
                                    Colors.deepOrange.shade600,
                                    Colors.red.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.castle_rounded,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Rank Tower',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black.withOpacity(0.3),
                                                      offset: const Offset(0, 2),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Vượt qua từng tầng thách thức',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.white.withOpacity(0.95),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Mỗi tầng là một thử thách mới. Hoàn thành để mở khóa tầng tiếp theo!',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.white.withOpacity(0.95),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Features
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.5, 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tính năng nổi bật',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              icon: Icons.emoji_events_rounded,
                              title: 'Hệ thống Rank',
                              description: 'Leo rank từ Bronze đến Challenger',
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                              icon: Icons.layers_rounded,
                              title: 'Nhiều tầng thử thách',
                              description: 'Độ khó tăng dần theo từng tầng',
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                              icon: Icons.star_rounded,
                              title: 'Phần thưởng hấp dẫn',
                              description: 'Nhận điểm và huy hiệu đặc biệt',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}