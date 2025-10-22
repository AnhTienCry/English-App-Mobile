import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../config/api_config.dart';

class VocabularyScreen extends StatefulWidget {
  final String? topicId;

  const VocabularyScreen({super.key, this.topicId});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with SingleTickerProviderStateMixin {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final FlutterTts _flutterTts = FlutterTts();
  late ConfettiController _confettiController;

  bool isLoading = true;
  List<dynamic> vocabList = [];
  int currentIndex = 0;
  bool showBack = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    if (widget.topicId != null) fetchVocab();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
  }

  Future<void> fetchVocab() async {
    try {
      setState(() => isLoading = true);
      final res = await _dio.get(
        "${ApiConfig.vocabByTopicEndpoint}/${widget.topicId}",
      );
      setState(() {
        vocabList = res.data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching vocab: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  void _nextCard() {
    if (currentIndex < vocabList.length - 1) {
      setState(() {
        showBack = false;
        currentIndex++;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _prevCard() {
    if (currentIndex > 0) {
      setState(() {
        showBack = false;
        currentIndex--;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This is the first word."),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showCompletionDialog() {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
          ),
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "🎉 Congratulations!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "You’ve completed all flashcards for this topic.",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _confettiController.stop();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Back to Lessons"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }

  // 📋 Danh sách toàn bộ từ
  void _showVocabList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: 400,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 5,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "📘 Vocabulary List",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: vocabList.length,
                itemBuilder: (context, index) {
                  final v = vocabList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        v['word'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.indigo),
                      ),
                    ),
                    title: Text(
                      v['word'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      v['meaning'] ?? "",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.indigo),
                      onPressed: () => _speak(v['word']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Flashcards"),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            tooltip: "View all words",
            onPressed: _showVocabList,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : vocabList.isEmpty
          ? const Center(child: Text("No vocabulary found."))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // ✅ Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(
                    value: (currentIndex + 1) / vocabList.length,
                    color: Colors.indigo,
                    backgroundColor: Colors.indigo.shade100,
                    minHeight: 6,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Flashcard
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => setState(() => showBack = !showBack),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) {
                          final rotate = Tween(
                            begin: pi,
                            end: 0.0,
                          ).animate(anim);
                          return AnimatedBuilder(
                            animation: rotate,
                            child: child,
                            builder: (context, child) {
                              final isUnder =
                                  (ValueKey(showBack) != child!.key);
                              final value = isUnder
                                  ? min(rotate.value, pi / 2)
                                  : rotate.value;
                              return Transform(
                                transform: Matrix4.rotationY(value),
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                          );
                        },
                        child: showBack ? _buildBackCard() : _buildFrontCard(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Next button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ElevatedButton.icon(
                    onPressed: _nextCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // 🌟 Mặt trước — chỉ hiển thị từ và nút loa
  Widget _buildFrontCard() {
    final v = vocabList[currentIndex];
    return Card(
      key: const ValueKey(true),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade300, Colors.indigo.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                v['word'],
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              IconButton(
                icon: const Icon(
                  Icons.volume_up,
                  color: Colors.white,
                  size: 38,
                ),
                onPressed: () => _speak(v['word']),
              ),
              const SizedBox(height: 14),
              const Text(
                "Tap to see meaning 👆",
                style: TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Mặt sau — hiển thị nghĩa, ví dụ, nút loa
  Widget _buildBackCard() {
    final v = vocabList[currentIndex];
    return Card(
      key: const ValueKey(false),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  v['meaning'] ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                if (v['example'] != null)
                  Column(
                    children: [
                      Text(
                        '"${v['example']}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => _speak(v['example']),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text(
                  "Tap to flip back 👆",
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
