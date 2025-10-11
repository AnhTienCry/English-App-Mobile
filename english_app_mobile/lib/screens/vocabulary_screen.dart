import 'package:flutter/material.dart';
import '../api/api_client.dart';

class VocabularyScreen extends StatefulWidget {
  final String? lessonId;

  const VocabularyScreen({
    super.key,
    this.lessonId,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with TickerProviderStateMixin {
  List<dynamic> vocabulary = [];
  bool loading = true;
  String? error;
  int currentIndex = 0;
  bool showAnswer = false;
  bool autoPlay = false;
  
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchVocabulary();
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> fetchVocabulary() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      String endpoint = '/vocabulary';
      if (widget.lessonId != null) {
        endpoint = '/lessons/${widget.lessonId}/vocabulary';
      }
      
      final res = await dio.get(endpoint);
      setState(() {
        vocabulary = res.data['vocabulary'] ?? [];
        loading = false;
      });
      
      if (vocabulary.isNotEmpty) {
        _slideController.forward();
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load vocabulary';
        loading = false;
      });
    }
  }

  void _flipCard() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
      setState(() => showAnswer = false);
    } else {
      _flipController.forward();
      setState(() => showAnswer = true);
    }
  }

  void _nextCard() {
    if (currentIndex < vocabulary.length - 1) {
      setState(() {
        currentIndex++;
        showAnswer = false;
      });
      _flipController.reset();
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _previousCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        showAnswer = false;
      });
      _flipController.reset();
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _toggleAutoPlay() {
    setState(() => autoPlay = !autoPlay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonId != null ? 'Vocabulary' : 'All Vocabulary'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(autoPlay ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoPlay,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchVocabulary,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchVocabulary,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : vocabulary.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.style_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No vocabulary available',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildProgressIndicator(),
                        Expanded(
                          child: _buildFlashcard(),
                        ),
                        _buildControls(),
                      ],
                    ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${currentIndex + 1} of ${vocabulary.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((currentIndex + 1) / vocabulary.length * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (currentIndex + 1) / vocabulary.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard() {
    if (vocabulary.isEmpty) return const SizedBox.shrink();
    
    final word = vocabulary[currentIndex];
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final isShowingFront = _flipAnimation.value < 0.5;
              
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_flipAnimation.value * 3.14159),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isShowingFront 
                          ? [Colors.blue[400]!, Colors.blue[600]!]
                          : [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: InkWell(
                      onTap: _flipCard,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Word/Audio section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isShowingFront ? word['word'] ?? '' : word['meaning'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (word['audioUrl'] != null && isShowingFront)
                                  IconButton(
                                    onPressed: () {
                                      // Play audio
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Playing audio...'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.volume_up,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Pronunciation
                            if (word['pronunciation'] != null && isShowingFront)
                              Text(
                                word['pronunciation'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            
                            const SizedBox(height: 20),
                            
                            // Example sentence
                            if (word['example'] != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  word['example'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            
                            const Spacer(),
                            
                            // Flip instruction
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isShowingFront ? 'Tap to reveal meaning' : 'Tap to see word',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: currentIndex > 0 ? _previousCard : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Flip button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _flipCard,
              icon: Icon(showAnswer ? Icons.undo : Icons.flip),
              label: Text(showAnswer ? 'Show Word' : 'Show Meaning'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: currentIndex < vocabulary.length - 1 ? _nextCard : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VocabularyListScreen extends StatefulWidget {
  final String? lessonId;

  const VocabularyListScreen({
    super.key,
    this.lessonId,
  });

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  List<dynamic> vocabulary = [];
  bool loading = true;
  String? error;
  String searchQuery = '';
  List<dynamic> filteredVocabulary = [];

  @override
  void initState() {
    super.initState();
    fetchVocabulary();
  }

  Future<void> fetchVocabulary() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      String endpoint = '/vocabulary';
      if (widget.lessonId != null) {
        endpoint = '/lessons/${widget.lessonId}/vocabulary';
      }
      
      final res = await dio.get(endpoint);
      setState(() {
        vocabulary = res.data['vocabulary'] ?? [];
        filteredVocabulary = vocabulary;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load vocabulary';
        loading = false;
      });
    }
  }

  void _filterVocabulary(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredVocabulary = vocabulary;
      } else {
        filteredVocabulary = vocabulary.where((word) {
          final wordText = word['word']?.toLowerCase() ?? '';
          final meaningText = word['meaning']?.toLowerCase() ?? '';
          return wordText.contains(query.toLowerCase()) ||
                 meaningText.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary List'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterVocabulary,
              decoration: InputDecoration(
                hintText: 'Search vocabulary...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // Vocabulary list
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: fetchVocabulary,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredVocabulary.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isNotEmpty 
                                    ? 'No vocabulary found for "$searchQuery"'
                                    : 'No vocabulary available',
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredVocabulary.length,
                            itemBuilder: (context, index) {
                              final word = filteredVocabulary[index];
                              return VocabularyListItem(
                                word: word,
                                onTap: () {
                                  // Navigate to flashcard view for this word
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VocabularyScreen(lessonId: widget.lessonId),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class VocabularyListItem extends StatelessWidget {
  final Map<String, dynamic> word;
  final VoidCallback onTap;

  const VocabularyListItem({
    super.key,
    required this.word,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Word icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.style_outlined,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Word details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word['word'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (word['pronunciation'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        word['pronunciation'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      word['meaning'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Audio button
              if (word['audioUrl'] != null)
                IconButton(
                  onPressed: () {
                    // Play audio
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playing audio...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.volume_up, color: Colors.blue),
                ),
              
              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
