// ...existing code...
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/api_config.dart';
import '../api/api_client.dart'; // Import global dio

class QuizScreen extends StatefulWidget {
  final String topicId;
  final String lessonId;

  const QuizScreen({super.key, this.topicId = '', this.lessonId = ''});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final TextEditingController _fillController = TextEditingController();
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _isAnswered = false;
  String? _selectedAnswer;
  bool _isLoading = true;
  bool _quizFinished = false;
  final Stopwatch _timer = Stopwatch();
  final Stopwatch _questionTimer = Stopwatch();

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _answers = []; // Thêm để lưu answers

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_animationController);
    // controller used for the full-screen celebration only
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    fetchQuizzes();
  }

  Future<void> fetchQuizzes() async {
    try {
      final res = await dio.get(
        "${ApiConfig.quizByTopicEndpoint}/${widget.topicId}",
      );
      if (!mounted) return;
      setState(() {
        _questions = res.data is List ? res.data : [];
        _isLoading = false;
      });
      if (_questions.isNotEmpty) {
        _timer.start();
        _startQuestionTimer();
      }
    } catch (e) {
      debugPrint("❌ Error fetching quiz: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load quiz")));
    }
  }

  void _startQuestionTimer() {
    _questionTimer.reset();
    _questionTimer.start();
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
      await dio.post(
        '/api/quizzes/submit-question',
        data: {
          'topicId': topicId,
          'quizId': quizId,
          'questionId': questionId,
          'userAnswer': userAnswer,
          'score': score,
          'timeSpent': timeSpent,
        },
      );
    } catch (e) {
      debugPrint('❌ Error submitting question attempt: $e');
    }
  }

  // Helper: kiểm tra answer (text) cho câu hỏi q.
  // Hỗ trợ trường hợp q['correctAnswer'] là int (index) hoặc string (option text).
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

    // Submit attempt to backend
    final topicId = widget.topicId;
    final quizId = q['_id']?.toString() ?? '';
    final questionId = q['_id']?.toString() ?? '';
    final userAnswer = answer;
    final score = isCorrect ? 1 : 0;
    final timeSpent = _questionTimer.elapsed.inSeconds;

    // Thêm vào _answers
    _answers.add({
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'score': score,
      'timeSpent': timeSpent,
    });

    await _submitQuestionAttempt(
      topicId: topicId,
      quizId: quizId,
      questionId: questionId,
      userAnswer: userAnswer,
      score: score,
      timeSpent: timeSpent,
    );

    _questionTimer.stop();

    // small delay for UX
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
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
      // nothing to submit
      if (!mounted) return;
      Navigator.pop(context, false);
      return;
    }

    final score = ((_correctCount / _questions.length) * 100).round();
    final finalScore = score > 0 ? score : 1; // ensure >0 to mark attempted
    final timeSpent = _timer.elapsed.inSeconds;

    if (!mounted) return;
    setState(() => _quizFinished = true);

    // play confetti on full-screen celebration
    try {
      _confettiController.play();
    } catch (e) {
      debugPrint('Confetti play error: $e');
    }

    try {
      final response = await dio.post(ApiConfig.submitQuizEndpoint, data: {
        'topicId': widget.topicId, // Chỉ cần topicId, backend tính từ attempts
        // Loại bỏ lessonId, score, timeSpent, answers vì backend không dùng
      });
      print('Quiz submitted successfully: ${response.data}');
      // Return true để tower biết mark completed
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error submitting quiz: $e');
      // Có thể show error dialog thay vì pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit quiz. Try again.')),
      );
    }
  }

  Future<void> _showResultDialog(int score) async {
    // Use a local ConfettiController for the dialog so its lifecycle is independent
    final dialogController = ConfettiController(duration: const Duration(seconds: 3));
    dialogController.play();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 80,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Quiz Completed!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Score: $score%',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Correct: $_correctCount / ${_questions.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    'Time: ${_timer.elapsed.inSeconds}s',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext); // close dialog
                      if (mounted) {
                        Navigator.pop(context, true); // return true so caller refreshes
                      }
                    },
                    child: Text(
                      'Back to Lessons',
                      style: GoogleFonts.poppins(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Confetti inside dialog uses the local dialogController
            ConfettiWidget(
              confettiController: dialogController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              gravity: 0.3,
            ),
          ],
        ),
      ),
    );

    // dispose local dialog controller after dialog dismissed
    try {
      dialogController.dispose();
    } catch (e) {
      debugPrint('dialog confetti dispose error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    try {
      _confettiController.dispose();
    } catch (e) {
      debugPrint('Confetti dispose error: $e');
    }
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
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: Colors.purple,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No questions available for this topic.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Back'),
              ),
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
                const Icon(
                  Icons.stars_rounded,
                  color: Colors.purple,
                  size: 100,
                ),
                const SizedBox(height: 20),
                Text(
                  "Well done!",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "You've completed this quiz!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
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
                    _isAnswered &&
                        _selectedAnswer != q['correctAnswer'] &&
                        q['type'] == 'multiple_choice'
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                label: Text(
                  _currentIndex < _questions.length - 1
                      ? "Next Question"
                      : "Finish Quiz",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: _nextQuestion,
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
            Text(
              "Your answer:",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fillController,
              enabled: !_isAnswered,
              decoration: InputDecoration(
                hintText: "Type your answer here...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () {
                    final answer = _fillController.text.trim();
                    if (answer.isNotEmpty) _checkAnswer(answer);
                  },
                  child: const Text(
                    "Submit Answer",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            if (_isAnswered) ...[
              const SizedBox(height: 20),
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
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
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

      return StatefulBuilder(
        builder: (context, setStateSB) {
          void checkMatch() {
            if (selectedLeft != null && selectedRight != null) {
              final isCorrect = pairs.any((p) => p['left'] == selectedLeft && p['right'] == selectedRight);

              if (isCorrect) {
                matched[selectedLeft!] = selectedRight!;
                HapticFeedback.lightImpact();

                if (matched.length == pairs.length) {
                  _correctCount++;
                  setState(() => _isAnswered = true);
                }

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
              } else {
                wrongCount++;
                HapticFeedback.heavyImpact();
              }

              selectedLeft = null;
              selectedRight = null;
              setStateSB(() {});

              if (wrongCount >= 3) {
                setState(() {
                  _isAnswered = true;
                });
                Future.delayed(const Duration(milliseconds: 600), _nextQuestion);
              }

              if (matched.length == pairs.length) {
                setState(() => _isAnswered = true);
              }
            }
          }

          Widget buildStars() {
            int remaining = (3 - wrongCount).clamp(0, 3);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                    (i) => Icon(
                  Icons.star,
                  color: i < remaining ? Colors.amber : Colors.grey.shade400,
                  size: 28,
                ),
              ),
            );
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                              return GestureDetector(
                                onTap: () {
                                  if (!isMatched) {
                                    selectedLeft = left;
                                    checkMatch();
                                    setStateSB(() {});
                                  }
                                },
                                child: Card(
                                  key: leftKeys[i],
                                  color: isMatched ? Colors.green.shade100 : (selectedLeft == left ? Colors.purple.shade100 : Colors.white),
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
                              return GestureDetector(
                                onTap: () {
                                  if (!isMatched) {
                                    selectedRight = right;
                                    checkMatch();
                                    setStateSB(() {});
                                  }
                                },
                                child: Card(
                                  key: rightKeys[i],
                                  color: isMatched ? Colors.green.shade100 : (selectedRight == right ? Colors.orange.shade100 : Colors.white),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          "Next",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      );
    }

    return const Center(child: Text("Unsupported question type."));
  }
}

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
// ...existing code...