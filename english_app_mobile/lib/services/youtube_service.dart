import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  final YoutubeExplode _yt;

  YoutubeService() : _yt = YoutubeExplode();

  /// Lấy URL stream trực tiếp từ YouTube URL
  Future<String?> getStreamUrl(String videoUrl) async {
    try {
      var videoId = VideoId(videoUrl);
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      // Tìm stream video có chất lượng tốt nhất
      var videoStream = manifest.muxed
          .where((stream) => stream.container.name == 'mp4')
          .withHighestBitrate();
      
      if (videoStream != null) {
        return videoStream.url.toString();
      }
      
      // Fallback: lấy stream đầu tiên có sẵn
      var firstStream = manifest.muxed.firstOrNull;
      if (firstStream != null) {
        return firstStream.url.toString();
      }
      
      return null;
    } catch (e) {
      print("Error getting stream URL: $e");
      print("YouTube stream extraction failed, will use fallback video");
      return null;
    }
  }

  /// Lấy phụ đề tiếng Anh từ YouTube URL
  Future<List<Map<String, dynamic>>?> getSubtitles(String videoUrl) async {
    try {
      var videoId = VideoId(videoUrl);
      var manifest = await _yt.videos.closedCaptions.getManifest(videoId);

      // Tìm tất cả tracks tiếng Anh (bao gồm cả auto-generated)
      var allTracks = manifest.tracks;
      var englishTracks = allTracks.where((track) => 
        track.language.name.toLowerCase().contains('english')).toList();
      
      if (englishTracks.isEmpty) {
        print("Không tìm thấy phụ đề tiếng Anh.");
        return null;
      }
      
      print("✅ Tìm thấy ${englishTracks.length} English tracks");
      
      // Lấy track đầu tiên (có thể là auto-generated)
      var track = await _yt.videos.closedCaptions.get(englishTracks.first);

      // Chuyển đổi thành format phù hợp với app
      List<Map<String, dynamic>> subtitles = [];
      for (var caption in track.captions) {
        subtitles.add({
          'startTime': caption.offset.inSeconds.toDouble(),
          'endTime': (caption.offset.inSeconds + caption.duration.inSeconds).toDouble(),
          'text': caption.text,
          'translation': '', // Có thể thêm translation sau
        });
      }
      
      print("✅ Lấy được ${subtitles.length} phụ đề từ YouTube");
      return subtitles;
    } catch (e) {
      print("Error getting subtitles: $e");
      return null;
    }
  }

  /// Lấy thông tin video (title, duration, thumbnail)
  Future<Map<String, dynamic>?> getVideoInfo(String videoUrl) async {
    try {
      var videoId = VideoId(videoUrl);
      var video = await _yt.videos.get(videoId);
      
      return {
        'title': video.title,
        'duration': video.duration?.inSeconds ?? 0,
        'thumbnailUrl': video.thumbnails.highResUrl,
        'description': video.description,
      };
    } catch (e) {
      print("Error getting video info: $e");
      return null;
    }
  }

  /// Đóng service
  void close() {
    _yt.close();
  }
}
