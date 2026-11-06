import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'gamepad_state.dart';

@JS('window')
external JSObject get _window;

class GamepadService {
  final ControllerMapping mapping = ControllerMapping();

  void init() {}

  GamepadSnapshot poll() {
    try {
      final gamepadManager = _window['cyberGamepad'];
      if (gamepadManager == null || !gamepadManager.isA<JSObject>()) {
        return GamepadSnapshot.empty;
      }

      final res = (gamepadManager as JSObject).callMethod('poll'.toJS);
      if (res == null || !res.isA<JSObject>()) {
        return GamepadSnapshot.empty;
      }

      final obj = res as JSObject;
      final connectedProp = obj['connected'];
      final isConn = connectedProp != null && (connectedProp as JSBoolean).toDart;
      if (!isConn) {
        return GamepadSnapshot.empty;
      }

      final idProp = obj['id'];
      final padId = idProp != null ? (idProp as JSString).toDart : 'Controller';

      // Read axes
      final axesProp = obj['axes'];
      double rawLx = 0.0;
      double rawLy = 0.0;
      double rawRx = 0.0;
      double rawRy = 0.0;

      if (axesProp != null && axesProp.isA<JSArray>()) {
        final arr = axesProp as JSArray;
        if (arr.length > 0) rawLx = _toDouble(arr[0]);
        if (arr.length > 1) rawLy = _toDouble(arr[1]);
        if (arr.length > 2) rawRx = _toDouble(arr[2]);
        if (arr.length > 3) rawRy = _toDouble(arr[3]);
      }

      // Read buttons
      final buttonsProp = obj['buttons'];
      final pressedButtons = <int, bool>{};
      if (buttonsProp != null && buttonsProp.isA<JSArray>()) {
        final arr = buttonsProp as JSArray;
        for (int i = 0; i < arr.length; i++) {
          final val = _toDouble(arr[i]);
          pressedButtons[i] = val > 0.45;
        }
      }

      // Apply deadzone
      double filter(double v) {
        return v.abs() > mapping.deadzone ? v : 0.0;
      }

      final lx = filter(rawLx);
      final ly = filter(rawLy);
      final rx = filter(rawRx);
      final ry = filter(rawRy);

      // Left stick: move forward is -Y, strafe is +X
      final moveForward = -ly;
      final moveStrafe = lx;

      // Right stick: look yaw and pitch
      final lookX = rx;
      final lookY = ry;

      // Map buttons according to user's ControllerMapping
      final jump = pressedButtons[mapping.jumpButton] ?? false;
      final attack = (pressedButtons[mapping.attackButton] ?? false) ||
          (pressedButtons[7] ?? false) || // RT alternative
          (pressedButtons[5] ?? false); // RB alternative
      final mount = pressedButtons[mapping.mountButton] ?? false;
      final sprint = (pressedButtons[mapping.sprintButton] ?? false) ||
          (pressedButtons[10] ?? false); // L3 stick click
      final pause = pressedButtons[mapping.pauseButton] ?? false;

      return GamepadSnapshot(
        isConnected: true,
        id: padId,
        moveForward: moveForward,
        moveStrafe: moveStrafe,
        lookX: lookX,
        lookY: lookY,
        jump: jump,
        attack: attack,
        mount: mount,
        sprint: sprint,
        pause: pause,
      );
    } catch (_) {
      return GamepadSnapshot.empty;
    }
  }

  double _toDouble(JSAny? val) {
    if (val == null) return 0.0;
    if (val.isA<JSNumber>()) {
      return (val as JSNumber).toDartDouble;
    }
    return 0.0;
  }
}
