import 'dart:js_interop';
import 'dart:ui';
import 'package:web/web.dart' as web;
import 'web_input_stub.dart';

export 'web_input_stub.dart' show GamepadState;

GamepadState pollWebGamepads() {
  bool connected = false;
  final buttonsDown = <int>{};
  Offset stick = Offset.zero;

  try {
    final pads = web.window.navigator.getGamepads().toDart;
    for (final p in pads) {
      if (p == null || !p.connected) continue;
      connected = true;
      final btns = p.buttons.toDart;
      for (var i = 0; i < btns.length; i++) {
        if (btns[i].pressed || btns[i].value > 0.5) buttonsDown.add(i);
      }
      final axes = p.axes.toDart;
      if (axes.length >= 2) {
        final v = Offset(axes[0].toDartDouble, axes[1].toDartDouble);
        if (v.distance > 0.25 && v.distance > stick.distance) stick = v;
      }
    }
  } catch (_) {}

  return GamepadState(
    connected: connected,
    buttonsDown: buttonsDown,
    stick: stick,
  );
}

void saveStorage(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {}
}

String? loadStorage(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

