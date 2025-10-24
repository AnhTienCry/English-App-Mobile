import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/api_config.dart';
import '../api/api_client.dart'; // global dio
import '../screens/level_up_animation.dart'; // Level-up effect

class QuizScreen extends StatefulWidget {
  final String topicId;
  final String lessonId;
  final String? levelId; // Tower mode khi có giá trị

  const QuizScreen({super.key, this.topicId = '', this.lessonId = '', this.levelId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _fillController = TextEditingController();
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _quizFinished = false;
  int _timeSpentSeconds = 0;
  bool _isAnswered = false;
  String? _selectedAnswer;
  bool _isLoading = true;
  final Stopwatch _timer = Stopwatch();
  final Stopwatch _questionTimer = Stopwatch();

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _answers = [];

  bool get _isTowerMode => (widget.levelId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    fetchQuizzes();
  }

  Future<void> fetchQuizzes() async {
    try {
      final res = await dio.get("${ApiConfig.quizByTopicEndpoint}/${widget.topicId}");
      setState(() {
        _questions = res.data is List ? List.from(res.data) : <dynamic>[];
        _isLoading = false;
      });
      if (_questions.isNotEmpty) {
        _timer.start();
        _startQuestionTimer();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load quiz")),
        );
      }
    }
  }

  void _startQuestionTimer() {
    _questionTimer
      ..reset()
      ..start();
  }

  Future<void> _submitQuestionAttempt({
    required String topicId,
    required String quizId,
    required String questionId,
    required String userAnswer,
    required int score,
    required int timeSpent,
  }) async {
    try {
      await dio.post('/api/quizzes/submit-question', data: {
        'topicId': topicId,
        'quizId': quizId,
        'questionId': questionId,
        'userAnswer': userAnswer,
        'score': score,
        'timeSpent': timeSpent,
      });
    } catch (e) {
      debugPrint('❌ Error submitting question attempt: $e');
    }
  }

  bool _isAnswerCorrectForQuestion(dynamic q, String answer, [int index = -1]) {
    final corrRaw = q['correctAnswer'];
    final answerNormalized = answer.toString().trim().toLowerCase();
    if (corrRaw is int) {
      int idx = index;
      if (idx < 0) {
        final opts = List.from(q['options'] ?? []);
        idx = opts.indexWhere((o) => o.toString().trim().toLowerCase() == answerNormalized);
      }
      return idx == corrRaw;
    }
    final corrStr = corrRaw?.toString().trim().toLowerCase() ?? '';
    return corrStr == answerNormalized;
  }

  void _checkAnswer(String answer) async {
    if (_isAnswered || _questions.isEmpty) return;

    final q = _questions[_currentIndex];
    final isCorrect = _isAnswerCorrectForQuestion(q, answer);

    if (!mounted) return;
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      if (isCorrect) {
        _correctCount++;
        HapticFeedback.lightImpact();
      } else {
        _animationController.forward(from: 0);
        HapticFeedback.heavyImpact();
      }
    });

    final topicId = widget.topicId;
    final quizId = q['_id']?.toString() ?? '';
    final questionId = q['_id']?.toString() ?? '';
    final userAnswer = answer;
    final score = isCorrect ? 1 : 0;
    final timeSpent = _questionTimer.elapsed.inSeconds;

    _answers.add({
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'score': score,
      'timeSpent': timeSpent,
    });

    if (!_isTowerMode) {
      await _submitQuestionAttempt(
        topicId: topicId,
        quizId: quizId,
        questionId: questionId,
        userAnswer: userAnswer,
        score: score,
        timeSpent: timeSpent,
      );
    }

