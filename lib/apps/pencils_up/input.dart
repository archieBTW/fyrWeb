import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'web_input_stub.dart'
    if (dart.library.js_interop) 'web_input_web.dart';

enum Act { up, down, left, right, confirm, cancel, menu }

const actNames = {
  Act.up: 'Up',
  Act.down: 'Down',
  Act.left: 'Left',
  Act.right: 'Right',
  Act.confirm: 'Confirm / Talk',
  Act.cancel: 'Cancel / Back',
  Act.menu: 'Pause Menu',
};

final defaultKeys = <Act, List<LogicalKeyboardKey>>{
  Act.up: [LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW],
  Act.down: [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS],
  Act.left: [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA],
  Act.right: [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD],
  Act.confirm: [LogicalKeyboardKey.enter, LogicalKeyboardKey.space, LogicalKeyboardKey.keyZ],
  Act.cancel: [LogicalKeyboardKey.backspace, LogicalKeyboardKey.keyX],
  Act.menu: [LogicalKeyboardKey.escape, LogicalKeyboardKey.keyM, LogicalKeyboardKey.tab],
};

/// Standard Gamepad mapping (https://w3c.github.io/gamepad/#remapping).
final defaultPad = <Act, List<int>>{
  Act.up: [12],
  Act.down: [13],
  Act.left: [14],
  Act.right: [15],
  Act.confirm: [0],
  Act.cancel: [1],
  Act.menu: [9, 8],
};

const padButtonNames = {
  0: 'A / Cross',
  1: 'B / Circle',
  2: 'X / Square',
  3: 'Y / Triangle',
  4: 'LB',
  5: 'RB',
  6: 'LT',
  7: 'RT',
  8: 'Select',
  9: 'Start',
  10: 'L-Stick',
  11: 'R-Stick',
  12: 'D-Up',
  13: 'D-Down',
  14: 'D-Left',
  15: 'D-Right',
  16: 'Home',
};

/// Unifies keyboard, gamepad and touch input into held actions, edge-triggered
/// presses (with auto-repeat for directions) and an analog move vector.
class InputManager {
  final keys = <Act, List<LogicalKeyboardKey>>{};
  final pad = <Act, List<int>>{};

  final _keysDown = <LogicalKeyboardKey>{};
  final _keyPulse = <LogicalKeyboardKey>{};
  final _padDown = <int>{};
  Offset _padStick = Offset.zero;
  bool padConnected = false;

  // touch
  Offset joystick = Offset.zero; // magnitude 0..1
  final touchHeld = <Act>{};
  final _touchPulse = <Act>{};

  final _held = <Act>{};
  final _repeatT = <Act, double>{};
  final pressed = <Act>[];

  /// When non-null the next key (or pad button) press rebinds this action.
  Act? rebindAct;
  bool rebindPad = false;
  VoidCallback? onRebound;

  InputManager() {
    resetDefaults();
    _load();
  }

  void resetDefaults() {
    keys
      ..clear()
      ..addAll({for (final e in defaultKeys.entries) e.key: [...e.value]});
    pad
      ..clear()
      ..addAll({for (final e in defaultPad.entries) e.key: [...e.value]});
  }

  void dispose() {
    clearKeys();
  }

  void clearKeys() {
    _keysDown.clear();
    _keyPulse.clear();
    _padDown.clear();
  }

  bool handleKeyEvent(KeyEvent e) {
    if (e is KeyDownEvent) {
      if (rebindAct != null && !rebindPad) {
        _bindKey(rebindAct!, e.logicalKey);
        return true;
      }
      _keysDown.add(e.logicalKey);
      _keyPulse.add(e.logicalKey);
    } else if (e is KeyUpEvent) {
      _keysDown.remove(e.logicalKey);
    }
    // Swallow keys we use so the browser doesn't scroll / tab focus.
    return keys.values.any((l) => l.contains(e.logicalKey));
  }

  void _bindKey(Act a, LogicalKeyboardKey k) {
    for (final l in keys.values) {
      l.remove(k);
    }
    keys[a] = [k];
    _finishRebind();
  }

  void _bindPad(Act a, int b) {
    for (final l in pad.values) {
      l.remove(b);
    }
    pad[a] = [b];
    _finishRebind();
  }

