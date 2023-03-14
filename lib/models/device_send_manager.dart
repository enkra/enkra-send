import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'app_state.dart';
import 'wait_to_pair.dart';
import 'paired.dart';

export 'wait_to_pair.dart';
export 'paired.dart';

class DeviceSendManager extends ChangeNotifier {
  AppState _state;

  static fromCurrentUrl() {
    final keys = DeviceSendManager._extractSessionKeyFromCurrentUrl();

    WaitToPairState state;

    if (keys == null) {
      state = WaitToPairState.host();
    } else {
      final channelId = keys[0];
      final publicKey = base64Url.decode(keys[1]);

      state = WaitToPairState.guest(channelId, publicKey);
    }

    return DeviceSendManager._internal(state);
  }

  DeviceSendManager._internal(this._state) {
    if (_state is WaitToPairState) {
      (_state as WaitToPairState).setOnPaired(_handlePaired);
    }
  }

  pairTo(String url) {
    final keys = DeviceSendManager._extractSessionKeyFromUrl(Uri.parse(url));

    // dispose old state
    _state.dispose();

    if (keys == null) {
      _state = WaitToPairState.host();
    } else {
      final channelId = keys[0];
      final publicKey = base64Url.decode(keys[1]);

      _state = WaitToPairState.guest(channelId, publicKey);
    }

    (_state as WaitToPairState).setOnPaired(_handlePaired);

    notifyListeners();
  }

  static _extractSessionKeyFromCurrentUrl() {
    final url = Uri.parse(html.window.location.href);

    return _extractSessionKeyFromUrl(url);
  }

  static _extractSessionKeyFromUrl(Uri url) {
    final tag = url.fragment.trim().split('/');

    if (tag.length > 2) {
      final sessionKey = tag[1];
      final cipherKey = tag[2];

      return [sessionKey, cipherKey];
    } else {
      return null;
    }
  }

  _handlePaired(aeadCipher) {
    final oldState = _state as WaitToPairState;

    _state = PairedState(
      oldState.wsChannel,
      aeadCipher,
    );

    oldState.dispose();

    notifyListeners();
  }

  AppState currentState() {
    return _state;
  }

  T currentStateAs<T extends AppState>() {
    return _state as T;
  }
}
