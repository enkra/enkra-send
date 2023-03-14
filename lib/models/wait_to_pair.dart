import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'app_state.dart';
import 'ws_client.dart';
import 'api.dart';

import '../native/native.dart';

const String ENKRA_SEND_APP_URL = String.fromEnvironment('SEND_APP_URL');

class WaitToPairState extends AppState {
  Future<bool>? _isInitliazed;

  WsClient? _wsChannel;
  String? _channelId;
  String? _deviceToken;

  Future<SecureChannelCipher>? _cipher;

  Function(AeadCipher)? _onPaired;

  WaitToPairState.host() {
    _cipher = initCipher();

    _isInitliazed = _initHost();
  }

  initCipher() {
    return SecureChannelCipher.newRandom(bridge: api);
  }

  _initHost() async {
    final requestChannelResult = await requestChannel();

    _channelId = requestChannelResult["channelId"]!;
    _deviceToken = requestChannelResult["hostToken"]!;

    _wsChannel = _buildWsClient(_channelId, _deviceToken);

    _hostListen(_wsChannel);

    return true;
  }

  WaitToPairState.guest(
    this._channelId,
    Uint8List publicKey,
  ) {
    _cipher = initCipher();

    _isInitliazed = _initGuest(_channelId, publicKey);
  }

  _initGuest(channelId, publicKey) async {
    final cipher = await _cipher!;
    final encapKeys = await cipher.encapKey(public: publicKey);

    _deviceToken = await joinChannel(
        channelId, base64Url.encode(encapKeys.encapsulatedKey));

    _wsChannel = _buildWsClient(_channelId, _deviceToken);
    _guestListen(_wsChannel, encapKeys.sharedSecret);

    return true;
  }

  static _buildWsClient(channelId, deviceToken) {
    final wsChannelUrl = Uri.parse('$wsUrl/$channelId/$deviceToken');
    return WsClient(WebSocketChannel.connect(wsChannelUrl));
  }

  String sesssionKey() {
    return _channelId!;
  }

  Future<String> pairingUrl() async {
    await _isInitliazed;

    final cipher = await _cipher!;

    final key = await cipher.public();
    final publicKey = base64Url.encode(key);

    return '$ENKRA_SEND_APP_URL/#/$_channelId/$publicKey';
  }

  _hostListen(channel) async {
    channel.listen((msg) async {
      final message = jsonDecode(msg);

      if (message["event"] == "pairing") {
        final key = message["encappedKey"];

        if (key == null) {
          return;
        }

        final encappedKey = base64Url.decode(key);

        final cipher = await _cipher!;
        final aeadCipher =
            await cipher.sharedSecret(encapsulatedKey: encappedKey);

        final result = await approvePairing(_channelId, _deviceToken);

        _onPaired?.call(aeadCipher);
      }
    });
  }

  _guestListen(channel, aeadCipher) async {
    channel.listen((msg) async {
      final message = jsonDecode(msg);

      if (message["event"] == "paired") {
        _onPaired?.call(aeadCipher);
      }
    });
  }

  setOnPaired(Function(AeadCipher) onPaired) {
    _onPaired = onPaired;
  }

  @override
  void dispose() async {
    if (_cipher != null) {
      final cipher = await _cipher!;

      cipher.key.dispose();
      cipher.csprng.dispose();
    }
  }

  get wsChannel => _wsChannel;
}
