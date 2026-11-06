import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'macro_cache.dart';
import 'models.dart';
import 'sound.dart';

class RayHit {
  final double distance;
  final int wallType;
  final bool hitVertical;
  final double wallX;
  final int mapX;
  final int mapY;

  const RayHit({
    required this.distance,
    required this.wallType,
    required this.hitVertical,
    required this.wallX,
    required this.mapX,
    required this.mapY,
  });
}

class CyberWorld {
  static const int mapWidth = 112;
  static const int mapHeight = 112;

  late List<List<int>> grid;
  final math.Random rng = math.Random(1859);
  final CyberSound sound = CyberSound();
  final MacroVisualsCache visualsCache = MacroVisualsCache();

  // Player Ant / Mounted Bug Vehicle state in 3D World Space
  Vec2 playerPos = const Vec2(56.0, 92.0);
  double playerAngle = -math.pi / 2; // Camera orbit yaw angle (facing North toward the meadow)
  double bodyYaw = -math.pi / 2; // Visual 3D orientation of the Ant / Bug body
  double playerPitch = 0.08; // Slight upward tilt so you see the towering City of Grass canopy!
  double playerZ = 0.0;
  double playerVz = 0.0;
  double walkBobPhase = 0.0;
  double walkBobIntensity = 0.0;
  double mandiblePinchAnim = 0.0;

  // 3rd-Person Camera state
  Vec2 cameraPos = const Vec2(56.0, 93.2);
  double cameraZ = 0.22;
  double cameraOrbitDist = 1.15;

  // Ant Stamina & Hydration & Colony Stores
  double stamina = 100.0;
  double maxStamina = 100.0;
  double hydration = 100.0;
  double maxHydration = 100.0;

  // Currently Mounted Bug Vehicle (null = 3rd-Person On-Foot Red Wood Ant)
  BugVehicleType? mountedVehicle;
  double mountedHealth = 100.0;
  double mountedMaxHealth = 100.0;
  int bugsRiddenCount = 0;
  int bugsDefeatedCount = 0;
  int forageCollected = 0;
  int score = 0;

  // Special Locomotion & Species Attack Burst
  double dashCooldown = 0.0;
  static const double maxDashCooldown = 0.45;
  double dashActiveTimer = 0.0;
  double attackAnim = 0.0;
  double screenShake = 0.0;

  // Open World "City of Grass" Entities
  final List<GrassStalk3D> grassStalks = [];
  final List<MountableBug> mountableBugs = [];
  final List<NpcAnt> npcAnts = [];
  final List<RealLifeProp3D> realLifeProps = [];
  final List<ForageItem> forageItems = [];
  final List<NatureParticle3D> particles = [];
  final List<FloatingNote3D> floatingNotes = [];
  final List<FieldLogEntry> fieldLog = [];

  // Active Colony Mission
  Mission? activeMission;

  int _nextEntityId = 1;
  double totalTime = 0.0;
  double _pollenSpawnTimer = 0.0;

  bool denseFoliage;

  CyberWorld({this.denseFoliage = false}) {
    resetGame();
  }

  void setDenseFoliage(bool enabled) {
    if (denseFoliage == enabled) return;
    denseFoliage = enabled;
    _spawnCityOfGrass();
  }

  BugVehicleSpec? get currentVehicleSpec =>
      mountedVehicle != null ? BugVehicleSpec.of(mountedVehicle!) : null;

  String get currentBiomeName {
    if (playerPos.y >= 74) {
      return 'Emerald Blade Avenue • Anthill Outpost';
    } else if (playerPos.y < 32) {
      return 'Dandelion Crown District';
    } else if (playerPos.x < 48) {
      return 'Clover Canopy Plaza';
    } else if (playerPos.x > 72) {
      return 'Tall Fescue Cathedral';
    } else {
      return 'Meadow Crossroads & Relic Glade';
    }
  }

  void _generateOpenWorldMap() {
    grid = List.generate(mapHeight, (_) => List<int>.filled(mapWidth, 0));

    // Only the distant outer perimeter uses boundary walls; the entire interior is an open 3D City of Grass!
    for (int x = 0; x < mapWidth; x++) {
      grid[0][x] = 1;
      grid[mapHeight - 1][x] = 1;
    }
    for (int y = 0; y < mapHeight; y++) {
      grid[y][0] = 1;
      grid[y][mapWidth - 1] = 1;
    }
  }