  void _finishRebind() {
    rebindAct = null;
    _save();
    _keysDown.clear();
    _padDown.clear();
    onRebound?.call();
  }

  void touchPress(Act a) {
    _touchPulse.add(a);
  }

  void _pollPad() {
    final state = pollWebGamepads();
    padConnected = state.connected;
    _padStick = state.stick;
    final newDown = state.buttonsDown;

    if (rebindAct != null && rebindPad) {
      final fresh = newDown.difference(_padDown);
      if (fresh.isNotEmpty) {
        _padDown
          ..clear()
          ..addAll(newDown);
        _bindPad(rebindAct!, fresh.first);
        return;
      }
    }
    _padDown
      ..clear()
      ..addAll(newDown);
  }

  /// Analog movement vector combined from all sources (length <= 1).
  Offset get move {
    var v = Offset.zero;
    if (_held.contains(Act.left)) v += const Offset(-1, 0);
    if (_held.contains(Act.right)) v += const Offset(1, 0);
    if (_held.contains(Act.up)) v += const Offset(0, -1);
    if (_held.contains(Act.down)) v += const Offset(0, 1);
    return v;
  }

  bool held(Act a) => _held.contains(a);

  void update(double dt) {
    _pollPad();
    pressed.clear();
    final now = <Act>{};
    if (rebindAct == null) {
      for (final a in Act.values) {
        if (keys[a]!.any((k) => _keysDown.contains(k) || _keyPulse.contains(k))) now.add(a);
        if (pad[a]!.any(_padDown.contains)) now.add(a);
      }
      now.addAll(touchHeld);
      now.addAll(_touchPulse);
      for (final v in [_padStick, joystick]) {
        if (v.distance < 0.35) continue;
        final ang = math.atan2(v.dy, v.dx);
        // 8-way thresholds
        if (math.cos(ang) > 0.38) now.add(Act.right);
        if (math.cos(ang) < -0.38) now.add(Act.left);
        if (math.sin(ang) > 0.38) now.add(Act.down);
        if (math.sin(ang) < -0.38) now.add(Act.up);
      }
    }
    _keyPulse.clear();
    _touchPulse.clear();

    for (final a in now) {
      if (!_held.contains(a)) {
        pressed.add(a);
        _repeatT[a] = 0.38;
      } else if (a.index <= Act.right.index) {
        _repeatT[a] = (_repeatT[a] ?? 0) - dt;
        if (_repeatT[a]! <= 0) {
          pressed.add(a);
          _repeatT[a] = 0.11;
        }
      }
    }
    _held
      ..clear()
      ..addAll(now);
  }

  String keyLabel(Act a) => keys[a]!.map((k) => k.keyLabel.isEmpty ? k.debugName : k.keyLabel).join(', ');
  String padLabel(Act a) => pad[a]!.map((b) => padButtonNames[b] ?? 'Btn $b').join(', ');

  void _save() {
    try {
      final k = keys.entries.map((e) => '${e.key.name}:${e.value.map((k) => k.keyId).join(',')}').join(';');
      final p = pad.entries.map((e) => '${e.key.name}:${e.value.join(',')}').join(';');
      saveStorage('pu_keys', k);
      saveStorage('pu_pad', p);
    } catch (_) {}
  }

  void saveDefaults() {
    resetDefaults();
    _save();
  }

  void _load() {
    try {
      final k = loadStorage('pu_keys');
      final p = loadStorage('pu_pad');
      if (k != null) {
        for (final part in k.split(';')) {
          final kv = part.split(':');
          final a = Act.values.byName(kv[0]);
          final list = kv[1]
              .split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => LogicalKeyboardKey.findKeyByKeyId(int.parse(s)))
              .whereType<LogicalKeyboardKey>()
              .toList();
          if (list.isNotEmpty) keys[a] = list;
        }
      }
      if (p != null) {
        for (final part in p.split(';')) {
          final kv = part.split(':');
          final a = Act.values.byName(kv[0]);
          final list = kv[1].split(',').where((s) => s.isNotEmpty).map(int.parse).toList();
          if (list.isNotEmpty) pad[a] = list;
        }
      }
    } catch (_) {
      resetDefaults();
    }
  }
}
