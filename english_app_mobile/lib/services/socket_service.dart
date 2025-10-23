import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  // 🔥 NEW: Hàm khởi tạo socket và join theo userId
  void init(String userId) {
    socket = IO.io('https://your-api-domain.com', {
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();

    socket.onConnect((_) {
      socket.emit('join', userId);
    });

    socket.on('tower.completed', (data) {
      print('🎯 Tower event: $data');
      // Bạn có thể thêm notification UI tại đây
    });
  }

  void dispose() {
    socket.disconnect();
  }
}
