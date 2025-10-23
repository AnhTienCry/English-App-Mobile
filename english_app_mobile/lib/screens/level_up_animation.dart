import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelUpAnimation extends StatefulWidget {
  final int level;
  const LevelUpAnimation({super.key, required this.level});

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Hiện chữ sau 1 giây
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _showText = true);
    });

    // Tự động thoát sau 4 giây
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon hiệu ứng phóng to
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _scaleController,
                curve: Curves.elasticOut,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 160,
              ),
            ),
            const SizedBox(height: 30),
            // Chữ hiện dần
            AnimatedOpacity(
              opacity: _showText ? 1 : 0,
              duration: const Duration(milliseconds: 700),
              child: Column(
                children: [
                  Text(
                    "LEVEL ${widget.level}",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Congratulations! 🎉",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
