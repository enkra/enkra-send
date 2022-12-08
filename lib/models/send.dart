import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nanoid/nanoid.dart';
import 'package:cryptography/cryptography.dart';

const String WS_API_URL = String.fromEnvironment('WS_API_URL');
const String ENKRA_SEND_APP_URL = String.fromEnvironment('SEND_APP_URL');

abstract class AppState extends ChangeNotifier {}

abstract class NonPairedState extends AppState {
  Function()? _onPaired;

  _setOnPaired(Function() onPaired) {
    _onPaired = onPaired;
  }
}

class WaitToPairState extends NonPairedState {
  final WsClient _channel;

  final String _sessionKey;

  final String _cipherKey;

  WaitToPairState._internal(
    WebSocketChannel channel,
    this._sessionKey,
    this._cipherKey,
  ) : _channel = WsClient._internal(channel) {
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
}

class PairedState extends AppState {
  final WsClient _channel;

  final List<String> _messages = [];

  final String _cipherKey;

  final AesGcm aes = AesGcm.with128bits();

  PairedState._internal(this._channel, this._cipherKey) {
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

class DeviceSendManager extends ChangeNotifier {
  AppState _state;

  static fromCurrentUrl() async {
    final keys = DeviceSendManager._extractSessionKeyFromUrl();

    final state = keys == null
        ? await WaitToPairState.create()
        : WaitToPairState.connect(keys!);

    return DeviceSendManager._internal(state);
  }

  DeviceSendManager._internal(this._state) {
    if (_state is WaitToPairState) {
      (_state as WaitToPairState)._setOnPaired(_handlePaired);
    }
  }

  static _extractSessionKeyFromUrl() {
    final url = Uri.parse(html.window.location.href).fragment.trim();
    var tag = url.split('/');

    if (tag.length > 2) {
      final sessionKey = tag[1];
      final cipherKey = tag[2];

      return [sessionKey, cipherKey];
    } else {
      return null;
    }
  }

  _handlePaired() {
    final oldState = _state as WaitToPairState;

    _state = PairedState._internal(
      oldState._channel,
      oldState._cipherKey,
    );

    notifyListeners();
  }

  AppState currentState() {
    return _state;
  }

  T currentStateAs<T extends AppState>() {
    return _state as T;
  }
}

class WsClient {
  final WebSocketChannel _channel;

  Function(String)? _listen;

  WsClient._internal(this._channel) {
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
