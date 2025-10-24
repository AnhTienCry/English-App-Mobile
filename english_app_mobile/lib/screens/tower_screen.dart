// tower_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import 'quiz_screen.dart';

class TowerScreen extends StatefulWidget {
  const TowerScreen({super.key});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<dynamic> _levels = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fetchLevels();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLevels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await dio.get("${ApiConfig.baseUrl}/api/tower-levels");
      final data = res.data;
      if (data is List) {
        data.sort((a, b) {
          final lnA = (a['levelNumber'] ?? 0) as int;
          final lnB = (b['levelNumber'] ?? 0) as int;
          return lnB.compareTo(lnA); // Đảo ngược: tầng cao nhất ở trên
        });
        setState(() => _levels = data);
        _animationController.forward(from: 0);
      } else {
        setState(() => _error = "Unexpected response format.");
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLevel(dynamic level) async {
    final String levelId = level['_id']?.toString() ?? '';
    if (levelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Level ID không hợp lệ'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(levelId: levelId),
      ),
    );

    if (mounted) await _fetchLevels();
  }

  List<Color> _getTowerGradient(int index) {
    final gradients = [
      [const Color(0xFFFFD700), const Color(0xFFFFAA00)], // Gold - cao nhất
      [const Color(0xFFC0C0C0), const Color(0xFF999999)], // Silver
      [const Color(0xFFCD7F32), const Color(0xFF8B4513)], // Bronze
      [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)], // Đỏ
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)], // Xanh ngọc
      [const Color(0xFFFFA502), const Color(0xFFFF793F)], // Cam
      [const Color(0xFF5F27CD), const Color(0xFF341F97)], // Tím
      [const Color(0xFF00D2FF), const Color(0xFF3A7BD5)], // Xanh dương
    ];
    return gradients[index % gradients.length];
  }

  IconData _getTowerIcon(int index, int totalLevels) {
    if (index == 0) return Icons.emoji_events_rounded; // Tầng cao nhất
    if (index == totalLevels - 1) return Icons.foundation_rounded; // Tầng đáy
    if (index < 3) return Icons.stars_rounded; // Top 3
    return Icons.castle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF134E5E),
              const Color(0xFF71B280),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
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
                            '🏰 Rank Tower',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Chinh phục đỉnh cao tri thức',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        onPressed: _fetchLevels,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? _buildLoading()
                      : _error != null
                          ? _buildError()
                          : _levels.isEmpty
                              ? _buildEmpty()
                              : _buildTower(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
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
            '🏗️ Đang xây tháp...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
            Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.purple.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                onPressed: _fetchLevels,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Thử lại', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.layers_clear_rounded, size: 64, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có tầng nào',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tháp sẽ được xây dựng sớm thôi!',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTower() {
    return RefreshIndicator(
      onRefresh: _fetchLevels,
      color: Colors.blue.shade600,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final level = _levels[index];
                  final levelNum = level['levelNumber'] ?? (index + 1);
                  final title = (level['title'] ?? 'Tầng $levelNum').toString();
                  
                  return _buildTowerLevel(
                    level: level,
                    levelNum: levelNum,
                    title: title,
                    index: index,
                    totalLevels: _levels.length,
                  );
                },
                childCount: _levels.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowerLevel({
    required dynamic level,
    required int levelNum,
    required String title,
    required int index,
    required int totalLevels,
  }) {
    final colors = _getTowerGradient(index);
    final icon = _getTowerIcon(index, totalLevels);
    final isTop = index == 0;
    final delay = index * 0.08;

    // Tính toán độ rộng tháp (tầng càng cao càng hẹp)
    final double widthFactor = 1.0 - (index * 0.05).clamp(0.0, 0.4);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 80)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 12,
          left: MediaQuery.of(context).size.width * (1 - widthFactor) / 2,
          right: MediaQuery.of(context).size.width * (1 - widthFactor) / 2,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main tower card
            InkWell(
              onTap: () => _openLevel(level),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: isTop ? 4 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.6),
                      blurRadius: isTop ? 25 : 15,
                      offset: const Offset(0, 8),
                      spreadRadius: isTop ? 3 : 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BrickPatternPainter(),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          // Icon container
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: isTop ? 32 : 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title and level
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Tầng $levelNum',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTop ? 20 : 18,
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
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Arrow button
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Top badge cho tầng cao nhất
                    if (isTop)
                      Positioned(
                        top: -10,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.yellow.shade600, Colors.orange.shade600],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'TOP',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
            // Connecting line to next level
            if (index < totalLevels - 1)
              Positioned(
                bottom: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 800 + (index * 100)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors[1].withOpacity(0.6),
                                _getTowerGradient(index + 1)[0].withOpacity(0.6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Custom painter cho hiệu ứng gạch tường
class _BrickPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double brickHeight = 20;
    const double brickWidth = 40;

    for (double y = 0; y < size.height; y += brickHeight) {
      final offset = (y / brickHeight).floor() % 2 == 0 ? 0.0 : brickWidth / 2;
      for (double x = -brickWidth; x < size.width + brickWidth; x += brickWidth) {
        canvas.drawRect(
          Rect.fromLTWH(x + offset, y, brickWidth - 2, brickHeight - 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}