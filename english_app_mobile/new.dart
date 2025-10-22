// lib/screens/interactive_video_screen.dart

import 'package:flutter/material.dart';

// Giả sử bạn sẽ dùng một thư viện video nào đó, ví dụ:
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class InteractiveVideoScreen extends StatefulWidget {
  // Các thuộc tính đã có
  final String videoId;
  final String videoTitle;
  final String videoUrl;

  // THÊM 2 THUỘC TÍNH NÀY
  final String topicId;
  final String userId;

  // CẬP NHẬT CONSTRUCTOR ĐỂ NHẬN THÊM THAM SỐ
  const InteractiveVideoScreen({
    super.key,
    required this.videoId,
    required this.videoTitle,
    required this.videoUrl,
    required this.topicId, // Thêm dòng này
    required this.userId, // Thêm dòng này
  });

  @override
  State<InteractiveVideoScreen> createState() => _InteractiveVideoScreenState();
}

class _InteractiveVideoScreenState extends State<InteractiveVideoScreen> {
  // Toàn bộ logic hiện tại của bạn ở đây.
  // Bây giờ bạn có thể truy cập các giá trị mới thông qua `widget.topicId` và `widget.userId`

  @override
  Widget build(BuildContext context) {
    // Đây chỉ là giao diện mẫu, bạn hãy thay thế bằng giao diện thật của mình
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoTitle), // Truy cập tiêu đề video
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Video ID: ${widget.videoId}'),
            const SizedBox(height: 8),
            Text('Video URL: ${widget.videoUrl}'),
            const SizedBox(height: 8),
            // Truy cập các tham số mới
            Text('Topic ID: ${widget.topicId}'),
            const SizedBox(height: 8),
            Text('User ID: ${widget.userId}'),
          ],
        ),
      ),
    );
  }
}