  void _spawnCityOfGrass() {
    grassStalks.clear();

    const palettes = <(Color, Color, Color)>[
      // Deep emerald base -> lush chlorophyll mid -> sunlit lime-gold tip
      (Color(0xFF1B3B14), Color(0xFF3E7526), Color(0xFF9AC94B)),
      // Kentucky bluegrass base -> sage-olive mid -> warm wheat tip
      (Color(0xFF163322), Color(0xFF356B43), Color(0xFF8BB858)),
      // Sunlit ryegrass base -> vibrant meadow green -> golden sunlit tip
      (Color(0xFF244216), Color(0xFF52872E), Color(0xFFC4D65A)),
      // Shaded woodland fern-green -> deep moss mid -> Chartreuse tip
      (Color(0xFF142B10), Color(0xFF2F5E21), Color(0xFF7FA83D)),
    ];

    // 1. Create grand "Avenues of Towering Grass" radiating across the expanded 112x112 meadow
    final yStep = denseFoliage ? 1.4 : 4.2;
    final lanes = denseFoliage
        ? const [
            8.0, 14.0, 20.0, 26.0, 32.0, 38.0, 44.0, 50.8,
            61.2, 68.0, 74.0, 80.0, 86.0, 92.0, 98.0, 104.0,
          ]
        : const [14.0, 26.0, 38.0, 50.8, 61.2, 74.0, 86.0, 98.0];

    final spawnOutpost = const Vec2(56.0, 92.0);

    for (double y = 6.0; y <= 106.0; y += yStep) {
      for (final laneX in lanes) {
        final jitterX = (rng.nextDouble() - 0.5) * (denseFoliage ? 1.4 : 1.5);
        final jitterY = (rng.nextDouble() - 0.5) * (denseFoliage ? 1.4 : 1.5);
        final pos = Vec2(laneX + jitterX, y + jitterY);
        // Keep starting outpost spawn clear
        if (pos.distanceTo(spawnOutpost) < 2.2) continue;
        if (pos.distanceTo(const Vec2(28.0, 46.0)) < 2.0) continue;

        final pal = palettes[rng.nextInt(palettes.length)];
        // Arching toward the center of the avenue to form a cathedral ceiling of grass!
        final archTowardCenter = (laneX < 56.0)
            ? (rng.nextDouble() - 0.3) * 0.9
            : math.pi + (rng.nextDouble() - 0.7) * 0.9;

        // Multi-tier height distribution: Ground turf, eye-level brush, and towering canopy
        final heightRoll = rng.nextDouble();
        double stalkHeight;
        double stalkBaseWidth;
        double archReach;
        int subBlades;
        GrassCrownType crown;

        if (heightRoll < 0.32) {
          // Low ground turf & clover undergrowth (ant eye-level)
          stalkHeight = 0.45 + rng.nextDouble() * 0.60;
          stalkBaseWidth = (denseFoliage ? 0.18 : 0.14) + rng.nextDouble() * 0.08;
          archReach = 0.38 + rng.nextDouble() * 0.45;
          subBlades = denseFoliage ? (6 + rng.nextInt(4)) : (4 + rng.nextInt(2));
          crown = (rng.nextDouble() < 0.45)
              ? GrassCrownType.cloverUmbrella
              : GrassCrownType.archingBlade;
        } else if (heightRoll < 0.68) {
          // Mid-story brush & seed panicles
          stalkHeight = 1.10 + rng.nextDouble() * 1.0;
          stalkBaseWidth = (denseFoliage ? 0.16 : 0.13) + rng.nextDouble() * 0.07;
          archReach = 0.60 + rng.nextDouble() * 0.65;
          subBlades = denseFoliage ? (6 + rng.nextInt(3)) : (3 + rng.nextInt(3));
          crown = (rng.nextDouble() < 0.55)
              ? GrassCrownType.seedPanicle
              : GrassCrownType.dewdropBlade;
        } else {
          // Towering cathedral arches
          stalkHeight = 2.10 + rng.nextDouble() * (denseFoliage ? 2.4 : 2.0);
          stalkBaseWidth = (denseFoliage ? 0.15 : 0.12) + rng.nextDouble() * 0.08;
          archReach = (denseFoliage ? 0.85 : 0.65) + rng.nextDouble() * 1.05;
          subBlades = denseFoliage ? (5 + rng.nextInt(3)) : (3 + rng.nextInt(3));
          crown = (rng.nextDouble() < 0.5)
              ? GrassCrownType.archingBlade
              : GrassCrownType.dandelionTower;
        }

        grassStalks.add(GrassStalk3D(
          pos: pos,
          height: stalkHeight,
          baseWidth: stalkBaseWidth,
          archAngle: archTowardCenter,
          archReach: archReach,
          swayPhase: rng.nextDouble() * math.pi * 2,
          baseColor: pal.$1,
          midColor: pal.$2,
          tipColor: pal.$3,
          crownType: crown,
          subBlades: subBlades,
        ));
      }
    }

    // 2. Dense Wild Grass Thickets & Meadow Clusters across the 112x112 open expanse
    final wildCount = denseFoliage ? 1500 : 180;
    for (int i = 0; i < wildCount; i++) {
      final pos = Vec2(
        4.0 + rng.nextDouble() * (mapWidth - 8.0),
        4.0 + rng.nextDouble() * (mapHeight - 8.0),
      );
      if (pos.distanceTo(spawnOutpost) < 2.2) continue;
      if (pos.distanceTo(const Vec2(28.0, 46.0)) < 2.0) continue;

      final pal = palettes[i % palettes.length];
      final heightRoll = rng.nextDouble();
      double stalkHeight;
      double stalkBaseWidth;
      double archReach;
      int subBlades;

      if (heightRoll < 0.38) {
        // Low ground turf
        stalkHeight = 0.40 + rng.nextDouble() * 0.60;
        stalkBaseWidth = (denseFoliage ? 0.18 : 0.14) + rng.nextDouble() * 0.08;
        archReach = 0.35 + rng.nextDouble() * 0.45;
        subBlades = denseFoliage ? (6 + (i % 4)) : (3 + (i % 3));
      } else if (heightRoll < 0.72) {
        // Mid-story grass
        stalkHeight = 1.0 + rng.nextDouble() * 1.05;
        stalkBaseWidth = (denseFoliage ? 0.15 : 0.12) + rng.nextDouble() * 0.07;
        archReach = 0.55 + rng.nextDouble() * 0.65;
        subBlades = denseFoliage ? (5 + (i % 4)) : (3 + (i % 3));
      } else {
        // High towering canopy
        stalkHeight = 2.0 + rng.nextDouble() * 2.2;
        stalkBaseWidth = (denseFoliage ? 0.14 : 0.11) + rng.nextDouble() * 0.08;
        archReach = 0.75 + rng.nextDouble() * 0.95;
        subBlades = denseFoliage ? (5 + (i % 3)) : (3 + (i % 3));
      }

      grassStalks.add(GrassStalk3D(
        pos: pos,
        height: stalkHeight,
        baseWidth: stalkBaseWidth,
        archAngle: rng.nextDouble() * math.pi * 2,
        archReach: archReach,
        swayPhase: rng.nextDouble() * math.pi * 2,
        baseColor: pal.$1,
        midColor: pal.$2,
        tipColor: pal.$3,
        crownType: GrassCrownType.values[i % GrassCrownType.values.length],
        subBlades: subBlades,
      ));
    }
  }

