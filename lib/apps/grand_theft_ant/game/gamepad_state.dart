enum ControllerPreset {
  standard,
  bumperJumper,
  actionCombat,
}

class ControllerMapping {
  ControllerPreset preset;
  int jumpButton;
  int attackButton;
  int mountButton;
  int sprintButton;
  int pauseButton;
  double deadzone;
  double lookSensitivity;
  bool invertLookY;

  ControllerMapping({
    this.preset = ControllerPreset.standard,
    this.jumpButton = 0, // A / Cross
    this.attackButton = 7, // RT (or 3: Y / Triangle)
    this.mountButton = 2, // X / Square
    this.sprintButton = 1, // B / Circle
    this.pauseButton = 9, // Start / Menu
    this.deadzone = 0.14,
    this.lookSensitivity = 1.0,
    this.invertLookY = false,
  });

  void applyPreset(ControllerPreset newPreset) {
    preset = newPreset;
    switch (newPreset) {
      case ControllerPreset.standard:
        jumpButton = 0; // A / Cross
        attackButton = 7; // RT
        mountButton = 2; // X / Square
        sprintButton = 1; // B / Circle
        pauseButton = 9; // Start / Menu
        break;
      case ControllerPreset.bumperJumper:
        jumpButton = 4; // LB
        attackButton = 5; // RB
        mountButton = 2; // X
        sprintButton = 0; // A
        pauseButton = 9;
        break;
      case ControllerPreset.actionCombat:
        jumpButton = 0; // A
        attackButton = 3; // Y
        mountButton = 2; // X
        sprintButton = 5; // RB
        pauseButton = 9;
        break;
    }
  }

  String get presetName {
    switch (preset) {
      case ControllerPreset.standard:
        return 'Standard (A=Leap, RT=Attack, X=Mount)';
      case ControllerPreset.bumperJumper:
        return 'Bumper Jumper (LB=Leap, RB=Attack, X=Mount)';
      case ControllerPreset.actionCombat:
        return 'Action Combat (A=Leap, Y=Attack, RB=Sprint)';
    }
  }
}

class GamepadSnapshot {
  final bool isConnected;
  final String id;
  final double moveForward; // -1.0 to 1.0
  final double moveStrafe; // -1.0 to 1.0
  final double lookX; // -1.0 to 1.0
  final double lookY; // -1.0 to 1.0
  final bool jump;
  final bool attack;
  final bool mount;
  final bool sprint;
  final bool pause;

  const GamepadSnapshot({
    this.isConnected = false,
    this.id = '',
    this.moveForward = 0.0,
    this.moveStrafe = 0.0,
    this.lookX = 0.0,
    this.lookY = 0.0,
    this.jump = false,
    this.attack = false,
    this.mount = false,
    this.sprint = false,
    this.pause = false,
  });

  static const empty = GamepadSnapshot();
}
