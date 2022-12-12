import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'app_state.dart';
import 'ws_client.dart';

class PairedState extends AppState {
  final WsClient _channel;

  final List<String> _messages = [];

  final String _cipherKey;

  final AesGcm aes = AesGcm.with128bits();

  PairedState(this._channel, this._cipherKey) {
    _listenChannel(_channel);
  }

  List<String> messages() {
    return _messages;
  }

  void sendMessage(text) async {
    final content = await _encryptContent(text);
    _channel.sink.add(content);
  }

  _listenChannel(channel) {
    channel.listen((msg) async {
      final message = jsonDecode(msg);

      if (message["event"] == "message") {
        final content = await _decryptContent(message["content"]);
        _messages.add(content);

        notifyListeners();
      }
    });
  }

  _encryptContent(plaintext) async {
    final secretKey = SecretKey(base64Url.decode(_cipherKey));

    final nonce = aes.newNonce();

    final secretBox = await aes.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return base64Url.encode(secretBox.concatenation());
  }

  _decryptContent(ciphertext) async {
    final secretKey = SecretKey(base64Url.decode(_cipherKey));

    final secretBox = SecretBox.fromConcatenation(
      base64Url.decode(ciphertext),
      nonceLength: 12,
      macLength: 16,
    );

    final plaintext = await aes.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(plaintext);
  }
}
