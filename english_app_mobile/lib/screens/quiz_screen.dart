import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import '../api/api_client.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;

  const QuizScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Map<String, dynamic>? quiz;
  List<dynamic> questions = [];
  int currentQuestionIndex = 0;
  Map<String, String> userAnswers = {};
  bool loading = true;
  String? error;
  bool quizCompleted = false;
  Map<String, dynamic>? results;
  
  // Timer variables
  Timer? timer;
  int remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    fetchQuiz();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchQuiz() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await dio.get('/quiz/${widget.quizId}');
      setState(() {
        quiz = res.data['quiz'];
        questions = quiz?['questions'] ?? [];
        loading = false;
        
        // Start timer if there's a time limit
        if (quiz?['timeLimit'] != null) {
          remainingSeconds = quiz!['timeLimit'];
          startTimer();
        }
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load quiz';
        loading = false;
      });
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          timer.cancel();
          submitQuiz();
        }
      });
    });
  }

  String formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> submitQuiz() async {
    if (quizCompleted) return;

    timer?.cancel();
    setState(() => loading = true);

    try {
      final answers = userAnswers.entries.map((e) => {
        'questionId': e.key,
        'answer': e.value,
      }).toList();

      final timeSpent = quiz?['timeLimit'] != null 
        ? quiz!['timeLimit'] - remainingSeconds 
        : null;

      final res = await dio.post('/quiz/${widget.quizId}/submit', data: {
        'answers': answers,
        'timeSpent': timeSpent,
      });

      setState(() {
        results = res.data;
        quizCompleted = true;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to submit quiz';
        loading = false;
      });
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() => currentQuestionIndex++);
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() => currentQuestionIndex--);
    }
  }

  void selectAnswer(String questionId, String answer) {
    setState(() {
      userAnswers[questionId] = answer;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchQuiz,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (quizCompleted && results != null) {
      return buildResultsScreen();
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: const Center(child: Text('No questions available')),
      );
    }

    return buildQuizScreen();
  }

  Widget buildQuizScreen() {
    final question = questions[currentQuestionIndex];
    final questionId = question['id'];
    final questionText = question['question'];
    final questionType = question['type'];
    final optionsJson = question['options'];
    final explanation = question['explanation'];
    
    List<String> options = [];
    if (optionsJson != null && optionsJson.isNotEmpty) {
      try {
        options = List<String>.from(json.decode(optionsJson));
      } catch (e) {
        options = [];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        actions: [
          if (remainingSeconds > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  formatTime(remainingSeconds),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: remainingSeconds < 60 ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question number and points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${currentQuestionIndex + 1} of ${questions.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${question['points']} pts',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Question text
                  Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Answer options
                  Expanded(
                    child: ListView(
                      children: options.map((option) {
                        final isSelected = userAnswers[questionId] == option;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => selectAnswer(questionId, option),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.white,
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Colors.blue),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: currentQuestionIndex < questions.length - 1
                        ? nextQuestion
                        : userAnswers.length == questions.length
                            ? submitQuiz
                            : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      currentQuestionIndex < questions.length - 1
                          ? 'Next'
                          : 'Submit Quiz',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResultsScreen() {
    final attempt = results!['attempt'];
    final score = attempt['score'];
    final maxScore = attempt['maxScore'];
    final percentage = attempt['percentage'];
    final answerResults = results!['results'] as List;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score card
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: percentage >= 70 
                    ? [Colors.green, Colors.green[700]!]
                    : [Colors.orange, Colors.orange[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    percentage >= 70 ? 'Great Job!' : 'Keep Practicing!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$score / $maxScore',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Question results
            ...answerResults.asMap().entries.map((entry) {
              final index = entry.key;
              final result = entry.value;
              final isCorrect = result['isCorrect'];
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green[50] : Colors.red[50],
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Question ${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green[900] : Colors.red[900],
                            ),
                          ),
                        ),
                        Text(
                          '${result['points']} pts',
                          style: TextStyle(
                            color: isCorrect ? Colors.green[900] : Colors.red[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your answer: ${result['answer']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Back to Lessons',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


