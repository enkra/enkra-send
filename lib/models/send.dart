import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nanoid/nanoid.dart';

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

  WaitToPairState._internal(WebSocketChannel channel, this._sessionKey)
      : _channel = WsClient._internal(channel) {
    _listenChannel(_channel);
  }

  factory WaitToPairState.create() {
    final sessionKey = nanoid();
    final wsUrl = Uri.parse('${WS_API_URL}/$sessionKey');
    final channel = WebSocketChannel.connect(wsUrl);

    return WaitToPairState._internal(channel, sessionKey);
  }

  factory WaitToPairState.connect(String sessionKey) {
    final wsUrl = Uri.parse('${WS_API_URL}/$sessionKey');
    final channel = WebSocketChannel.connect(wsUrl);

    return WaitToPairState._internal(channel, sessionKey);
  }

  String sesssionKey() {
    return _sessionKey;
  }

  String pairingUrl() {
    return '${ENKRA_SEND_APP_URL}/#/$_sessionKey';
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

  PairedState._internal(this._channel) {
    _listenChannel(_channel);
  }

  List<String> messages() {
    return _messages;
  }

  void sendMessage(text) {
    _channel.sink.add(text);
  }

  _listenChannel(channel) async {
    channel.listen((msg) {
      final message = jsonDecode(msg);

      if (message["event"] == "message") {
        _messages.add(message["content"]);
        notifyListeners();
      }
    });
  }
}

class DeviceSendManager extends ChangeNotifier {
  AppState _state;

  factory DeviceSendManager.fromCurrentUrl() {
    final sessionKey = DeviceSendManager._extractSessionKeyFromUrl();

    final state = sessionKey == null
        ? WaitToPairState.create()
        : WaitToPairState.connect(sessionKey!);

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

    final sessionKey = tag.length > 1 ? tag[1] : null;

    if (sessionKey != "") {
      return sessionKey;
    } else {
      return null;
    }
  }

  _handlePaired() {
    final oldState = _state as WaitToPairState;

    _state = PairedState._internal(oldState._channel);

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
