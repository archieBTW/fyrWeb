import 'dart:math' as math;
import 'package:flutter/material.dart';

class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);

  double get length => math.sqrt(x * x + y * y);
  double get lengthSquared => x * x + y * y;

  Vec2 get normalized {
    final len = length;
    if (len < 1e-8) return const Vec2(1, 0);
    return Vec2(x / len, y / len);
  }

  double distanceTo(Vec2 other) => (this - other).length;
  double dot(Vec2 other) => x * other.x + y * other.y;

  Vec2 rotated(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Vec2(x * c - y * s, x * s + y * c);
  }
}

/// The 5 realistic insect & arachnid species the player ant can mount and battle in the City of Grass
enum BugVehicleType {
  rhinoBeetle,
  grasshopper,
  hornet,
  stagBeetle,
  wolfSpider,
}

class BugVehicleSpec {
  final BugVehicleType type;
  final String commonName;
  final String scientificName;
  final String role;
  final String traitDescription;
  final String attackName;
  final double attackDamage;
  final double attackRange;
  final double maxHealth;
  final double sizeMultiplier;
  final double moveSpeed;
  final double sprintSpeed;
  final double rideElevation;
  final double cameraFollowDist;
  final bool canFly;
  final bool canClearObstacles;
  final Color carapacePrimary;
  final Color carapaceSecondary;
  final Color specularHighlight;

  const BugVehicleSpec({
    required this.type,
    required this.commonName,
    required this.scientificName,
    required this.role,
    required this.traitDescription,
    required this.attackName,
    required this.attackDamage,
    required this.attackRange,
    required this.maxHealth,
    required this.sizeMultiplier,
    required this.moveSpeed,
    required this.sprintSpeed,
    required this.rideElevation,
    required this.cameraFollowDist,
    this.canFly = false,
    this.canClearObstacles = false,
    required this.carapacePrimary,
    required this.carapaceSecondary,
    required this.specularHighlight,
  });

  static const Map<BugVehicleType, BugVehicleSpec> specs = {
    BugVehicleType.rhinoBeetle: BugVehicleSpec(
      type: BugVehicleType.rhinoBeetle,
      commonName: 'Hercules Rhino Beetle',
      scientificName: 'Dynastes hercules',
      role: 'Heavy Juggernaut',
      traitDescription: 'Colossal thoracic horn gores and flips rival bugs',
      attackName: 'HORN GORE',
      attackDamage: 55.0,
      attackRange: 2.9,
      maxHealth: 180.0,
      sizeMultiplier: 1.18,
      moveSpeed: 3.9,
      sprintSpeed: 6.4,
      rideElevation: 0.14,
      cameraFollowDist: 1.82,
      canClearObstacles: true,
      carapacePrimary: Color(0xFF6B7342),
      carapaceSecondary: Color(0xFF2B1D14),
      specularHighlight: Color(0xFFDCE3B8),
    ),
    BugVehicleType.grasshopper: BugVehicleSpec(
      type: BugVehicleType.grasshopper,
      commonName: 'Meadow Grasshopper',
      scientificName: 'Chorthippus parallelus',
      role: 'Canopy Leaper',
      traitDescription: 'Spined hind-leg raking kick & high canopy leap',
      attackName: 'SPINED KICK',
      attackDamage: 36.0,
      attackRange: 2.6,
      maxHealth: 110.0,
      sizeMultiplier: 0.96,
      moveSpeed: 5.8,
      sprintSpeed: 8.6,
      rideElevation: 0.08,
      cameraFollowDist: 1.54,
      carapacePrimary: Color(0xFF567D35),
      carapaceSecondary: Color(0xFF8C733E),
      specularHighlight: Color(0xFFC8E09B),
    ),
    BugVehicleType.hornet: BugVehicleSpec(
      type: BugVehicleType.hornet,
      commonName: 'European Hornet',
      scientificName: 'Vespa crabro',
      role: 'Aerial Striker',
      traitDescription: 'Venomous barbed stinger dive & 3D flight',
      attackName: 'VENOM STING',
      attackDamage: 46.0,
      attackRange: 2.8,
      maxHealth: 120.0,
      sizeMultiplier: 0.95,
      moveSpeed: 6.6,
      sprintSpeed: 9.5,
      rideElevation: 0.42,
      cameraFollowDist: 1.58,
      canFly: true,
      carapacePrimary: Color(0xFFC47D1B),
      carapaceSecondary: Color(0xFF2E1A0F),
      specularHighlight: Color(0xFFF5D799),
    ),
    BugVehicleType.stagBeetle: BugVehicleSpec(
      type: BugVehicleType.stagBeetle,
      commonName: 'Greater Stag Beetle',
      scientificName: 'Lucanus cervus',
      role: 'Armored Crusher',
      traitDescription: 'Serrated antler mandibles crush rival chitin',
      attackName: 'ANTLER CRUSH',
      attackDamage: 50.0,
      attackRange: 2.8,
      maxHealth: 160.0,
      sizeMultiplier: 1.12,
      moveSpeed: 4.6,
      sprintSpeed: 6.8,
      rideElevation: 0.11,
      cameraFollowDist: 1.74,
      canClearObstacles: true,
      carapacePrimary: Color(0xFF592316),
      carapaceSecondary: Color(0xFF1F1614),
      specularHighlight: Color(0xFFC98A76),
    ),
    BugVehicleType.wolfSpider: BugVehicleSpec(
      type: BugVehicleType.wolfSpider,
      commonName: 'Giant Wolf Spider',
      scientificName: 'Hogna carolinensis',
      role: 'Apex Arachnid',
      traitDescription: '8-legged ambush pounce & venomous chelicerae fangs',
      attackName: 'FANG POUNCE',
      attackDamage: 48.0,
      attackRange: 2.8,
      maxHealth: 145.0,
      sizeMultiplier: 1.10,
      moveSpeed: 6.2,
      sprintSpeed: 9.2,
      rideElevation: 0.10,
      cameraFollowDist: 1.76,
      carapacePrimary: Color(0xFF4A3828),
      carapaceSecondary: Color(0xFF1F1610),
      specularHighlight: Color(0xFFC4AD8D),
    ),
  };

