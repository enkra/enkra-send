import 'dart:html' as html;

import 'package:flutter/foundation.dart';

import 'app_state.dart';
import 'wait_to_pair.dart';
import 'paired.dart';

export 'wait_to_pair.dart';
export 'paired.dart';

class DeviceSendManager extends ChangeNotifier {
  AppState _state;

  static fromCurrentUrl() async {
    final keys = DeviceSendManager._extractSessionKeyFromCurrentUrl();

    final state = keys == null
        ? await WaitToPairState.create()
        : WaitToPairState.connect(keys!);

    return DeviceSendManager._internal(state);
  }

  DeviceSendManager._internal(this._state) {
    if (_state is WaitToPairState) {
      (_state as WaitToPairState).setOnPaired(_handlePaired);
    }
  }

  pairTo(String url) async {
    final keys = DeviceSendManager._extractSessionKeyFromUrl(Uri.parse(url));

    _state = keys == null
        ? await WaitToPairState.create()
        : WaitToPairState.connect(keys!);

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

  _handlePaired() {
    final oldState = _state as WaitToPairState;

    _state = PairedState(
      oldState.wsChannel,
      oldState.cipherKey,
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

