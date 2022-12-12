import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nanoid/nanoid.dart';
import 'package:cryptography/cryptography.dart';

import 'app_state.dart';
import 'ws_client.dart';

const String WS_API_URL = String.fromEnvironment('WS_API_URL');
const String ENKRA_SEND_APP_URL = String.fromEnvironment('SEND_APP_URL');

class WaitToPairState extends AppState {
  final WsClient _channel;

  final String _sessionKey;

  final String _cipherKey;

  Function()? _onPaired;

  WaitToPairState._internal(
    WebSocketChannel channel,
    this._sessionKey,
    this._cipherKey,
  ) : _channel = WsClient(channel) {
    _listenChannel(_channel);
  }

  static create() async {
    final sessionKey = nanoid();
    final wsUrl = Uri.parse('${WS_API_URL}/$sessionKey');
    final channel = WebSocketChannel.connect(wsUrl);

    final algorithm = AesGcm.with128bits();
    final secretKey = await algorithm.newSecretKey();
    final cipherKey = base64Url.encode(await secretKey.extractBytes());

    return WaitToPairState._internal(channel, sessionKey, cipherKey);
  }

  factory WaitToPairState.connect(List<String> keys) {
    final sessionKey = keys[0];
    final cipherKey = keys[1];

    final wsUrl = Uri.parse('${WS_API_URL}/$sessionKey');
    final channel = WebSocketChannel.connect(wsUrl);

    return WaitToPairState._internal(channel, sessionKey, cipherKey);
  }

  String sesssionKey() {
    return _sessionKey;
  }

  String pairingUrl() {
    return '${ENKRA_SEND_APP_URL}/#/$_sessionKey/$_cipherKey';
  }

  _listenChannel(channel) async {
    channel.listen((msg) {
      final message = jsonDecode(msg);

      if (message["event"] == "paired") {
        _onPaired?.call();
      }
    });
  }

  setOnPaired(Function() onPaired) {
    _onPaired = onPaired;
  }

  get wsChannel => _channel;

  get cipherKey => _cipherKey;
}