  void _spawnNpcAnts() {
    npcAnts.clear();

    // 1. Commander Khepri (Queen's Vanguard) - Stationed at the starting Anthill Outpost
    npcAnts.add(NpcAnt(
      id: _nextEntityId++,
      name: 'Commander Khepri',
      rank: 'Vanguard Commander',
      title: "Queen's Royal Scout",
      chitinColor: const Color(0xFF1E140C),
      crestColor: const Color(0xFFE88A2D),
      pos: const Vec2(56.0, 89.2),
      angle: math.pi / 2, // Facing South toward player
      missions: [
        Mission(
          id: 'khepri_1',
          title: "The Queen's Cavalry",
          description: 'Approach and mount any wild insect vehicle in the meadow.',
          giverName: 'Commander Khepri',
          type: MissionType.mountBug,
          targetCount: 1,
          scoreReward: 400,
          introDialogue:
              'Salute, sister! The Queen needs mounted riders to scout our expanding borders. Approach one of the great insect beasts of the meadow and mount it!',
          inProgressDialogue:
              'Walk close to any beetle, grasshopper, or hornet, and press MOUNT to take the reins.',
          completionDialogue:
              'Superb horsemanship! The colony sings praises of your mastery over the beasts. Here is your commendation!',
        ),
        Mission(
          id: 'khepri_2',
          title: 'Relic of the Giants',
          description: 'Locate the massive Weathered Copper Penny resting near the southern trail.',
          giverName: 'Commander Khepri',
          type: MissionType.reachLocation,
          targetLocation: const Vec2(53.0, 84.0),
          targetRadius: 4.8,
          targetLocationName: 'Weathered Copper Penny (1989)',
          targetCount: 1,
          scoreReward: 550,
          introDialogue:
              'Scouts report a colossal copper monolith dropped by human giants near our southern trail. Scout the landmark and verify its coordinates!',
          inProgressDialogue:
              'Head slightly northwest into the avenue to find the giant Weathered Copper Penny.',
          completionDialogue:
              'You found the giant disc! Our cartographers have marked the monument. Excellent work, rider!',
        ),
        Mission(
          id: 'khepri_3',
          title: 'Subdue the Wolf Spider',
          description: 'Defeat a Giant Wolf Spider in combat to protect the anthill trails.',
          giverName: 'Commander Khepri',
          type: MissionType.defeatBug,
          targetBug: BugVehicleType.wolfSpider,
          targetCount: 1,
          scoreReward: 850,
          introDialogue:
              'An 8-legged demon prowls the tall grass near our nursery trails! Mount a heavy beetle or strike with venom to drive back a Giant Wolf Spider!',
          inProgressDialogue:
              'Look for the dark chevrons of a Wolf Spider in the grass. Strike it until it retreats!',
          completionDialogue:
              'The spider is driven off! The Queen decorates you as Champion of the Anthill Mound!',
        ),
      ],
    ));

    // 2. Forager Rust (Harvest Overseer) - Stationed in the lush Clover Canopy Plaza
    npcAnts.add(NpcAnt(
      id: _nextEntityId++,
      name: 'Forager Rust',
      rank: 'Harvest Overseer',
      title: 'Master of Provisions',
      chitinColor: const Color(0xFF382312),
      crestColor: const Color(0xFFC9A23E),
      pos: const Vec2(36.0, 74.0),
      angle: 0.0,
      missions: [
        Mission(
          id: 'rust_1',
          title: 'Sweet Dew Harvest',
          description: 'Forage 3 Morning Dewdrops or Golden Honeydews from the grass floor.',
          giverName: 'Forager Rust',
          type: MissionType.forageItem,
          targetCount: 3,
          scoreReward: 450,
          introDialogue:
              'Greetings, sister! The nursery pupae are parched, and our aphid partners need supplies. Venture under the dew-laden blades and gather 3 sweet forage items!',
          inProgressDialogue:
              'Scan the dirt floor for shimmering blue dewdrops or amber honeydew nectar droplets.',
          completionDialogue:
              'Glorious harvest! The nursery chambers will feast tonight thanks to your tireless foraging!',
        ),
        Mission(
          id: 'rust_2',
          title: 'Winter Granary',
          description: 'Collect 2 dense Pine Nut Seeds or Bramble Berries for the winter stores.',
          giverName: 'Forager Rust',
          type: MissionType.forageItem,
          targetCount: 2,
          scoreReward: 600,
          introDialogue:
              'The nursery is refreshed, but cold winds will come. We need dense sustenance for the deep granary. Forage 2 seeds or berries!',
          inProgressDialogue:
              'Search the soil beneath the taller stalks for pine nut seeds and wild berries.',
          completionDialogue:
              'Magnificent! The winter granary swells with rich seed oil. Take your share of the colony nectar!',
        ),
      ],
    ));

    // 3. Warrior Thrak (Mandible Major) - Stationed at the Tall Fescue Cathedral hunting grounds
    npcAnts.add(NpcAnt(
      id: _nextEntityId++,
      name: 'Warrior Thrak',
      rank: 'Mandible Major',
      title: 'Frontline Veteran',
      chitinColor: const Color(0xFF19120F),
      crestColor: const Color(0xFFD43828),
      pos: const Vec2(80.0, 68.0),
      angle: math.pi,
      missions: [
        Mission(
          id: 'thrak_1',
          title: 'Canopy Leap',
          description: 'Mount a Meadow Grasshopper and launch high into the grass canopy.',
          giverName: 'Warrior Thrak',
          type: MissionType.leapAction,
          targetCount: 1,
          scoreReward: 500,
          introDialogue:
              'You think you have strong legs? Mount a Meadow Grasshopper and launch a massive canopy leap into the sky! Feel the wind across your antennae!',
          inProgressDialogue:
              'Find a green Meadow Grasshopper, mount it, and press LEAP while on the ground.',
          completionDialogue:
              'Hah! What a leap! You touched the very tips of the fescue blades. You have the heart of a true warrior!',
        ),
        Mission(
          id: 'thrak_2',
          title: 'Ruler of the Skies',
          description: 'Mount a European Hornet and soar through the 3D meadow canopy.',
          giverName: 'Warrior Thrak',
          type: MissionType.mountBug,
          targetBug: BugVehicleType.hornet,
          targetCount: 1,
          scoreReward: 750,
          introDialogue:
              'The dirt floor is for grubs; the true arena is the open sky! Tame an aerial European Hornet and conquer the third dimension!',
          inProgressDialogue:
              'Look above the fescue avenues for the buzzing yellow wings of a European Hornet.',
          completionDialogue:
              'Incredible! You rode the striped terror of the skies! Even the Wolf Spiders cower beneath your shadow!',
        ),
      ],
    ));

    // 4. Elder Atta (Royal Cartographer) - Stationed near the northern ruins
    npcAnts.add(NpcAnt(
      id: _nextEntityId++,
      name: 'Elder Atta',
      rank: 'Royal Sage',
      title: 'Keeper of the Lore',
      chitinColor: const Color(0xFF332014),
      crestColor: const Color(0xFFE5C07B),
      pos: const Vec2(56.0, 32.0),
      angle: math.pi / 2,
      missions: [
        Mission(
          id: 'atta_1',
          title: 'Northern Expanse',
          description: 'Journey north to the sunny Dandelion Crown District.',
          giverName: 'Elder Atta',
          type: MissionType.reachLocation,
          targetLocation: const Vec2(56.0, 16.0),
          targetRadius: 6.0,
          targetLocationName: 'Dandelion Crown District',
          targetCount: 1,
          scoreReward: 650,
          introDialogue:
              'Few workers ever venture beyond the dark fescue shadows into the north. Journey north to the Dandelion Crown District and gaze upon the sunlit yellow blooms!',
          inProgressDialogue:
              'Keep traveling north past the rainwater puddle toward the horizon haze.',
          completionDialogue:
              'You have walked the high golden plateaus! The colony records your journey in the sacred annals of Formica.',
        ),
        Mission(
          id: 'atta_2',
          title: 'The Brass Shed Key',
          description: 'Locate the ancient Tarnished Brass Shed Key monolith in the northeast.',
          giverName: 'Elder Atta',
          type: MissionType.reachLocation,
          targetLocation: const Vec2(74.0, 36.0),
          targetRadius: 5.0,
          targetLocationName: 'Tarnished Brass Shed Key',
          targetCount: 1,
          scoreReward: 800,
          introDialogue:
              'Legend speaks of a bronze monument carved with cryptic geometric teeth—the Shed Key. Seek out this mythical human relic in the northeast fescue groves!',
          inProgressDialogue:
              'Scout northeast of the crossroads into the tall grass to find the golden metal key.',
          completionDialogue:
              'The ancient Key of the Giants! You have recovered one of the greatest relics in insect history! All hail the Master Explorer!',
        ),
      ],
    ));
  }

  void resetGame() {
    _generateOpenWorldMap();

    playerPos = const Vec2(56.0, 92.0);
    playerAngle = -math.pi / 2;
    bodyYaw = -math.pi / 2;
    playerPitch = 0.08;
    playerZ = 0.0;
    playerVz = 0.0;
    walkBobPhase = 0.0;
    walkBobIntensity = 0.0;
    mandiblePinchAnim = 0.0;

    stamina = 100.0;
    hydration = 100.0;
    mountedVehicle = null;
    mountedHealth = 100.0;
    mountedMaxHealth = 100.0;
    bugsRiddenCount = 0;
    bugsDefeatedCount = 0;
    forageCollected = 0;
    score = 0;

    dashCooldown = 0.0;
    dashActiveTimer = 0.0;
    attackAnim = 0.0;
    screenShake = 0.0;

    activeMission = null;
    npcAnts.clear();
    mountableBugs.clear();
    realLifeProps.clear();
    forageItems.clear();
    particles.clear();
    floatingNotes.clear();
    fieldLog.clear();

    _spawnCityOfGrass();
    _spawnNpcAnts();
    _spawnOpenWorldBugs();
    _spawnRealLifeProps();
    _spawnForageItems();
    _updateThirdPersonCamera(1.0);
  }

