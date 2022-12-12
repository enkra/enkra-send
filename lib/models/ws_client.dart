import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  final WebSocketChannel _channel;

  Function(String)? _listen;

  WsClient(this._channel) {
    _listenChannel(_channel);
  }

  _listenChannel(channel) async {
    await for (var msg in channel.stream) {
      _listen?.call(msg);
    }
  }

  listen(Function(String) listen) {
    _listen = listen;
  }

  get sink => _channel.sink;
}
