import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'app_state.dart';
import 'ws_client.dart';
import 'api.dart';
import '../src/rust/api/crypto.dart';

const String ENKRA_SEND_APP_URL = String.fromEnvironment('SEND_APP_URL');

class WaitToPairState extends AppState {
  WsClient? _wsChannel;
  String? channelId;
  String? _deviceToken;

  SecureChannelCipher? _cipher;

  Future<bool>? isInitialized;

  Function(AeadCipher)? _onPaired;

  WaitToPairState._create();

  static host() {
    final state = WaitToPairState._create();

    state.isInitialized = state._initHost();

    return state;
  }

  initCipher() {
    return SecureChannelCipher.newRandom();
  }

  Future<bool> _initHost() async {
    final cipher = initCipher();
    final requestChannelResult = await requestChannel();

    channelId = requestChannelResult["channelId"]!;
    _deviceToken = requestChannelResult["hostToken"]!;

    _wsChannel = _buildWsClient(channelId, _deviceToken);

    _hostListen(_wsChannel);

    _cipher = await cipher;

    return true;
  }

  static guest(
    channelId,
    Uint8List publicKey,
  ) {
    final state = WaitToPairState._create();

    state.isInitialized = state._initGuest(channelId, publicKey);

    return state;
  }

  _initGuest(channelId, publicKey) async {
    this.channelId = channelId;

    _cipher = await initCipher();

    final cipher = _cipher!;

    final encapKeys = await cipher.encapKey(public: publicKey);

    _deviceToken = await joinChannel(
        channelId, base64Url.encode(encapKeys.encapsulatedKey));

    _wsChannel = _buildWsClient(channelId, _deviceToken);
    _guestListen(_wsChannel, encapKeys.sharedSecret);

    return true;
  }

  static _buildWsClient(channelId, deviceToken) {
    final wsChannelUrl = Uri.parse('$wsUrl/$channelId/$deviceToken');
    return WsClient(WebSocketChannel.connect(wsChannelUrl));
  }

  String sesssionKey() {
    return channelId!;
  }

  Future<String> pairingUrl() async {
    await isInitialized;

    final cipher = _cipher!;

    final key = await cipher.public();
    final publicKey = base64Url.encode(key);

    return '$ENKRA_SEND_APP_URL/#/$channelId/$publicKey';
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

        final cipher = _cipher!;
        final aeadCipher =
            await cipher.sharedSecret(encapsulatedKey: encappedKey);

        await approvePairing(channelId, _deviceToken);

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
    super.dispose();

    if (_cipher != null) {
      final cipher = _cipher!;

      cipher.key.dispose();
      cipher.csprng.dispose();
    }
  }

  get wsChannel => _wsChannel;
}