  void addFieldLog(String msg, Color color) {
    fieldLog.insert(0, FieldLogEntry(message: msg, color: color));
    if (fieldLog.length > 3) {
      fieldLog.removeLast();
    }
  }

  void _spawnOpenWorldBugs() {
    // Spread bugs generously across the expanded 112x112 City of Grass!
    final initialBugs = <(BugVehicleType, Vec2, double)>[
      // 1. Southern Outpost & Emerald Avenue
      (BugVehicleType.rhinoBeetle, const Vec2(56.0, 85.0), -1.57),
      (BugVehicleType.grasshopper, const Vec2(48.0, 86.0), -2.1),
      (BugVehicleType.stagBeetle, const Vec2(64.0, 86.0), -1.1),
      (BugVehicleType.wolfSpider, const Vec2(56.0, 78.0), 1.57),
      (BugVehicleType.hornet, const Vec2(46.0, 78.0), -0.8),

      // 2. Western Clover Canopy Plaza
      (BugVehicleType.rhinoBeetle, const Vec2(28.0, 72.0), 0.4),
      (BugVehicleType.grasshopper, const Vec2(22.0, 64.0), 2.2),
      (BugVehicleType.stagBeetle, const Vec2(34.0, 58.0), -1.8),
      (BugVehicleType.hornet, const Vec2(26.0, 50.0), 1.2),
      (BugVehicleType.wolfSpider, const Vec2(18.0, 68.0), -0.5),

      // 3. Eastern Tall Fescue Cathedral
      (BugVehicleType.wolfSpider, const Vec2(88.0, 72.0), 3.1),
      (BugVehicleType.stagBeetle, const Vec2(82.0, 58.0), -2.4),
      (BugVehicleType.hornet, const Vec2(92.0, 52.0), -0.9),
      (BugVehicleType.grasshopper, const Vec2(76.0, 52.0), 1.8),
      (BugVehicleType.rhinoBeetle, const Vec2(90.0, 62.0), 0.7),

      // 4. Central Crossroads & Relic Glade
      (BugVehicleType.wolfSpider, const Vec2(56.0, 64.0), -1.57),
      (BugVehicleType.rhinoBeetle, const Vec2(48.0, 50.0), 2.6),
      (BugVehicleType.stagBeetle, const Vec2(64.0, 50.0), -0.6),
      (BugVehicleType.hornet, const Vec2(56.0, 44.0), 0.0),

      // 5. Northern Dandelion Crown District
      (BugVehicleType.hornet, const Vec2(56.0, 20.0), 1.57),
      (BugVehicleType.grasshopper, const Vec2(44.0, 22.0), 0.8),
      (BugVehicleType.stagBeetle, const Vec2(68.0, 22.0), -2.2),
      (BugVehicleType.wolfSpider, const Vec2(56.0, 12.0), -1.57),
      (BugVehicleType.rhinoBeetle, const Vec2(32.0, 16.0), 0.3),
      (BugVehicleType.wolfSpider, const Vec2(80.0, 16.0), 2.7),
    ];

    for (final v in initialBugs) {
      mountableBugs.add(MountableBug(
        id: _nextEntityId++,
        type: v.$1,
        pos: v.$2,
        angle: v.$3,
        walkPhase: rng.nextDouble() * 6.28,
      ));
    }
  }

  void _spawnRealLifeProps() {
    final curatedProps = <RealLifeProp3D>[
      // Southern Avenue Landmark: Weathered Copper Penny
      const RealLifeProp3D(
        pos: Vec2(53.0, 84.0),
        type: RealLifeObjectType.pennyCoin,
        rotation: 0.4,
        scale: 1.15,
        label: 'Weathered Copper Penny (1989)',
      ),
      const RealLifeProp3D(
        pos: Vec2(59.0, 84.5),
        type: RealLifeObjectType.glassMarble,
        rotation: 1.1,
        scale: 1.1,
        label: "Cat's-Eye Glass Marble",
      ),
      const RealLifeProp3D(
        pos: Vec2(56.0, 80.0),
        type: RealLifeObjectType.cloverBlossom,
        rotation: 0.0,
        scale: 1.25,
        label: 'White Dutch Clover (Trifolium repens)',
      ),
      const RealLifeProp3D(
        pos: Vec2(56.0, 74.0),
        type: RealLifeObjectType.bottleCap,
        rotation: 2.2,
        scale: 1.1,
        label: 'Crimped Metal Bottle Cap',
      ),
      // Central Meadow Landmark: Rainwater Puddle
      const RealLifeProp3D(
        pos: Vec2(56.0, 60.0),
        type: RealLifeObjectType.rainPuddle,
        rotation: 0.2,
        scale: 2.2,
        label: 'Rainwater Puddle',
      ),
      const RealLifeProp3D(
        pos: Vec2(40.0, 52.0),
        type: RealLifeObjectType.terracottaShard,
        rotation: 0.8,
        scale: 1.3,
        label: 'Cracked Terracotta Pot Shard',
      ),
      // Northeast Fescue Landmark: Tarnished Brass Shed Key
      const RealLifeProp3D(
        pos: Vec2(74.0, 36.0),
        type: RealLifeObjectType.gardenKey,
        rotation: -0.7,
        scale: 1.35,
        label: 'Tarnished Brass Shed Key',
      ),
      const RealLifeProp3D(
        pos: Vec2(56.0, 42.0),
        type: RealLifeObjectType.glassMarble,
        rotation: 0.3,
        scale: 1.2,
        label: 'Cobalt Swirl Glass Marble',
      ),
      const RealLifeProp3D(
        pos: Vec2(44.0, 24.0),
        type: RealLifeObjectType.pennyCoin,
        rotation: 1.9,
        scale: 1.15,
        label: 'Patina Copper Coin',
      ),
    ];
    realLifeProps.addAll(curatedProps);

    final naturalTypes = [
      (RealLifeObjectType.fallenOakLeaf, 'Fallen Oak Leaf'),
      (RealLifeObjectType.riverPebble, 'Speckled Quartz Pebble'),
      (RealLifeObjectType.cloverBlossom, 'Wild Clover Blossom'),
      (RealLifeObjectType.pineCone, 'Fallen Pine Cone'),
    ];
    for (int i = 0; i < 90; i++) {
      final pos = _findValidOpenPos();
      final entry = naturalTypes[i % naturalTypes.length];
      realLifeProps.add(RealLifeProp3D(
        pos: pos,
        type: entry.$1,
        rotation: rng.nextDouble() * math.pi * 2,
        scale: 0.8 + rng.nextDouble() * 0.55,
        label: entry.$2,
      ));
    }
  }

