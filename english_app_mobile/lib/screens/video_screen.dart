import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import 'interactive_video_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  List<dynamic> videos = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await dio.get(ApiConfig.videosEndpoint);
      setState(() {
        videos = res.data ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load videos';
        loading = false;
      });
    }
  }

  Future<void> markVideoViewed(String videoId, bool isCompleted) async {
    try {
      await dio.patch('${ApiConfig.markVideoViewedEndpoint}/$videoId/mark-viewed', data: {
        'isCompleted': isCompleted,
      });
      fetchVideos(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update video progress')),
        );
      }
    }
  }

  String formatDuration(int? seconds) {
    if (seconds == null) return 'N/A';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  String getVideoThumbnail(String url) {
    // Extract YouTube video ID and get thumbnail
    if (url.contains('youtube.com/watch')) {
      final videoId = url.split('v=')[1].split('&')[0];
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    if (url.contains('youtu.be/')) {
      final videoId = url.split('youtu.be/')[1].split('?')[0];
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Videos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchVideos,
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
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchVideos,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : videos.isEmpty
                  ? const Center(
                      child: Text(
                        'No videos available',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchVideos,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          return VideoCard(
                            video: video,
                            onMarkViewed: markVideoViewed,
                          );
                        },
                      ),
                    ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final Function(String videoId, bool isCompleted) onMarkViewed;

  const VideoCard({
    super.key,
    required this.video,
    required this.onMarkViewed,
  });

  String formatDuration(int? seconds) {
    if (seconds == null) return 'N/A';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  String getVideoThumbnail(String url) {
    if (url.contains('youtube.com/watch')) {
      final videoId = url.split('v=')[1].split('&')[0];
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    if (url.contains('youtu.be/')) {
      final videoId = url.split('youtu.be/')[1].split('?')[0];
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = video['thumbnailUrl'] ?? getVideoThumbnail(video['url']);
    final lesson = video['lesson'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InteractiveVideoScreen(
                videoId: video['_id'] ?? video['id'],
                videoTitle: video['title'] ?? 'Video',
                videoUrl: video['videoUrl'] ?? video['url'] ?? '',
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    Image.network(
                      thumbnailUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.video_library, size: 64, color: Colors.grey),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          formatDuration(video['duration']),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Center(
                  child: Icon(Icons.video_library, size: 64, color: Colors.grey),
                ),
              ),

            // Video info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (video['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      video['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.book, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        lesson?['title'] ?? 'No lesson',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          lesson?['level'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> video;
  final Function(String videoId, bool isCompleted) onMarkViewed;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.onMarkViewed,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool hasMarkedViewed = false;

  String getVideoEmbedUrl(String url) {
    if (url.contains('youtube.com/watch')) {
      final videoId = url.split('v=')[1].split('&')[0];
      return 'https://www.youtube.com/embed/$videoId';
    }
    if (url.contains('youtu.be/')) {
      final videoId = url.split('youtu.be/')[1].split('?')[0];
      return 'https://www.youtube.com/embed/$videoId';
    }
    return url;
  }

  void markAsCompleted() {
    if (!hasMarkedViewed) {
      widget.onMarkViewed(widget.video['id'], true);
      setState(() => hasMarkedViewed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video marked as completed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video['title']),
      ),
      body: Column(
        children: [
          // Video player (placeholder - would use video_player package in production)
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Video Player',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Open in browser or YouTube app',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.video['description'] != null) ...[
                    Text(
                      widget.video['description'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Lesson: ${widget.video['lesson']?['title'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasMarkedViewed ? null : markAsCompleted,
                      icon: Icon(hasMarkedViewed ? Icons.check_circle : Icons.check),
                      label: Text(
                        hasMarkedViewed ? 'Marked as Completed' : 'Mark as Completed',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: hasMarkedViewed ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}