  static BugVehicleSpec of(BugVehicleType type) => specs[type]!;
}

/// Mountable & Battleable Bug roaming the open world
class MountableBug {
  final int id;
  final BugVehicleType type;
  Vec2 pos;
  double angle;
  double wanderTimer = 2.0;
  double walkPhase = 0.0;
  bool isMoving = true;

  // Combat & Health state
  late double health;
  late final double maxHealth;
  double hitFlashTimer = 0.0;
  double attackPhase = 0.0;
  double aiAttackCooldown = 0.0;
  double aggroTimer = 0.0;

  MountableBug({
    required this.id,
    required this.type,
    required this.pos,
    required this.angle,
    this.walkPhase = 0.0,
    double? currentHealth,
  }) {
    maxHealth = BugVehicleSpec.of(type).maxHealth;
    health = currentHealth ?? maxHealth;
  }

  BugVehicleSpec get spec => BugVehicleSpec.of(type);
}

enum GrassCrownType {
  archingBlade,
  seedPanicle,
  cloverUmbrella,
  dandelionTower,
  dewdropBlade,
}

/// A towering 3D grass plant cluster in the "City of Grass"
class GrassStalk3D {
  final Vec2 pos;
  final double height; // 1.4 to 3.6 units tall (skyscraper scale relative to ant!)
  final double baseWidth;
  final double archAngle; // Direction the upper blade arches overhead
  final double archReach; // How far the blade arches horizontally over the street
  final double swayPhase;
  final Color baseColor;
  final Color midColor;
  final Color tipColor;
  final GrassCrownType crownType;
  final int subBlades;

  const GrassStalk3D({
    required this.pos,
    required this.height,
    required this.baseWidth,
    required this.archAngle,
    required this.archReach,
    required this.swayPhase,
    required this.baseColor,
    required this.midColor,
    required this.tipColor,
    required this.crownType,
    this.subBlades = 3,
  });
}

/// Real-life backyard & botanical 3D scenery elements that give true macro scale
enum RealLifeObjectType {
  pennyCoin,
  glassMarble,
  bottleCap,
  terracottaShard,
  gardenKey,
  fallenOakLeaf,
  riverPebble,
  cloverBlossom,
  pineCone,
  rainPuddle,
}

class RealLifeProp3D {
  final Vec2 pos;
  final RealLifeObjectType type;
  final double rotation;
  final double scale;
  final String label;

  const RealLifeProp3D({
    required this.pos,
    required this.type,
    this.rotation = 0.0,
    this.scale = 1.0,
    required this.label,
  });
}

