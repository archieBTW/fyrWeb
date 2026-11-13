import 'dart:ui';

class GamepadState {
  final bool connected;
  final Set<int> buttonsDown;
  final Offset stick;
  const GamepadState({
    this.connected = false,
    this.buttonsDown = const {},
    this.stick = Offset.zero,
  });
}

GamepadState pollWebGamepads() => const GamepadState();

void saveStorage(String key, String value) {}

String? loadStorage(String key) => null;

