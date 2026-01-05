import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;

  factory SocketService() => _instance;
  SocketService._internal();

  void connect(String token) {
    socket = IO.io(
      "http://52.9.12.189:4300/",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
}
