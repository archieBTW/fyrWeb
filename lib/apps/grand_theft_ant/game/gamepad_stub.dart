import 'gamepad_state.dart';

class GamepadService {
  final ControllerMapping mapping = ControllerMapping();

  void init() {}

  GamepadSnapshot poll() {
    return GamepadSnapshot.empty;
  }
}