    _questionTimer.stop();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _selectedAnswer = null;
        _fillController.clear();
      });
      _startQuestionTimer();
    } else {
      _timer.stop();
      _submitResult();
    }
  }

  Future<void> _submitResult() async {
      if (_questions.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context, false);
        return;
      }

      final score = ((_correctCount / _questions.length) * 100).round();
      final timeSpent = _timer.elapsed.inSeconds;

      if (!mounted) return;
      setState(() => _quizFinished = true);

      try {
        _confettiController.play();
      } catch (_) {}

      // Tower mode: call submit with levelId
      if (_isTowerMode) {
        try {
          final payload = {
            'topicId': widget.topicId,
            'lessonId': widget.lessonId,
            'levelId': widget.levelId,
            'score': score,
            'timeSpent': timeSpent,
            'correctCount': _correctCount,
            'totalQuestions': _questions.length,
            'answers': _answers,
          };

          final res = await dio.post(ApiConfig.submitQuizEndpoint, data: payload);
          final data = res.data;
          debugPrint('Tower submit response: $data');

          if (data is Map && data['passed'] == true) {
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LevelUpAnimation(level: data['level']?['levelNumber'] ?? 1),
              ),
            );
            if (mounted) {
              // return progress + local stats so caller can update UI immediately
              Navigator.pop(context, {
                'passed': true,
                'progress': data['progress'],
                'correctCount': _correctCount,
                'totalQuestions': _questions.length,
                'lessonId': widget.lessonId,
                'topicId': widget.topicId,
              });
            }
            return;
          } else {
            if (!mounted) return;
            await _showResultDialog(score);
            if (mounted) Navigator.pop(context, {
              'passed': false,
              'correctCount': _correctCount,
              'totalQuestions': _questions.length,
              'lessonId': widget.lessonId,
              'topicId': widget.topicId,
            });
            return;
          }
        } catch (e) {
          debugPrint('❌ Tower submit error: $e');
          if (mounted) Navigator.pop(context, null);
          return;
        }
      }

      // Topic/Lesson mode
      try {
        final payload = {
          'topicId': widget.topicId,
          'lessonId': widget.lessonId,
          'score': score,
          'timeSpent': timeSpent,
          'correctCount': _correctCount,
          'totalQuestions': _questions.length,
          'answers': _answers,
        };

        final response = await dio.post(ApiConfig.submitQuizEndpoint, data: payload);
        debugPrint('Quiz submitted: ${response.data}');

        final resp = response.data;
        if (resp is Map && resp['passed'] == true) {
          await _showResultDialog(score);
          if (mounted) Navigator.pop(context, {
            'passed': true,
            'progress': resp['progress'] ?? resp['progression'] ?? {},
            'correctCount': _correctCount,
            'totalQuestions': _questions.length,
            'lessonId': widget.lessonId,
            'topicId': widget.topicId,
          });
          return;
        }

        if (!mounted) return;
        await _showResultDialog(score);
        // always return stats so caller can update local UI
        if (mounted) Navigator.pop(context, {
          'passed': (resp is Map && resp['passed'] == true),
          'correctCount': _correctCount,
          'totalQuestions': _questions.length,
          'lessonId': widget.lessonId,
          'topicId': widget.topicId,
        });
      } catch (e) {
        debugPrint('Error submitting quiz: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to submit quiz.')));
      }
    }

  Future<void> _showResultDialog(int score) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ConfettiResultDialog(score: score),
    );
  }

  Future<void> _finishQuiz() async {
    if (_quizFinished) return;
    setState(() => _quizFinished = true);

    final int totalQuestions = _questions.length;
    final bool passed = _correctCount >= 7;

    final body = {
      'topicId': widget.topicId,
      'lessonId': widget.lessonId,
      'levelId': widget.levelId,
      'correctCount': _correctCount,
      'totalQuestions': totalQuestions,
      'timeSpent': _timeSpentSeconds,
    };

    try {
      await dio.post(ApiConfig.submitQuizEndpoint, data: body);
    } catch (e) {
      // ignore network error for UX
      debugPrint('Finish submit error: $e');
    }

    if (!mounted) return;
    // include stats so caller (LessonTopicsScreen) updates percent/completion immediately
    Navigator.pop(context, {
      'passed': passed,
      'correctCount': _correctCount,
      'totalQuestions': totalQuestions,
      'lessonId': widget.lessonId,
      'topicId': widget.topicId,
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz'), backgroundColor: Colors.purple),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No questions available for this topic.'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
            ],
          ),
        ),
      );
    }

    if (_quizFinished) {
      return Scaffold(
        backgroundColor: Colors.deepPurple[50],
        body: Stack(
          alignment: Alignment.center,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.3,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.purple, size: 100),
                const SizedBox(height: 20),
                Text("Well done!",
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                const SizedBox(height: 8),
                const Text("You've completed this quiz!", style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ],
        ),
      );
    }

    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: Text("Question ${_currentIndex + 1}/${_questions.length}"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            color: Colors.purple,
            backgroundColor: Colors.purple.shade100,
            minHeight: 6,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final shake = _shakeAnimation.value;
                return Transform.translate(
                  offset: Offset(
                    _isAnswered && _selectedAnswer != q['correctAnswer'] && q['type'] == 'multiple_choice'
                        ? shake - 12
                        : 0,
                    0,
                  ),
                  child: child,
                );
              },
              child: Card(
                elevation: 6,
                shadowColor: Colors.purpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    q['question'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuestionType(q),
            ),
          ),
          if (_isAnswered)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                label: Text(
                  _currentIndex < _questions.length - 1 ? "Next Question" : "Finish Quiz",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  final bool isLast = _currentIndex == (_questions.length - 1);
                  if (isLast) {
                    _finishQuiz();
                  } else {
                    setState(() => _currentIndex++);
                    _isAnswered = false;
                    _selectedAnswer = null;
                    _fillController.clear();
                    _startQuestionTimer();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionType(dynamic q) {
    final type = q['type'] ?? 'multiple_choice';

    if (type == 'multiple_choice') {
      final options = List<String>.from(q['options'] ?? []);
      return ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isCorrect = _isAnswerCorrectForQuestion(q, option, index);
          final isSelected = option == _selectedAnswer;

          Color cardColor = Colors.white;
          IconData? icon;

          if (_isAnswered) {
            if (isSelected && isCorrect) {
              cardColor = Colors.green.shade300;
              icon = Icons.check_circle;
            } else if (isSelected && !isCorrect) {
              cardColor = Colors.red.shade300;
              icon = Icons.cancel_rounded;
            } else if (isCorrect) {
              cardColor = Colors.green.shade100;
              icon = Icons.check_rounded;
            }
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ListTile(
              leading: icon != null
                  ? Icon(icon, color: isCorrect ? Colors.green : Colors.red)
                  : null,
              title: Text(option, style: GoogleFonts.poppins(fontSize: 16)),
              onTap: _isAnswered ? null : () => _checkAnswer(option),
            ),
          );
        },
      );
    }

    if (type == 'fill_blank') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your answer:", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            TextField(
              controller: _fillController,
              enabled: !_isAnswered,
              decoration: InputDecoration(
                hintText: "Type your answer here...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.purple),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isAnswered)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  onPressed: () {
                    final answer = _fillController.text.trim();
                    if (answer.isNotEmpty) _checkAnswer(answer);
                  },
                  child: const Text("Submit Answer", style: TextStyle(color: Colors.white)),
                ),
              ),
            if (_isAnswered)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _fillController.text.trim().toLowerCase() ==
                          q['correctAnswer'].toString().trim().toLowerCase()
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fillController.text.trim().toLowerCase() ==
                              q['correctAnswer'].toString().trim().toLowerCase()
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _fillController.text.trim().toLowerCase() ==
                              q['correctAnswer'].toString().trim().toLowerCase()
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _fillController.text.trim().toLowerCase() ==
                                q['correctAnswer'].toString().trim().toLowerCase()
                            ? "✅ Correct!"
                            : "❌ Correct answer: ${q['correctAnswer']}",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    if (type == 'true_false') {
      final options = ['True', 'False'];
      return Column(
        children: options.map((opt) {
          final isCorrect = q['correctAnswer'].toString().toLowerCase() == opt.toLowerCase();
          final isSelected = _selectedAnswer == opt;

          Color cardColor = Colors.white;
          IconData? icon;

          if (_isAnswered) {
            if (isSelected && isCorrect) {
              cardColor = Colors.green.shade300;
              icon = Icons.check_circle;
            } else if (isSelected && !isCorrect) {
              cardColor = Colors.red.shade300;
              icon = Icons.cancel_rounded;
            } else if (isCorrect) {
              cardColor = Colors.green.shade100;
              icon = Icons.check_rounded;
            }
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: icon != null ? Icon(icon, color: isCorrect ? Colors.green : Colors.red) : null,
              title: Text(opt, style: GoogleFonts.poppins(fontSize: 16)),
              onTap: _isAnswered ? null : () => _checkAnswer(opt),
            ),
          );
        }).toList(),
      );
    }

    if (type == 'matching') {
      final List<dynamic> pairs = q['pairs'] ?? [];
      final List<String> leftItems = pairs.map((p) => p['left'].toString()).toList();
      final List<String> rightItems = pairs.map((p) => p['right'].toString()).toList()..shuffle();

      String? selectedLeft;
      String? selectedRight;
      Map<String, String> matched = {};
      int wrongCount = 0;

      final leftKeys = List.generate(leftItems.length, (_) => GlobalKey());
      final rightKeys = List.generate(rightItems.length, (_) => GlobalKey());
      List<List<Offset>> linePairs = [];

      Widget buildStars() {
        int remaining = (3 - wrongCount).clamp(0, 3);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Icon(
              Icons.star,
              color: i < remaining ? Colors.amber : Colors.grey.shade400,
              size: 24,
            ),
          ),
        );
      }

      return StatefulBuilder(builder: (context, setStateSB) {
        void connectAndDraw() {
          final leftIndex = leftItems.indexOf(selectedLeft!);
          final rightIndex = rightItems.indexOf(selectedRight!);

          final box = context.findRenderObject() as RenderBox?;
          final leftBox = leftKeys[leftIndex].currentContext?.findRenderObject() as RenderBox?;
          final rightBox = rightKeys[rightIndex].currentContext?.findRenderObject() as RenderBox?;

          if (box != null && leftBox != null && rightBox != null) {
            final leftPos = box.globalToLocal(leftBox.localToGlobal(Offset.zero));
            final rightPos = box.globalToLocal(rightBox.localToGlobal(Offset.zero));

            final start = Offset(leftPos.dx + leftBox.size.width, leftPos.dy + leftBox.size.height / 2);
            final end = Offset(rightPos.dx, rightPos.dy + rightBox.size.height / 2);

            linePairs.add([start, end]);
          }
        }

        void checkMatch() {
          if (selectedLeft != null && selectedRight != null) {
            final isCorrect = pairs.any((p) => p['left'] == selectedLeft && p['right'] == selectedRight);

            if (isCorrect) {
              matched[selectedLeft!] = selectedRight!;
              HapticFeedback.lightImpact();
              connectAndDraw();

              if (matched.length == pairs.length) {
                _correctCount++;
                setState(() => _isAnswered = true);
              }
            } else {
              wrongCount++;
              HapticFeedback.heavyImpact();
            }

            selectedLeft = null;
            selectedRight = null;
            setStateSB(() {});

            if (wrongCount >= 3) {
              setState(() => _isAnswered = true);
              Future.delayed(const Duration(milliseconds: 600), _nextQuestion);
            }

            if (matched.length == pairs.length) {
              setState(() => _isAnswered = true);
            }
          }
        }

        return Stack(
          children: [
            CustomPaint(
              painter: _CurveLinePainter(linePairs),
              size: Size.infinite,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ghép các cặp đúng:",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                buildStars(),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Column(
                          children: List.generate(leftItems.length, (i) {
                            final left = leftItems[i];
                            final isMatched = matched.containsKey(left);
                            final isSelected = selectedLeft == left;
                            return GestureDetector(
                              onTap: () {
                                if (!_isAnswered && !isMatched) {
                                  selectedLeft = left;
                                  checkMatch();
                                  setStateSB(() {});
                                }
                              },
                              child: Card(
                                key: leftKeys[i],
                                color: isMatched
                                    ? Colors.green.shade100
                                    : (isSelected ? Colors.purple.shade100 : Colors.white),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(left, style: GoogleFonts.poppins(fontSize: 16)),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: List.generate(rightItems.length, (i) {
                            final right = rightItems[i];
                            final isMatched = matched.containsValue(right);
                            final isSelected = selectedRight == right;
                            return GestureDetector(
                              onTap: () {
                                if (!_isAnswered && !isMatched) {
                                  selectedRight = right;
                                  checkMatch();
                                  setStateSB(() {});
                                }
                              },
                              child: Card(
                                key: rightKeys[i],
                                color: isMatched
                                    ? Colors.green.shade100
                                    : (isSelected ? Colors.orange.shade100 : Colors.white),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(right, style: GoogleFonts.poppins(fontSize: 16)),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isAnswered)
                  Center(
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      ),
                      child: Text("Next", style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ],
        );
      });
    }

    return const Center(child: Text("Unsupported question type."));
  }
}

// Vẽ đường cong nối cặp
class _CurveLinePainter extends CustomPainter {
  final List<List<Offset>> linePairs;
  _CurveLinePainter(this.linePairs);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.shade300
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var pair in linePairs) {
      if (pair.length == 2) {
        final start = pair[0];
        final end = pair[1];
        final path = Path();
        path.moveTo(start.dx, start.dy);
        final midX = (start.dx + end.dx) / 2;
        path.cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CurveLinePainter oldDelegate) => oldDelegate.linePairs != linePairs;
}

// Confetti result dialog (self-contained controller)
class _ConfettiResultDialog extends StatefulWidget {
  final int score;
  const _ConfettiResultDialog({Key? key, required this.score}) : super(key: key);

  @override
  State<_ConfettiResultDialog> createState() => _ConfettiResultDialogState();
}

class _ConfettiResultDialogState extends State<_ConfettiResultDialog> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF7B42F6), Color(0xFFB01EFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amberAccent),
                const SizedBox(height: 10),
                Text('Quiz Completed!',
                    style: GoogleFonts.poppins(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Your Score: ${widget.score}%',
                    style: GoogleFonts.poppins(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // chỉ đóng dialog
                  },
                  child: Text('Back to Lessons',
                      style: GoogleFonts.poppins(color: Colors.purple, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 40,
            gravity: 0.3,
          ),
        ],
      ),
    );
  }
}