import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'app_state.dart';
import 'ws_client.dart';
import 'api.dart';

import '../native/native.dart';

const String ENKRA_SEND_APP_URL = String.fromEnvironment('SEND_APP_URL');

class WaitToPairState extends AppState {
  final WsClient _channel;
  final String _channelId;
  final String _deviceToken;

  final SecureChannelCipher _cipher;

  Function(AeadCipher)? _onPaired;

  final bool _isSender;
  AeadCipher? _senderAeadCipher;

  WaitToPairState._internal(
    WebSocketChannel channel,
    this._channelId,
    this._cipher,
    this._isSender,
    this._senderAeadCipher,
    this._deviceToken,
  ) : _channel = WsClient(channel) {
    if (_isSender) {
      _senderListen(_channel);
    } else {
      _receiverListen(_channel);
    }
  }

  static create() async {
    final result = await Future.wait([
      requestChannel(),
      SecureChannelCipher.newRandom(bridge: api),
    ]);

    final requestChannelResult = result[0];
    final channelCipher = result[1];

    final channelId = requestChannelResult["channelId"]!;
    final deviceToken = requestChannelResult["hostToken"]!;

    final wsChannelUrl = Uri.parse('$wsUrl/$channelId/$deviceToken');
    final channel = WebSocketChannel.connect(wsChannelUrl);

    return WaitToPairState._internal(
      channel,
      channelId,
      channelCipher,
      false,
      null,
      deviceToken,
    );
  }

  static connect(List<String> tokens) async {
    final channelId = tokens[0];
    final publicKey = base64Url.decode(tokens[1]);

    final channelCipher = await SecureChannelCipher.newRandom(bridge: api);
    final encapKeys = await channelCipher.encapKey(public: publicKey);

    final deviceToken = await joinChannel(
        channelId, base64Url.encode(encapKeys.encapsulatedKey));

    final wsChannelUrl = Uri.parse('$wsUrl/$channelId/$deviceToken');
    final channel = WebSocketChannel.connect(wsChannelUrl);

    return WaitToPairState._internal(
      channel,
      channelId,
      channelCipher,
      true,
      encapKeys.sharedSecret,
      deviceToken,
    );
  }

  String sesssionKey() {
    return _channelId;
  }

  Future<String> pairingUrl() async {
    final key = await _cipher.public();
    final publicKey = base64Url.encode(key);

    return '$ENKRA_SEND_APP_URL/#/$_channelId/$publicKey';
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

        final result = await approvePairing(_channelId, _deviceToken);

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

  setOnPaired(Function(AeadCipher) onPaired) {
    _onPaired = onPaired;
  }

  @override
  void dispose() {
    _cipher.key.dispose();
    _cipher.csprng.dispose();

    _senderAeadCipher?.inner.dispose();
  }

  get wsChannel => _channel;
}
