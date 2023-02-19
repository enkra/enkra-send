import 'dart:html';
import 'dart:async';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'bridge_generated.web.dart';

const root = 'native/native';

FutureOr<WasmModule> _initModule() {
  if (crossOriginIsolated != true) {
    return Future.error(const MissingHeaderException());
  }

  final script = ScriptElement()..src = '$root.js';
  document.head!.append(script);
  return script.onLoad.first.then((_) {
    eval("window.wasm_bindgen = wasm_bindgen");
    return wasmModule.bind(wasmModule, '${root}_bg.wasm');
  });
}

late final api = NativeImpl.wasm(_initModule());
