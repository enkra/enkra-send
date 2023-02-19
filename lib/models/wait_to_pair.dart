import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nanoid/nanoid.dart';

import 'app_state.dart';
import 'ws_client.dart';

import '../native/native.dart';

const String WS_API_URL = String.fromEnvironment('WS_API_URL');
const String ENKRA_SEND_APP_URL = String.fromEnvironment('SEND_APP_URL');

class WaitToPairState extends AppState {
  final WsClient _channel;

  final String _sessionKey;

  final SecureChannelCipher _cipher;

  Function(AeadCipher)? _onPaired;

  final bool _isSender;
  AeadCipher? _senderAeadCipher;

  WaitToPairState._internal(
    WebSocketChannel channel,
    this._sessionKey,
    this._cipher,
    this._isSender,
    this._senderAeadCipher,
  ) : _channel = WsClient(channel) {
    if (_isSender) {
      _senderListen(_channel);
    } else {
      _receiverListen(_channel);
    }
  }

  static create() async {
    final sessionKey = nanoid();
    final wsUrl = Uri.parse('$WS_API_URL/$sessionKey');
    final channel = WebSocketChannel.connect(wsUrl);

    final channelCipher = await SecureChannelCipher.newRandom(bridge: api);

    return WaitToPairState._internal(
      channel,
      sessionKey,
      channelCipher,
      false,
      null,
    );
  }

  static connect(List<String> keys) async {
    final sessionKey = keys[0];
    final publicKey = base64Url.decode(keys[1]);

    final channelCipher = await SecureChannelCipher.newRandom(bridge: api);
    final encapKeys = await channelCipher.encapKey(public: publicKey);

    final wsUrl = Uri.parse('$WS_API_URL/$sessionKey');
    final channel = WebSocketChannel.connect(wsUrl);

    _sendPairingMessage(encapKeys.encapsulatedKey, channel);

    return WaitToPairState._internal(
      channel,
      sessionKey,
      channelCipher,
      true,
      encapKeys.sharedSecret,
    );
  }

  String sesssionKey() {
    return _sessionKey;
  }

  Future<String> pairingUrl() async {
    final key = await _cipher.public();
    final publicKey = base64Url.encode(key);

    return '$ENKRA_SEND_APP_URL/#/$_sessionKey/$publicKey';
  }

  _receiverListen(channel) async {
    channel.listen((msg) async {
      final message = jsonDecode(msg);

      if (message["event"] == "pairing") {
        final key = message["encappedKey"];

        if (key == null) {
          return;
        }

        final encappedKey = base64Url.decode(key);

        final cipherKey =
            await _cipher.sharedSecret(encapsulatedKey: encappedKey);

        _channel.sink.add(jsonEncode({
          "event": "paired",
        }));

        _onPaired?.call(cipherKey);
      }
    });
  }

  _senderListen(channel) async {
    channel.listen((msg) async {
      final message = jsonDecode(msg);

      if (message["event"] == "paired") {
        final senderAeadCipher = _senderAeadCipher!;

        _senderAeadCipher = null;

        _onPaired?.call(senderAeadCipher);
      }
    });
  }

  static _sendPairingMessage(encappedKey, wsChannel) async {
    final msg = jsonEncode({
      "event": "pairing",
      "encappedKey": base64Url.encode(encappedKey),
    });

    wsChannel.sink.add(msg);
  }

  setOnPaired(Function(AeadCipher) onPaired) {
    _onPaired = onPaired;
  }

  void dispose() {
    _cipher.key.dispose();
    _cipher.csprng.dispose();

    _senderAeadCipher?.inner.dispose();
  }

  get wsChannel => _channel;
}
