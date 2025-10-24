import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lesson_screen.dart';
import 'lesson_rank_screen.dart';

class LessonOptionScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  const LessonOptionScreen({super.key, required this.lessonId, required this.lessonTitle});

  @override
  State<LessonOptionScreen> createState() => _LessonOptionScreenState();
}

class _LessonOptionScreenState extends State<LessonOptionScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
              Colors.deepPurple.shade800,
              Colors.purple.shade600,
              Colors.pink.shade400,
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
                          Text(
                            'Chọn chế độ học',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.lessonTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
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

              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
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
                      // Tiêu đề
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOut,
                        )),
                        child: FadeTransition(
                          opacity: _controller,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.purple.shade100, Colors.pink.shade100],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.school_rounded, size: 48, color: Colors.deepPurple),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Chọn cách bạn muốn học',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepPurple.shade800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                      // Normal Mode Card
                      _buildModeCard(
                        context,
                        delay: 0.2,
                        title: 'Normal Mode',
                        subtitle: 'Học theo lộ trình từng bước',
                        description: 'Lessons → Topics → Quiz → Vocabulary',
                        icon: Icons.auto_stories_rounded,
                        gradientColors: [
                          const Color(0xFF667EEA),
                          const Color(0xFF764BA2),
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LessonScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Rank Mode Card
                      _buildModeCard(
                        context,
                        delay: 0.4,
                        title: 'Rank Mode',
                        subtitle: 'Chinh phục tháp tri thức',
                        description: 'Vượt qua từng tầng để đạt rank cao hơn 🏆',
                        icon: Icons.emoji_events_rounded,
                        gradientColors: [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFFFA502),
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonRankScreen(
                                lessonId: widget.lessonId,
                                lessonTitle: widget.lessonTitle,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Thông tin thêm
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(0.6, 1.0),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200, width: 2),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Mỗi chế độ mang lại trải nghiệm học tập khác nhau. Hãy chọn phù hợp với bạn!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.blue.shade900,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
      BuildContext context, {
        required double delay,
        required String title,
        required String subtitle,
        required String description,
        required IconData icon,
        required List<Color> gradientColors,
        required VoidCallback onTap,
      }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, delay + 0.4),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: Colors.white, size: 32),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bắt đầu',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
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
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            description,
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
    );
  }
}