/// Natural foraging items in the open world
enum ForageType {
  dewdrop,
  honeydewNectar,
  pineSeed,
  wildBerry,
}

class ForageItem {
  Vec2 pos;
  final ForageType type;
  double shimmerPhase;

  ForageItem({
    required this.pos,
    required this.type,
    this.shimmerPhase = 0.0,
  });

  Color get color {
    switch (type) {
      case ForageType.dewdrop:
        return const Color(0xFFB8E2F2);
      case ForageType.honeydewNectar:
        return const Color(0xFFE8A838);
      case ForageType.pineSeed:
        return const Color(0xFF8C6239);
      case ForageType.wildBerry:
        return const Color(0xFF9E2A3B);
    }
  }

  String get label {
    switch (type) {
      case ForageType.dewdrop:
        return 'Morning Dewdrop';
      case ForageType.honeydewNectar:
        return 'Golden Honeydew';
      case ForageType.pineSeed:
        return 'Pine Nut Seed';
      case ForageType.wildBerry:
        return 'Wild Bramble Berry';
    }
  }
}

/// Floating pollen, dust motes, or sunlit spores
class NatureParticle3D {
  Vec2 pos;
  Vec2 vel;
  double z;
  double vz;
  double life;
  final double maxLife;
  final Color color;
  final double size;

  NatureParticle3D({
    required this.pos,
    required this.vel,
    required this.z,
    required this.vz,
    required this.life,
    required this.color,
    this.size = 0.04,
  }) : maxLife = life;
}

class FloatingNote3D {
  Vec2 pos;
  double z;
  final String text;
  final Color color;
  double life;
  final double maxLife;

  FloatingNote3D({
    required this.pos,
    required this.z,
    required this.text,
    required this.color,
    this.life = 1.2,
  }) : maxLife = life;
}

class FieldLogEntry {
  final String message;
  final Color color;
  double life;

  FieldLogEntry({
    required this.message,
    required this.color,
    this.life = 5.5,
  });
}

/// Objectives given by Colony NPC Ants
enum MissionType {
  mountBug,
  defeatBug,
  forageItem,
  reachLocation,
  leapAction,
}

enum MissionStatus {
  available,
  active,
  completed,
  claimed,
}

class Mission {
  final String id;
  final String title;
  final String description;
  final String giverName;
  final MissionType type;
  final BugVehicleType? targetBug;
  final ForageType? targetForage;
  final Vec2? targetLocation;
  final double targetRadius;
  final String? targetLocationName;
  final int targetCount;
  int currentCount;
  final int scoreReward;
  final String introDialogue;
  final String inProgressDialogue;
  final String completionDialogue;
  MissionStatus status;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.giverName,
    required this.type,
    this.targetBug,
    this.targetForage,
    this.targetLocation,
    this.targetRadius = 5.0,
    this.targetLocationName,
    this.targetCount = 1,
    this.currentCount = 0,
    required this.scoreReward,
    required this.introDialogue,
    required this.inProgressDialogue,
    required this.completionDialogue,
    this.status = MissionStatus.available,
  });

  bool get isFinished => currentCount >= targetCount;
  double get progressRatio =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;
}

/// Friendly NPC Ants from the Colony providing dialogue and missions
class NpcAnt {
  final int id;
  final String name;
  final String rank;
  final String title;
  final Color chitinColor;
  final Color crestColor;
  Vec2 pos;
  double angle;
  final List<Mission> missions;
  int activeMissionIndex;
  double walkPhase;
  double antennaeTwitchTimer;

  NpcAnt({
    required this.id,
    required this.name,
    required this.rank,
    required this.title,
    required this.chitinColor,
    required this.crestColor,
    required this.pos,
    required this.angle,
    required this.missions,
    this.activeMissionIndex = 0,
    this.walkPhase = 0.0,
    this.antennaeTwitchTimer = 0.0,
  });

  Mission? get currentMission {
    if (activeMissionIndex >= 0 && activeMissionIndex < missions.length) {
      return missions[activeMissionIndex];
    }
    return null;
  }

  bool get hasClaimableMission {
    final m = currentMission;
    return m != null && m.status == MissionStatus.completed;
  }

  bool get hasAvailableMission {
    final m = currentMission;
    return m != null && m.status == MissionStatus.available;
  }

  bool get hasActiveMission {
    final m = currentMission;
    return m != null && m.status == MissionStatus.active;
  }

  bool get allMissionsClaimed => activeMissionIndex >= missions.length;
}
