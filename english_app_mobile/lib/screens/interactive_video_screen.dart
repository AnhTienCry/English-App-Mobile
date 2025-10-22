import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import '../services/youtube_service.dart';
import '../services/tts_service.dart';

class InteractiveVideoScreen extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final String videoUrl;

  // Added optional params so home_screen can pass topicId and userId
  final String? topicId;
  final String? userId;

  const InteractiveVideoScreen({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.videoUrl,

    // allow callers to provide topicId/userId (optional)
    this.topicId,
    this.userId,
  });

  @override
  State<InteractiveVideoScreen> createState() => _InteractiveVideoScreenState();
}

class _InteractiveVideoScreenState extends State<InteractiveVideoScreen>
    with TickerProviderStateMixin {
  // Video data
  Map<String, dynamic>? videoData;
  List<dynamic> subtitles = [];
  List<dynamic> wordDefinitions = [];

  // YouTube service
  YoutubeService? _youtubeService;
  String? _streamUrl;

  // UI state
  bool isLoading = true;
  String? error;
  int selectedTabIndex = 0; // 0: Subtitles, 1: Usage, 2: Vocabulary

  // Video player state
  VideoPlayerController? _videoController;
  bool isPlaying = false;
  double currentTime = 0.0;
  double duration = 0.0;

  // Interactive features
  String? selectedWord;
  Map<String, dynamic>? selectedWordDefinition;
  bool showWordDefinition = false;

  // Animation controllers
  late AnimationController _wordDefinitionAnimationController;
  late Animation<Offset> _wordDefinitionAnimation;

  @override
  void initState() {
    super.initState();
    _wordDefinitionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _wordDefinitionAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _wordDefinitionAnimationController,
      curve: Curves.easeOut,
    ));

    // Initialize TTS service
    TTSService().initialize();

    _initializeVideoPlayer();
    _loadVideoData();
  }

  @override
  void dispose() {
    _wordDefinitionAnimationController.dispose();
    _videoController?.dispose();
    _youtubeService?.close();
    TTSService().dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Initialize YouTube service
      _youtubeService = YoutubeService();

      // Get stream URL from YouTube
      _streamUrl = await _youtubeService!.getStreamUrl(widget.videoUrl);

      if (_streamUrl != null) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(_streamUrl!),
        );

        await _videoController!.initialize();

        // Add listener for video position updates
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              currentTime = _videoController!.value.position.inSeconds.toDouble();
              duration = _videoController!.value.duration.inSeconds.toDouble();
              isPlaying = _videoController!.value.isPlaying;
            });
          }
        });
      } else {
        // YouTube stream extraction failed - show message
        print('❌ YouTube stream extraction failed for: ${widget.videoUrl}');
        print('📺 Using fallback video for demo purposes');

        // Fallback to sample video if YouTube stream fails
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
        );

        await _videoController!.initialize();

        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              currentTime = _videoController!.value.position.inSeconds.toDouble();
              duration = _videoController!.value.duration.inSeconds.toDouble();
              isPlaying = _videoController!.value.isPlaying;
            });
          }
        });
      }

    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  Future<void> _loadVideoData() async {
    try {
      final response = await dio.get('${ApiConfig.videosEndpoint}/${widget.videoId}');
      setState(() {
        videoData = response.data;
        wordDefinitions = response.data['wordDefinitions'] ?? [];
      });

      // Try to get subtitles from YouTube first
      if (_youtubeService != null) {
        try {
          final youtubeSubtitles = await _youtubeService!.getSubtitles(widget.videoUrl);
          if (youtubeSubtitles != null && youtubeSubtitles.isNotEmpty) {
            setState(() {
              subtitles = youtubeSubtitles;
            });
          } else {
            // Fallback to database subtitles
            setState(() {
              subtitles = response.data['subtitles'] ?? [];
            });
          }
        } catch (e) {
          print('Error getting YouTube subtitles: $e');
          // Fallback to database subtitles
          setState(() {
            subtitles = response.data['subtitles'] ?? [];
          });
        }
      } else {
        setState(() {
          subtitles = response.data['subtitles'] ?? [];
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load video data';
        isLoading = false;
      });
    }
  }

  Future<void> _getWordDefinition(String word) async {
    try {
      final response = await dio.get('${ApiConfig.videosEndpoint}/words/$word');
      setState(() {
        selectedWord = word;
        selectedWordDefinition = response.data['wordDefinition'];
        showWordDefinition = true;
      });
      _wordDefinitionAnimationController.forward();
    } catch (e) {
      // Word not found, show basic info
      setState(() {
        selectedWord = word;
        selectedWordDefinition = {
          'word': word,
          'pronunciation': {'us': '/$word/', 'uk': '/$word/'},
          'definitions': [
            {
              'partOfSpeech': 'word',
              'meaning': 'Từ này chưa có định nghĩa',
              'example': ''
            }
          ],
          'cefrLevel': 'Unknown'
        };
        showWordDefinition = true;
      });
      _wordDefinitionAnimationController.forward();
    }
  }

  void _hideWordDefinition() {
    _wordDefinitionAnimationController.reverse().then((_) {
      setState(() {
        showWordDefinition = false;
        selectedWord = null;
        selectedWordDefinition = null;
      });
    });
  }

  /// Phát âm từ với giọng US
  void _speakUS() {
    if (selectedWordDefinition != null) {
      final word = selectedWordDefinition!['word'] ?? '';
      TTSService().speakUS(word);
    }
  }

  /// Phát âm từ với giọng UK
  void _speakUK() {
    if (selectedWordDefinition != null) {
      final word = selectedWordDefinition!['word'] ?? '';
      TTSService().speakUK(word);
    }
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Real Video Player
          if (_videoController != null && _videoController!.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            // Loading placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade300, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      widget.videoTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Video controls overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_videoController != null) {
                        if (isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      }
                    },
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Slider(
                          value: currentTime.toDouble(),
                          max: duration > 0 ? duration : 1.0,
                          onChanged: (value) {
                            if (_videoController != null) {
                              _videoController!.seekTo(Duration(seconds: value.toInt()));
                            }
                          },
                          activeColor: Colors.purple,
                          inactiveColor: Colors.white.withOpacity(0.3),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTime(currentTime),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              _formatTime(duration),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Fullscreen functionality
                    },
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _buildTab('Phụ đề', 0),
          _buildTab('Cách dùng', 1),
          _buildTab('Từ vựng', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.purple : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.purple : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitlesContent() {
    if (subtitles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subtitles_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No subtitles available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Subtitles will appear here when available',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subtitles.length,
      itemBuilder: (context, index) {
        final subtitle = subtitles[index];
        return _buildSubtitleSegment(subtitle);
      },
    );
  }

  Widget _buildSubtitleSegment(Map<String, dynamic> subtitle) {
    final startTime = (subtitle['startTime'] ?? 0.0).toDouble();
    final endTime = (subtitle['endTime'] ?? 0.0).toDouble();
    final text = subtitle['text'] ?? '';
    final translation = subtitle['translation'] ?? '';
    final isActive = currentTime.toDouble() >= startTime && currentTime.toDouble() <= endTime;

    return GestureDetector(
      onTap: () {
        // Seek to subtitle time
        if (_videoController != null) {
          _videoController!.seekTo(Duration(seconds: startTime.toInt()));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Colors.purple.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: Colors.purple, width: 2) : Border.all(color: Colors.grey.shade200),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.purple.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.purple : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // English text with interactive words
            _buildInteractiveText(text),

            if (translation.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Vietnamese translation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        translation,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveText(String text) {
    // Split text into words and make them interactive
    final words = text.split(' ');

    return Wrap(
      children: words.map((word) {
        // Clean word (remove punctuation)
        final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
        final isClickable = cleanWord.isNotEmpty && cleanWord.length > 2;

        return GestureDetector(
          onTap: isClickable ? () => _getWordDefinition(cleanWord) : null,
          child: Container(
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isClickable ? Colors.purple.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isClickable ? Border.all(color: Colors.purple.withOpacity(0.3)) : null,
            ),
            child: Text(
              word,
              style: TextStyle(
                fontSize: 16,
                color: isClickable ? Colors.purple : Colors.black,
                fontWeight: isClickable ? FontWeight.w500 : FontWeight.normal,
                decoration: isClickable ? TextDecoration.underline : null,
                decorationColor: Colors.purple,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWordDefinitionPopup() {
    if (!showWordDefinition || selectedWordDefinition == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _wordDefinitionAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedWordDefinition!['word'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _hideWordDefinition,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pronunciation
                  Row(
                    children: [
                      Text(
                        'US${selectedWordDefinition!['pronunciation']?['us'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _speakUS(),
                        child: Icon(
                          Icons.volume_up,
                          size: 16,
                          color: Colors.blue.shade600
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'UK${selectedWordDefinition!['pronunciation']?['uk'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _speakUK(),
                        child: Icon(
                          Icons.volume_up,
                          size: 16,
                          color: Colors.green.shade600
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Definitions
                  ...((selectedWordDefinition!['definitions'] as List).map((def) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${def['partOfSpeech']}. ${def['meaning']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (def['example'] != null && def['example'].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Ví dụ: ${def['example']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList()),

                  // CEFR Level
                  if (selectedWordDefinition!['cefrLevel'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedWordDefinition!['cefrLevel'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Example sentences
                  GestureDetector(
                    onTap: () {
                      // Show example sentences
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text('Câu ví dụ'),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
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

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVideoData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player
                _buildVideoPlayer(),

                // Tab Bar
                _buildTabBar(),

                // Content based on selected tab
                if (selectedTabIndex == 0) _buildSubtitlesContent(),
                if (selectedTabIndex == 1) const Center(child: Text('Usage content coming soon')),
                if (selectedTabIndex == 2) const Center(child: Text('Vocabulary content coming soon')),
              ],
            ),
          ),

          // Word Definition Popup
          if (showWordDefinition)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildWordDefinitionPopup(),
            ),
        ],
      ),
    );
  }
}