  void _spawnForageItems() {
    final spots = <(Vec2, ForageType)>[
      // Near starting outpost
      (const Vec2(56.0, 86.0), ForageType.dewdrop),
      (const Vec2(51.0, 81.0), ForageType.honeydewNectar),
      (const Vec2(61.0, 81.0), ForageType.pineSeed),
      // Clover Canopy
      (const Vec2(38.0, 76.0), ForageType.honeydewNectar),
      (const Vec2(32.0, 70.0), ForageType.dewdrop),
      (const Vec2(42.0, 64.0), ForageType.wildBerry),
      // Tall Fescue
      (const Vec2(78.0, 70.0), ForageType.dewdrop),
      (const Vec2(86.0, 64.0), ForageType.honeydewNectar),
      // Central crossroads
      (const Vec2(56.0, 65.0), ForageType.dewdrop),
      (const Vec2(50.0, 52.0), ForageType.pineSeed),
      (const Vec2(62.0, 52.0), ForageType.wildBerry),
      // Northern Dandelion Crown
      (const Vec2(56.0, 36.0), ForageType.honeydewNectar),
      (const Vec2(56.0, 18.0), ForageType.dewdrop),
      (const Vec2(46.0, 16.0), ForageType.wildBerry),
      (const Vec2(66.0, 16.0), ForageType.pineSeed),
      (const Vec2(74.0, 30.0), ForageType.honeydewNectar),
    ];
    for (final s in spots) {
      forageItems.add(ForageItem(
        pos: s.$1,
        type: s.$2,
        shimmerPhase: rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  bool isWallCell(int mx, int my) {
    if (mx < 0 || mx >= mapWidth || my < 0 || my >= mapHeight) return true;
    return grid[my][mx] > 0;
  }

  bool isWallAt(double x, double y, {double radius = 0.28}) {
    final minX = (x - radius).floor();
    final maxX = (x + radius).floor();
    final minY = (y - radius).floor();
    final maxY = (y + radius).floor();
    for (int ty = minY; ty <= maxY; ty++) {
      for (int tx = minX; tx <= maxX; tx++) {
        if (isWallCell(tx, ty)) return true;
      }
    }
    return false;
  }

  /// Returns the closest MountableBug within mounting range (`maxRange = 2.6`)
  MountableBug? findNearbyMountableBug({double maxRange = 2.6}) {
    MountableBug? closest;
    double bestDist = maxRange;
    for (final b in mountableBugs) {
      final d = b.pos.distanceTo(playerPos);
      if (d <= bestDist) {
        bestDist = d;
        closest = b;
      }
    }
    return closest;
  }

  /// Returns the closest Colony NPC Ant within talking range (`maxRange = 2.8`)
  NpcAnt? findNearbyNpcAnt({double maxRange = 2.8}) {
    NpcAnt? closest;
    double bestDist = maxRange;
    for (final npc in npcAnts) {
      final d = npc.pos.distanceTo(playerPos);
      if (d <= bestDist) {
        bestDist = d;
        closest = npc;
      }
    }
    return closest;
  }

  void acceptMission(Mission mission) {
    mission.status = MissionStatus.active;
    activeMission = mission;
    sound.playPickup();
    addFieldLog('Accepted: ${mission.title}', const Color(0xFFD9A74A));
    floatingNotes.add(FloatingNote3D(
      pos: playerPos,
      z: 0.35,
      text: 'Accepted: ${mission.title}',
      color: const Color(0xFFF5E6C8),
    ));
  }

  void claimMissionReward(NpcAnt ant, Mission mission) {
    mission.status = MissionStatus.claimed;
    score += mission.scoreReward;
    stamina = maxStamina;
    hydration = maxHydration;
    sound.playPickup();
    addFieldLog(
      'Completed: ${mission.title} (+${mission.scoreReward} pts)',
      const Color(0xFFA8E07B),
    );
    floatingNotes.add(FloatingNote3D(
      pos: playerPos,
      z: 0.45,
      text: '+${mission.scoreReward} PTS • MISSION COMPLETE!',
      color: const Color(0xFFFFE066),
    ));
    _spawnNatureParticles(playerPos, const Color(0xFFFFD54F), 22);

    ant.activeMissionIndex++;
    if (activeMission?.id == mission.id) {
      activeMission = null;
    }
  }

  void checkMissionProgress(
    MissionType type, {
    BugVehicleType? bugType,
    ForageType? forageType,
    int amount = 1,
  }) {
    if (activeMission == null || activeMission!.status != MissionStatus.active) return;
    final m = activeMission!;
    if (m.type != type) return;

    if (type == MissionType.mountBug && m.targetBug != null && m.targetBug != bugType) {
      return;
    }
    if (type == MissionType.defeatBug && m.targetBug != null && m.targetBug != bugType) {
      return;
    }
    if (type == MissionType.forageItem && m.targetForage != null && m.targetForage != forageType) {
      return;
    }

    m.currentCount += amount;
    if (m.isFinished) {
      m.status = MissionStatus.completed;
      sound.playPickup();
      addFieldLog(
        'Objective Complete: ${m.title}! Return to ${m.giverName}',
        const Color(0xFFA8E07B),
      );
      floatingNotes.add(FloatingNote3D(
        pos: playerPos,
        z: 0.40,
        text: 'OBJECTIVE COMPLETE! Return to ${m.giverName}',
        color: const Color(0xFFA8E07B),
      ));
    }
  }

  void mountBugVehicle(BugVehicleType type, {double? initialHealth}) {
    final spec = BugVehicleSpec.of(type);
    mountedVehicle = type;
    mountedMaxHealth = spec.maxHealth;
    mountedHealth = initialHealth ?? spec.maxHealth;
    playerZ = spec.rideElevation;
    playerVz = 0.0;
    bugsRiddenCount++;
    sound.playPickup();
    _updateThirdPersonCamera(1.0);
    addFieldLog(
      'Mounted ${spec.commonName} (${spec.scientificName})',
      spec.specularHighlight,
    );
    checkMissionProgress(MissionType.mountBug, bugType: type);
  }

  /// Mounts a nearby insect if within range, or dismounts if currently riding one
  void interactOrToggleMount() {
    if (mountedVehicle != null) {
      final oldType = mountedVehicle!;
      final forward = Vec2(math.cos(bodyYaw), math.sin(bodyYaw));
      final parkPos = playerPos - forward * 0.75;

      if (!isWallAt(parkPos.x, parkPos.y, radius: 0.3)) {
        mountableBugs.add(MountableBug(
          id: _nextEntityId++,
          type: oldType,
          pos: parkPos,
          angle: bodyYaw,
          currentHealth: mountedHealth,
        ));
      }

      mountedVehicle = null;
      playerZ = 0.0;
      sound.playDash();
      _updateThirdPersonCamera(1.0);
      return;
    }

    final targetBug = findNearbyMountableBug();
    if (targetBug != null) {
      mountableBugs.remove(targetBug);
      playerPos = targetBug.pos;
      bodyYaw = targetBug.angle;
      mountBugVehicle(targetBug.type, initialHealth: targetBug.health);
      _spawnNatureParticles(playerPos, const Color(0xFFDCE3B8), 12);
      floatingNotes.add(FloatingNote3D(
        pos: playerPos,
        z: 0.35,
        text: 'Mounted ${targetBug.spec.commonName}',
        color: const Color(0xFFF5E6C8),
      ));
    }
  }

  void triggerJumpOrAscend() {
    if (mountedVehicle == BugVehicleType.hornet) {
      if (playerZ < 3.2) {
        playerVz = (playerVz + 2.4).clamp(1.8, 3.8);
      }
      sound.playDash();
      return;
    }
    if (mountedVehicle == BugVehicleType.grasshopper) {
      if (playerZ <= 0.20) {
        playerVz = 4.8;
        sound.playDash();
        _spawnNatureParticles(playerPos, const Color(0xFF8C733E), 10);
        checkMissionProgress(MissionType.leapAction);
      }
      return;
    }
    final groundZ = currentVehicleSpec?.rideElevation ?? 0.0;
    if (playerZ <= groundZ + 0.04) {
      playerVz = 2.6;
      sound.playDash();
    }
  }

  String get currentAttackName =>
      currentVehicleSpec?.attackName ?? 'MANDIBLE BITE';

  /// Performs the active bug's (or Red Wood Ant's) signature attack against nearby bugs
  void triggerSpeciesAbility() {
    if (dashCooldown > 0) return;
    dashCooldown = maxDashCooldown;
    dashActiveTimer = 0.22;
    mandiblePinchAnim = 1.0;
    attackAnim = 1.0;
    sound.playDash();

    final spec = currentVehicleSpec;
    final attackRange = spec?.attackRange ?? 2.35;
    final attackDamage = spec?.attackDamage ?? 25.0;
    final attackLabel = currentAttackName;

    // Slight forward pounce for Wolf Spider or Horn Gore for Rhino Beetle
    if (mountedVehicle == BugVehicleType.wolfSpider) {
      playerVz = 1.4;
    } else if (mountedVehicle == BugVehicleType.rhinoBeetle) {
      screenShake = 0.25;
    }

    final forward = Vec2(math.cos(playerAngle), math.sin(playerAngle));
    final strikeOrigin = playerPos + forward * 0.65;
    _spawnNatureParticles(
      strikeOrigin,
      spec?.specularHighlight ?? const Color(0xFFE86A38),
      10,
    );

    // Check all wild bugs within attack range and arc
    bool hitAny = false;
    for (int i = mountableBugs.length - 1; i >= 0; i--) {
      final target = mountableBugs[i];
      final toTarget = target.pos - playerPos;
      final dist = toTarget.length;
      if (dist <= attackRange) {
        final dir = toTarget.normalized;
        final facingDot = dir.dot(forward);
        // Hit if within front 140-degree cone OR very close (< 1.5 units)
        if (facingDot > -0.25 || dist < 1.55) {
          hitAny = true;
          target.health -= attackDamage;
          target.hitFlashTimer = 0.30;
          target.aggroTimer = 8.0;
          target.angle = math.atan2(-toTarget.y, -toTarget.x);

          // Knockback target bug away from the strike
          final knockPos = target.pos + dir * 0.55;
          if (!isWallAt(knockPos.x, knockPos.y, radius: 0.4)) {
            target.pos = knockPos;
          }

          _spawnNatureParticles(target.pos, const Color(0xFFFF6B4A), 16);
          floatingNotes.add(FloatingNote3D(
            pos: target.pos,
            z: 0.45,
            text: '$attackLabel -${attackDamage.round()} HP',
            color: const Color(0xFFFF8566),
          ));

          if (target.health <= 0) {
            bugsDefeatedCount++;
            score += 300;
            checkMissionProgress(MissionType.defeatBug, bugType: target.type);
            _spawnNatureParticles(target.pos, target.spec.specularHighlight, 26);
            floatingNotes.add(FloatingNote3D(
              pos: target.pos,
              z: 0.65,
              text: 'DEFEATED ${target.spec.commonName.toUpperCase()}!',
              color: const Color(0xFFFFE066),
            ));
            // Drop a forageable reward where the bug was defeated
            forageItems.add(ForageItem(
              pos: target.pos,
              type: ForageType.honeydewNectar,
            ));
            final respawnType = target.type;
            mountableBugs.removeAt(i);
            // Respawn a fresh wild bug in another part of the meadow
            mountableBugs.add(MountableBug(
              id: _nextEntityId++,
              type: respawnType,
              pos: _findValidOpenPos(),
              angle: rng.nextDouble() * math.pi * 2,
            ));
          }
        }
      }
    }

    if (hitAny) {
      screenShake = 0.35;
      sound.playHit();
    }
  }

  void _spawnNatureParticles(Vec2 pos, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final ang = rng.nextDouble() * math.pi * 2;
      final spd = 0.6 + rng.nextDouble() * 2.5;
      particles.add(NatureParticle3D(
        pos: pos,
        vel: Vec2(math.cos(ang) * spd, math.sin(ang) * spd),
        z: (rng.nextDouble() - 0.3) * 0.25,
        vz: 0.4 + rng.nextDouble() * 1.4,
        life: 0.4 + rng.nextDouble() * 0.5,
        color: color,
        size: 0.03 + rng.nextDouble() * 0.04,
      ));
    }
  }

  void _updateThirdPersonCamera(double dt) {
    final desiredDist = currentVehicleSpec?.cameraFollowDist ?? 1.12;
    // Smooth camera zoom when mounting / dismounting bigger bugs
    final zoomT = (dt * 5.5).clamp(0.0, 1.0);
    cameraOrbitDist = cameraOrbitDist + (desiredDist - cameraOrbitDist) * zoomT;

    final backAngle = playerAngle + math.pi;
    final backHit = castRay(playerPos, backAngle);
    final safeDist = math.min(cameraOrbitDist, math.max(0.32, backHit.distance - 0.22));

    cameraPos = Vec2(
      playerPos.x + math.cos(backAngle) * safeDist,
      playerPos.y + math.sin(backAngle) * safeDist,
    );
    final mountElev = mountedVehicle != null ? 0.28 : 0.22;
    // Camera smoothly follows player's 3D altitude so flying insects stay firmly centered in view
    final targetCameraZ = playerZ + mountElev;
    final camZLerp = (dt * 18.0).clamp(0.0, 1.0);
    cameraZ = cameraZ + (targetCameraZ - cameraZ) * camZLerp;
  }

  double _lerpAngle(double current, double target, double t) {
    double diff = (target - current) % (math.pi * 2);
    if (diff > math.pi) diff -= math.pi * 2;
    if (diff < -math.pi) diff += math.pi * 2;
    return current + diff * t.clamp(0.0, 1.0);
  }

  void update(
    double dt, {
    required double moveForward,
    required double moveStrafe,
    required double turnDelta,
    required double pitchDelta,
    required bool sprinting,
    required bool actionPressed,
  }) {
    final clampedDt = dt.clamp(0.001, 0.05);
    totalTime += clampedDt;

    if (dashCooldown > 0) dashCooldown = math.max(0.0, dashCooldown - clampedDt);
    if (dashActiveTimer > 0) dashActiveTimer = math.max(0.0, dashActiveTimer - clampedDt);
    if (screenShake > 0) screenShake = math.max(0.0, screenShake - clampedDt * 2.4);
    if (mandiblePinchAnim > 0) {
      mandiblePinchAnim = math.max(0.0, mandiblePinchAnim - clampedDt * 3.5);
    }
    if (attackAnim > 0) {
      attackAnim = math.max(0.0, attackAnim - clampedDt * 4.2);
    }

    if (!sprinting) {
      stamina = math.min(maxStamina, stamina + clampedDt * 14.0);
    } else {
      stamina = math.max(10.0, stamina - clampedDt * 10.0);
    }

    // Continuous yaw rotation & bounded vertical pitch (-0.68 down to +0.72 up into the grass canopy!)
    playerAngle = (playerAngle + turnDelta) % (math.pi * 2);
    playerPitch = (playerPitch + pitchDelta).clamp(-0.68, 0.72);

    final targetGroundZ = currentVehicleSpec?.rideElevation ?? 0.0;
    if (mountedVehicle == BugVehicleType.hornet) {
      final hoverTarget = 0.42 + math.sin(totalTime * 4.2) * 0.035;
      const maxFlightAltitude = 3.2;
      playerZ = (playerZ + playerVz * clampedDt).clamp(hoverTarget, maxFlightAltitude);
      playerVz -= 4.2 * clampedDt;
      if (playerZ <= hoverTarget) {
        playerZ = hoverTarget;
        playerVz = 0.0;
      }
      if (playerZ >= maxFlightAltitude) {
        playerVz = math.min(0.0, playerVz);
      }
    } else {
      if (playerZ > targetGroundZ || playerVz != 0) {
        playerZ += playerVz * clampedDt;
        playerVz -= 6.8 * clampedDt;
        if (playerZ <= targetGroundZ) {
          playerZ = targetGroundZ;
          playerVz = 0.0;
        }
      } else {
        playerZ = targetGroundZ;
      }
    }

    final forwardVec = Vec2(math.cos(playerAngle), math.sin(playerAngle));
    final rightVec = Vec2(-math.sin(playerAngle), math.cos(playerAngle));
    final inputVec = forwardVec * moveForward + rightVec * moveStrafe;
    final inputMag = inputVec.length;

    double moveSpeed;
    if (mountedVehicle != null) {
      final spec = currentVehicleSpec!;
      moveSpeed = sprinting ? spec.sprintSpeed : spec.moveSpeed;
    } else {
      moveSpeed = sprinting ? 5.8 : 4.1;
    }

    if (dashActiveTimer > 0) {
      moveSpeed = 11.5;
    }

    if (inputMag > 0.08 || dashActiveTimer > 0) {
      final desiredVec = (inputMag > 0.08) ? inputVec : Vec2(math.cos(bodyYaw), math.sin(bodyYaw));
      final desiredHeading = math.atan2(desiredVec.y, desiredVec.x);

      // Insect turns towards desired travel direction
      final turnRate = mountedVehicle != null ? 14.0 : 18.0;
      bodyYaw = _lerpAngle(bodyYaw, desiredHeading, clampedDt * turnRate);

      // Insect scurries forward along its body heading rather than strafing or sliding backward
      var headingDiff = (desiredHeading - bodyYaw) % (math.pi * 2);
      if (headingDiff > math.pi) headingDiff -= math.pi * 2;
      if (headingDiff < -math.pi) headingDiff += math.pi * 2;
      final forwardDrive = math.max(0.25, math.cos(headingDiff));

      final forwardHeading = Vec2(math.cos(bodyYaw), math.sin(bodyYaw));
      final effectiveSpeed = moveSpeed * math.min(1.0, inputMag > 0.08 ? inputMag : 1.0) * forwardDrive;
      final step = forwardHeading * (effectiveSpeed * clampedDt);

      final nextX = playerPos.x + step.x;
      final nextY = playerPos.y + step.y;

      if (!isWallAt(nextX, playerPos.y, radius: 0.28)) {
        playerPos = Vec2(nextX, playerPos.y);
      }
      if (!isWallAt(playerPos.x, nextY, radius: 0.28)) {
        playerPos = Vec2(playerPos.x, nextY);
      }

      walkBobPhase += clampedDt * (sprinting ? 16.0 : 11.0);
      walkBobIntensity = (walkBobIntensity + clampedDt * 6.5).clamp(0.0, 1.0);
    } else {
      // Body preserves facing direction when stationary rather than snapping back to camera yaw
      walkBobIntensity = (walkBobIntensity - clampedDt * 6.0).clamp(0.0, 1.0);
    }

    _updateThirdPersonCamera(clampedDt);

    for (final mb in mountableBugs) {
      if (mb.hitFlashTimer > 0) {
        mb.hitFlashTimer = math.max(0.0, mb.hitFlashTimer - clampedDt);
      }
      if (mb.attackPhase > 0) {
        mb.attackPhase = math.max(0.0, mb.attackPhase - clampedDt * 3.5);
      }
      if (mb.aiAttackCooldown > 0) {
        mb.aiAttackCooldown = math.max(0.0, mb.aiAttackCooldown - clampedDt);
      }
      if (mb.aggroTimer > 0) {
        mb.aggroTimer = math.max(0.0, mb.aggroTimer - clampedDt);
        // Aggroed wild bug turns toward player and counter-attacks if close!
        final toPlayer = playerPos - mb.pos;
        final dist = toPlayer.length;
        mb.angle = _lerpAngle(mb.angle, math.atan2(toPlayer.y, toPlayer.x), clampedDt * 6.0);
        mb.isMoving = dist > 1.35;
        if (dist <= 1.75 && mb.aiAttackCooldown <= 0) {
          mb.aiAttackCooldown = 1.4;
          mb.attackPhase = 1.0;
          final retDmg = (mb.spec.attackDamage * 0.35).roundToDouble();
          screenShake = 0.22;
          _spawnNatureParticles(playerPos, const Color(0xFFFF7A52), 8);
          floatingNotes.add(FloatingNote3D(
            pos: playerPos,
            z: 0.35,
            text: '${mb.spec.attackName} -${retDmg.round()}',
            color: const Color(0xFFFF9E80),
          ));
          if (mountedVehicle != null) {
            mountedHealth = math.max(10.0, mountedHealth - retDmg);
          }
        }
      } else {
        mb.wanderTimer -= clampedDt;
        if (mb.wanderTimer <= 0) {
          mb.wanderTimer = 2.5 + rng.nextDouble() * 3.5;
          mb.isMoving = rng.nextDouble() > 0.25;
          mb.angle += (rng.nextDouble() - 0.5) * 1.2;
        }
      }

      mb.walkPhase += clampedDt * (mb.aggroTimer > 0 ? 9.0 : 5.0);
      if (mb.isMoving) {
        final speed = mb.aggroTimer > 0 ? 1.15 : 0.50;
        final dir = Vec2(math.cos(mb.angle), math.sin(mb.angle));
        final nx = mb.pos.x + dir.x * speed * clampedDt;
        final ny = mb.pos.y + dir.y * speed * clampedDt;
        if (!isWallAt(nx, ny, radius: 0.45)) {
          mb.pos = Vec2(nx, ny);
        } else {
          mb.angle += math.pi * 0.75;
        }
      }
    }

    for (int i = forageItems.length - 1; i >= 0; i--) {
      final item = forageItems[i];
      item.shimmerPhase += clampedDt * 3.0;
      if (item.pos.distanceTo(playerPos) <= 0.78) {
        sound.playPickup();
        forageCollected++;
        score += 150;
        checkMissionProgress(MissionType.forageItem, forageType: item.type);
        stamina = math.min(maxStamina, stamina + 35.0);
        hydration = math.min(maxHydration, hydration + 35.0);
        mandiblePinchAnim = 1.0;

        floatingNotes.add(FloatingNote3D(
          pos: item.pos,
          z: 0.22,
          text: item.label,
          color: item.color,
        ));
        forageItems.removeAt(i);

        if (forageItems.length < 8) {
          forageItems.add(ForageItem(
            pos: _findValidOpenPos(),
            type: ForageType.values[rng.nextInt(ForageType.values.length)],
          ));
        }
      }
    }

    _pollenSpawnTimer -= clampedDt;
    if (_pollenSpawnTimer <= 0 && particles.length < 45) {
      _pollenSpawnTimer = 0.16;
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = 1.2 + rng.nextDouble() * 6.5;
      particles.add(NatureParticle3D(
        pos: playerPos + Vec2(math.cos(angle) * dist, math.sin(angle) * dist),
        vel: Vec2((rng.nextDouble() - 0.5) * 0.3, (rng.nextDouble() - 0.5) * 0.3),
        z: -0.05 + rng.nextDouble() * 1.1,
        vz: 0.04 + rng.nextDouble() * 0.10,
        life: 2.5 + rng.nextDouble() * 2.0,
        color: const Color(0xFFF5E6B8),
        size: 0.025 + rng.nextDouble() * 0.02,
      ));
    }

    for (int i = particles.length - 1; i >= 0; i--) {
      final pt = particles[i];
      pt.life -= clampedDt;
      if (pt.life <= 0) {
        particles.removeAt(i);
        continue;
      }
      pt.pos = pt.pos + pt.vel * clampedDt;
      pt.z += pt.vz * clampedDt;
    }

    for (int i = floatingNotes.length - 1; i >= 0; i--) {
      final fn = floatingNotes[i];
      fn.life -= clampedDt;
      fn.z += clampedDt * 0.25;
      if (fn.life <= 0) {
        floatingNotes.removeAt(i);
      }
    }

    for (int i = fieldLog.length - 1; i >= 0; i--) {
      fieldLog[i].life -= clampedDt;
      if (fieldLog[i].life <= 0) {
        fieldLog.removeAt(i);
      }
    }

    // Check location discovery missions
    if (activeMission != null &&
        activeMission!.status == MissionStatus.active &&
        activeMission!.type == MissionType.reachLocation &&
        activeMission!.targetLocation != null) {
      if (playerPos.distanceTo(activeMission!.targetLocation!) <= activeMission!.targetRadius) {
        activeMission!.currentCount = activeMission!.targetCount;
        activeMission!.status = MissionStatus.completed;
        sound.playPickup();
        addFieldLog(
          'Discovered ${activeMission!.targetLocationName}! Return to ${activeMission!.giverName}',
          const Color(0xFFA8E07B),
        );
        floatingNotes.add(FloatingNote3D(
          pos: playerPos,
          z: 0.40,
          text: 'DISCOVERED ${activeMission!.targetLocationName!.toUpperCase()}!',
          color: const Color(0xFFA8E07B),
        ));
      }
    }

    // Animate Colony NPC Ants
    for (final npc in npcAnts) {
      npc.walkPhase += clampedDt * 2.5;
      npc.antennaeTwitchTimer += clampedDt;
    }
  }

  Vec2 _findValidOpenPos() {
    for (int attempt = 0; attempt < 50; attempt++) {
      final x = 2.0 + rng.nextDouble() * (mapWidth - 4.0);
      final y = 2.0 + rng.nextDouble() * (mapHeight - 4.0);
      if (!isWallAt(x, y, radius: 0.45)) {
        return Vec2(x, y);
      }
    }
    return const Vec2(18.0, 20.0);
  }

  RayHit castRay(Vec2 origin, double rayAngle) {
    final rayDirX = math.cos(rayAngle);
    final rayDirY = math.sin(rayAngle);

    int mapX = origin.x.floor();
    int mapY = origin.y.floor();

    final deltaDistX = rayDirX.abs() < 1e-8 ? 1e30 : (1.0 / rayDirX).abs();
    final deltaDistY = rayDirY.abs() < 1e-8 ? 1e30 : (1.0 / rayDirY).abs();

    int stepX;
    int stepY;
    double sideDistX;
    double sideDistY;

    if (rayDirX < 0) {
      stepX = -1;
      sideDistX = (origin.x - mapX) * deltaDistX;
    } else {
      stepX = 1;
      sideDistX = (mapX + 1.0 - origin.x) * deltaDistX;
    }

    if (rayDirY < 0) {
      stepY = -1;
      sideDistY = (origin.y - mapY) * deltaDistY;
    } else {
      stepY = 1;
      sideDistY = (mapY + 1.0 - origin.y) * deltaDistY;
    }

    bool hitVertical = false;
    int wallType = 1;

    for (int steps = 0; steps < 80; steps++) {
      if (sideDistX < sideDistY) {
        sideDistX += deltaDistX;
        mapX += stepX;
        hitVertical = true;
      } else {
        sideDistY += deltaDistY;
        mapY += stepY;
        hitVertical = false;
      }

      if (mapX < 0 || mapX >= mapWidth || mapY < 0 || mapY >= mapHeight) {
        wallType = 1;
        break;
      }

      // Early break if ray has traveled past maximum visible fog distance (36.0 units)
      final currentDist =
          hitVertical ? (sideDistX - deltaDistX) : (sideDistY - deltaDistY);
      if (currentDist > 36.0) {
        wallType = 1;
        break;
      }

      final cell = grid[mapY][mapX];
      if (cell > 0) {
        wallType = cell;
        break;
      }
    }

    double perpWallDist;
    if (hitVertical) {
      perpWallDist = sideDistX - deltaDistX;
    } else {
      perpWallDist = sideDistY - deltaDistY;
    }
    if (perpWallDist < 0.02) perpWallDist = 0.02;

    double wallX;
    if (hitVertical) {
      wallX = origin.y + perpWallDist * rayDirY;
    } else {
      wallX = origin.x + perpWallDist * rayDirX;
    }
    wallX -= wallX.floor();

    return RayHit(
      distance: perpWallDist,
      wallType: wallType,
      hitVertical: hitVertical,
      wallX: wallX,
      mapX: mapX,
      mapY: mapY,
    );
  }
}
