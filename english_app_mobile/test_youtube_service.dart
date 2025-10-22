import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  
  try {
    // Test với PSY - GANGNAM STYLE
    const videoUrl = 'https://www.youtube.com/watch?v=9bZkp7q19f0';
    print('Testing YouTube service with: $videoUrl');
    
    // 1. Test lấy video info
    print('\n1. Getting video info...');
    var videoId = VideoId(videoUrl);
    var video = await yt.videos.get(videoId);
    print('Title: ${video.title}');
    print('Duration: ${video.duration}');
    print('Thumbnail: ${video.thumbnails.highResUrl}');
    
    // 2. Test lấy stream URL
    print('\n2. Getting stream URL...');
    var manifest = await yt.videos.streamsClient.getManifest(videoId);
    var videoStream = manifest.muxed
        .where((stream) => stream.container.name == 'mp4')
        .withHighestBitrate();
    
    if (videoStream != null) {
      print('Stream URL found: ${videoStream.url}');
      print('Quality: ${videoStream.videoQuality}');
      print('Container: ${videoStream.container}');
    } else {
      print('No suitable stream found');
    }
    
    // 3. Test lấy subtitles
    print('\n3. Getting subtitles...');
    var captionManifest = await yt.videos.closedCaptions.getManifest(videoId);
    var trackInfo = captionManifest.getByLanguage('en');
    
    if (trackInfo.isNotEmpty) {
      print('Found ${trackInfo.length} English subtitle tracks');
      var track = await yt.videos.closedCaptions.get(trackInfo.first);
      print('First track has ${track.captions.length} captions');
      
      // Show first few captions
      for (int i = 0; i < 3 && i < track.captions.length; i++) {
        var caption = track.captions[i];
        print('Caption ${i + 1}: ${caption.offset} - ${caption.text}');
      }
    } else {
      print('No English subtitles found');
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
