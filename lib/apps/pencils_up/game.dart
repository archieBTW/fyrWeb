import 'dart:math' as math;
import 'dart:ui' show VoidCallback;

import 'data.dart';
import 'draw.dart';
import 'input.dart';
import 'world.dart';


class Msg {
  final String text;
  final VoidCallback? effect;
  Msg(this.text, [this.effect]);
}

class MenuOption {
  final String label;
  final String? sub;
  final String? icon;
  final bool enabled;
  final VoidCallback onSelect;
  MenuOption(this.label, this.onSelect, {this.sub, this.icon, this.enabled = true});
}

class MenuPage {
  final String title;
  final List<MenuOption> Function() build;
  final VoidCallback? onCancel;
  final bool preview; // show the doodle equipment preview
  final String Function()? info;
  int index = 0;
  MenuPage(this.title, this.build, {this.onCancel, this.preview = false, this.info});
}

class FloatText {
  final String text;
  final bool onEnemy;
  final bool heal;
  double t = 0;
  FloatText(this.text, this.onEnemy, {this.heal = false});
}

class Battle {
  final Enemy enemy;
  final bool boss;
  double enemyShake = 0, playerShake = 0, lunge = 0, enemyLunge = 0;
  double enemyFade = 0;
  bool enemyDead = false;
  double intro = 0;
  final floats = <FloatText>[];
  Battle(this.enemy, this.boss);
}

class _Sim {
  int eHp, pHp;
  bool fled = false;
  _Sim(this.eHp, this.pHp);
}

class Game {
  final input = InputManager();
  final player = Player();
  final rng = math.Random();

  late List<List<String>> grid;
  late int mapW, mapH;
  late int startX, startY;
  int px = 0, py = 0, fromX = 0, fromY = 0;
  double moveT = 1; // 0..1 progress between tiles
  bool moving = false;
  Facing facing = Facing.down;
  double walk = 0;
  final chestItems = <String, String>{};
  final signs = <String, String>{};
  final opened = <String>{};
  int stepsSafe = 0;
  bool bossDefeated = false;
  bool touchControls = false;
  double time = 0;

  final dialog = <Msg>[];
  VoidCallback? _dialogDone;
  final menus = <MenuPage>[];
  Battle? battle;

  Game() {
    mapW = mapRows.map((r) => r.length).reduce(math.max);
    mapH = mapRows.length;
    grid = [
      for (var y = 0; y < mapH; y++)
        [for (var x = 0; x < mapW; x++) x < mapRows[y].length ? mapRows[y][x] : '.']
    ];
    // borders
    for (var y = 0; y < mapH; y++) {
      for (var x = 0; x < mapW; x++) {
        if (x == 0 || y == 0 || x == mapW - 1 || y == mapH - 1) grid[y][x] = '#';
      }
    }
    var ci = 0, si = 0;
    for (var y = 0; y < mapH; y++) {
      for (var x = 0; x < mapW; x++) {
        final t = grid[y][x];
        if (t == 'P') {
          startX = px = fromX = x;
          startY = py = fromY = y;
          grid[y][x] = '=';
        } else if (t == 'C') {
          chestItems['$x,$y'] = chestLoot[ci++ % chestLoot.length];
        } else if (t == 'S') {
          signs['$x,$y'] = signTexts[si++ % signTexts.length];
        }
      }
    }
    say([
      Msg('*scribble scribble*  ...You have been drawn into existence!'),
      Msg('Explore the page, open chests for gear, and beware the tall grass.'),
    ]);
  }

  String tile(int x, int y) => (x < 0 || y < 0 || x >= mapW || y >= mapH) ? '#' : grid[y][x];

  /// Player position in tile units (fractional while walking).
  double get posX => fromX + (px - fromX) * moveT;
  double get posY => fromY + (py - fromY) * moveT;

  bool get exploring => dialog.isEmpty && menus.isEmpty && battle == null;

  // ---------------------------------------------------------------- dialog
  void say(List<Msg> msgs, [VoidCallback? then]) {
    final wasEmpty = dialog.isEmpty;
    dialog.addAll(msgs);
    _dialogDone = then;
    if (wasEmpty && dialog.isNotEmpty) dialog.first.effect?.call();
  }

  void advanceDialog() {
    if (dialog.isEmpty) return;
    dialog.removeAt(0);
    if (dialog.isNotEmpty) {
      dialog.first.effect?.call();
    } else {
      final d = _dialogDone;
      _dialogDone = null;
      d?.call();
    }
  }

  /// Insert messages right after the current one (used by effects).
  void insertNext(List<Msg> msgs) => dialog.insertAll(math.min(1, dialog.length), msgs);

  // ---------------------------------------------------------------- update
  void update(double dt) {
    time += dt;
    input.update(dt);
    for (final a in input.pressed) {
      _handle(a);
    }
    if (exploring) _explore(dt);
    final b = battle;
    if (b != null) {
      b.intro = math.min(1, b.intro + dt * 2);
      b.enemyShake = math.max(0, b.enemyShake - dt * 2.5);
      b.playerShake = math.max(0, b.playerShake - dt * 2.5);
      b.lunge = math.max(0, b.lunge - dt * 3);
      b.enemyLunge = math.max(0, b.enemyLunge - dt * 3);
      if (b.enemyDead) b.enemyFade = math.min(1, b.enemyFade + dt * 1.5);
      for (final f in b.floats) {
        f.t += dt;
      }
      b.floats.removeWhere((f) => f.t > 1.2);
    }
  }

  void _handle(Act a) {
    if (input.rebindAct != null) return;
    if (dialog.isNotEmpty) {
      if (a == Act.confirm || a == Act.cancel) advanceDialog();
      return;
    }
    if (menus.isNotEmpty) {
      final m = menus.last;
      final opts = m.build();
      if (opts.isEmpty) {
        if (a == Act.cancel || a == Act.confirm || a == Act.menu) _cancelMenu();
        return;
      }
      m.index = m.index.clamp(0, opts.length - 1);
      switch (a) {
        case Act.up:
          m.index = (m.index - 1 + opts.length) % opts.length;
        case Act.down:
          m.index = (m.index + 1) % opts.length;
        case Act.confirm:
          selectOption(m.index);
        case Act.cancel:
          _cancelMenu();
        case Act.menu:
          if (battle == null) menus.clear();
        default:
      }
      return;
    }
    if (exploring) {
      if (a == Act.confirm) _interact();
      if (a == Act.menu) openPauseMenu();
    }
  }

  void selectOption(int i) {
    if (menus.isEmpty) return;
    final m = menus.last;
    final opts = m.build();
    if (i < 0 || i >= opts.length) return;
    m.index = i;
    if (opts[i].enabled) opts[i].onSelect();
  }

  void _cancelMenu() {
    final m = menus.last;
    if (m.onCancel != null) {
      m.onCancel!();
    } else {
      menus.removeLast();
    }
  }

  void popMenu() {
    if (menus.isNotEmpty) menus.removeLast();
  }

  // --------------------------------------------------------------- explore
  void _explore(double dt) {
    if (moving) {
      moveT += dt * 4.2;
      walk += dt * 2.1;
      if (moveT >= 1) {
        moveT = 1;
        moving = false;
        fromX = px;
        fromY = py;
        _onStep();
        if (!exploring) return;
      } else {
        return;
      }
    }
    final v = input.move;
    if (v.dx == 0 && v.dy == 0) {
      walk = 0;
      return;
    }
    Facing? f;
    if (v.dx != 0 && v.dy != 0) {
      // keep moving along current axis if possible
      f = (facing == Facing.left || facing == Facing.right)
          ? (v.dx < 0 ? Facing.left : Facing.right)
          : (v.dy < 0 ? Facing.up : Facing.down);
    } else if (v.dx != 0) {
      f = v.dx < 0 ? Facing.left : Facing.right;
    } else {
      f = v.dy < 0 ? Facing.up : Facing.down;
    }
    facing = f;
    final (dx, dy) = _dir(f);
    if (!isSolid(tile(px + dx, py + dy))) {
      fromX = px;
      fromY = py;
      px += dx;
      py += dy;
      moveT = 0;
      moving = true;
    } else {
      walk = 0;
    }
  }

  (int, int) _dir(Facing f) => switch (f) {
        Facing.up => (0, -1),
        Facing.down => (0, 1),
        Facing.left => (-1, 0),
        Facing.right => (1, 0),
      };

  void _onStep() {
    if (tile(px, py) == '"') {
      stepsSafe++;
      if (stepsSafe > 2 && rng.nextDouble() < 0.13) {
        stepsSafe = 0;
        final south = py >= 14;
        final pool = south ? ['spider', 'snake', 'snake'] : ['blob', 'blob', 'spider'];
        final type = enemyTypes.firstWhere((e) => e.id == pool[rng.nextInt(pool.length)]);
        final lvl = math.max(1, (south ? 3 : 1) + rng.nextInt(2) + (player.level - 2) ~/ 2);
        startBattle(Enemy(type, lvl), false);
      }
    }
  }

  void _interact() {
    final (dx, dy) = _dir(facing);
    final tx = px + dx, ty = py + dy;
    final t = tile(tx, ty);
    final key = '$tx,$ty';
    switch (t) {
      case 'C':
        if (opened.contains(key)) {
          say([Msg('The chest is empty. Just eraser crumbs.')]);
        } else {
          opened.add(key);
          final it = items[chestItems[key]]!;
          player.addItem(it.id);
          say([
            Msg('You opened the chest... found ${it.name}!'),
            if (it.isEquip) Msg('Open the MENU > Gear to equip it.'),
          ]);
        }
      case 'S':
        say([Msg('The sign reads: "${signs[key]}"')]);
      case 'N':
        say([
          Msg('Sharpener Sam: "Whoa, you look a bit smudged! Let me sharpen you up."'),
          Msg('Your HP was fully restored!', () => player.hp = player.maxHp),
          Msg('Sharpener Sam: "The Crayon Knight lurks in the fenced arena down south. Be careful!"'),
        ]);
      case 'B':
        say([
          Msg('Crayon Knight: "Who dares scribble in MY margins?!"'),
        ], () => startBattle(Enemy(enemyTypes.last, 5), true));
      case 'H':
        say([Msg('Sam\'s house. The door is drawn shut.')]);
      case '~':
        say([Msg('Blue pencil water. Looks wet... ish.')]);
    }
  }

  // ------------------------------------------------------------ pause menu
  void openPauseMenu() {
    menus.add(MenuPage('PAUSED', () => [
          MenuOption('Items', () => menus.add(itemsPage(false)), icon: 'apple', sub: 'Use healing snacks'),
          MenuOption('Gear', () => menus.add(gearPage(false)), icon: 'pencil', sub: 'Equip clothes, armor & weapons'),
          MenuOption('Stats', () => menus.add(statsPage()), sub: 'Lv ${player.level}  HP ${player.hp}/${player.maxHp}'),
          MenuOption('Controls', () => menus.add(controlsPage()), sub: 'Remap keys & controller'),
          MenuOption('Close', popMenu),
        ], preview: true));
  }

  MenuPage itemsPage(bool inBattle) => MenuPage('ITEMS', () {
        final opts = <MenuOption>[];
        for (final e in player.bag.entries) {
          final it = items[e.key]!;
          if (it.isEquip) continue;
          opts.add(MenuOption('${it.name}  x${e.value}', () => useItem(it, inBattle),
              sub: '${it.desc}  ${it.statLine}', icon: it.id));
        }
        if (opts.isEmpty) opts.add(MenuOption('(No items)', () {}, enabled: false));
        opts.add(MenuOption('Back', popMenu));
        return opts;
      });

  void useItem(Item it, bool inBattle) {
    if (it.damage > 0) {
      if (!inBattle) {
        say([Msg('Better save that ${it.name} for battle!')]);
        return;
      }
      player.removeItem(it.id);
      menus.clear();
      _turn((sim) {
        final d = it.damage + rng.nextInt(5);
        sim.eHp -= d;
        return [
          Msg('You throw the ${it.name}! $d damage!', () {
            battle!.lunge = 1;
            _hitEnemy(d);
          })
        ];
      }, false);
      return;
    }
    if (player.hp >= player.maxHp) {
      say([Msg('Your HP is already full!')]);
      return;
    }
    player.removeItem(it.id);
    if (!inBattle) {
      final before = player.hp;
      player.hp = math.min(player.maxHp, player.hp + it.heal);
      say([Msg('You ate the ${it.name}. Restored ${player.hp - before} HP!')]);
      return;
    }
    menus.clear();
    _turn((sim) {
      final amt = math.min(player.maxHp - sim.pHp, it.heal);
      sim.pHp += amt;
      return [
        Msg('You used the ${it.name}! Restored $amt HP.', () {
          player.hp = math.min(player.maxHp, player.hp + amt);
          battle!.floats.add(FloatText('+$amt', false, heal: true));
        })
      ];
    }, false);
  }

  static const slotNames = {Slot.head: 'Head', Slot.body: 'Body', Slot.weapon: 'Weapon', Slot.shield: 'Shield'};

  MenuPage gearPage(bool inBattle) => MenuPage('GEAR', () {
        return [
          for (final s in Slot.values)
            MenuOption('${slotNames[s]}: ${player.equipped[s]?.name ?? '-'}', () => menus.add(slotPage(s, inBattle)),
                sub: player.equipped[s]?.statLine ?? 'Nothing equipped', icon: player.equipped[s]?.id),
          MenuOption('Back', popMenu),
        ];
      }, preview: true, info: () => 'ATK ${player.atk}   DEF ${player.def}   SPD ${player.spd}');

  MenuPage slotPage(Slot s, bool inBattle) => MenuPage(slotNames[s]!.toUpperCase(), () {
        final opts = <MenuOption>[];
        for (final id in player.bag.keys) {
          final it = items[id]!;
          if (it.slot != s) continue;
          opts.add(MenuOption(it.name, () => _equip(() => player.equip(it), 'You equipped the ${it.name}!', inBattle),
              sub: '${it.desc}  ${it.statLine}', icon: it.id));
        }
        if (player.equipped[s] != null) {
          opts.add(MenuOption('Remove ${player.equipped[s]!.name}',
              () => _equip(() => player.unequip(s), 'You took it off.', inBattle)));
        }
        if (opts.isEmpty) opts.add(MenuOption('(Nothing to equip)', () {}, enabled: false));
        opts.add(MenuOption('Back', popMenu));
        return opts;
      }, preview: true, info: () => 'ATK ${player.atk}   DEF ${player.def}   SPD ${player.spd}');

  void _equip(VoidCallback act, String text, bool inBattle) {
    if (!inBattle) {
      act();
      popMenu();
      return;
    }
    menus.clear();
    _turn((sim) => [Msg(text, act)], false);
  }

  MenuPage statsPage() => MenuPage('STATS', () => [MenuOption('Back', popMenu)],
      preview: true,
      info: () => 'Level ${player.level}\n'
          'HP ${player.hp} / ${player.maxHp}\n'
          'XP ${player.xp} / ${player.xpNext}\n'
          'ATK ${player.atk}   DEF ${player.def}   SPD ${player.spd}');

  MenuPage controlsPage() => MenuPage('CONTROLS', () {
        String waiting(Act a, bool pad) => input.rebindAct == a && input.rebindPad == pad ? '  > press...' : '';
        return [
          for (final a in Act.values)
            MenuOption('Key  ${actNames[a]}', () => _rebind(a, false),
                sub: input.keyLabel(a) + waiting(a, false)),
          for (final a in Act.values)
            MenuOption('Pad  ${actNames[a]}', () => _rebind(a, true),
                sub: input.padLabel(a) + waiting(a, true)),
          MenuOption('Touch controls: ${touchControls ? 'ON' : 'OFF'}', () => touchControls = !touchControls),
          MenuOption('Reset to defaults', () => input.saveDefaults()),
          MenuOption('Back', popMenu),
        ];
      },
          info: () => input.rebindAct != null
              ? (input.rebindPad ? 'Press a controller button...' : 'Press a key...')
              : 'Controller: ${input.padConnected ? 'connected' : 'not detected (press a button)'}');

  void _rebind(Act a, bool pad) {
    input.rebindPad = pad;
    input.rebindAct = a;
  }

  // ---------------------------------------------------------------- battle
  void startBattle(Enemy e, bool boss) {
    battle = Battle(e, boss);
    menus.clear();
    say([Msg(boss ? 'The ${e.type.name} draws its sword!' : 'A wild ${e.type.name} (Lv ${e.level}) scribbles into view!')],
        _battleMenu);
  }

  void _battleMenu() {
    final b = battle;
    if (b == null) return;
    menus.add(MenuPage('What will you do?', () => [
          MenuOption('Fight', () {
            menus.clear();
            _turn(_playerAttack, true);
          }, sub: 'Attack with ${player.equipped[Slot.weapon]?.name ?? 'your fists'}'),
          MenuOption('Items', () => menus.add(itemsPage(true)), sub: 'Uses your turn'),
          MenuOption('Gear', () => menus.add(gearPage(true)), sub: 'Swap equipment (uses turn)'),
          MenuOption('Run', () {
            menus.clear();
            _turn((sim) {
              if (b.boss) return [Msg('You can\'t run from the Crayon Knight!')];
              if (rng.nextDouble() < 0.7) {
                sim.fled = true;
                return [Msg('You scurried off the page safely!')];
              }
              return [Msg('Couldn\'t get away!')];
            }, false);
          }),
        ], onCancel: () {}));
  }

  int _damage(int atk, int def) {
    final base = atk * (0.9 + rng.nextDouble() * 0.3) - def * 0.6;
    return math.max(1, base.round());
  }

  List<Msg> _playerAttack(_Sim sim) {
    final e = battle!.enemy;
    var d = _damage(player.atk, e.def);
    final crit = rng.nextDouble() < 0.1;
    if (crit) d = (d * 1.6).round();
    sim.eHp -= d;
    final w = player.equipped[Slot.weapon];
    final verb = w == null ? 'You bonk the ${e.type.name}!' : 'You strike with the ${w.name}!';
    return [
      Msg('$verb ${crit ? 'Critical hit! ' : ''}$d damage!', () {
        battle!.lunge = 1;
        _hitEnemy(d);
      })
    ];
  }

  List<Msg> _enemyAttack(_Sim sim) {
    final e = battle!.enemy;
    var mult = 1.0;
    var name = 'attacks';
    final r = rng.nextDouble();
    switch (e.type.id) {
      case 'blob':
        name = r < 0.3 ? 'smudges you' : 'bounces into you';
      case 'spider':
        if (r < 0.3) {
          name = 'spits ink';
          mult = 1.3;
        } else {
          name = 'bites';
        }
      case 'snake':
        name = r < 0.4 ? 'wraps around you' : 'pokes you';
        if (r < 0.4) mult = 1.2;
      case 'knight':
        if (r < 0.3) {
          name = 'unleashes a WAXY SLASH';
          mult = 1.6;
        } else {
          name = 'swings its sword';
        }
    }
    final d = math.max(1, (_damage(e.atk, player.def) * mult).round());
    sim.pHp -= d;
    return [
      Msg('${e.type.name} $name! $d damage!', () {
        battle!.enemyLunge = 1;
        battle!.playerShake = 1;
        player.hp = math.max(0, player.hp - d);
        battle!.floats.add(FloatText('-$d', false));
      })
    ];
  }

  void _hitEnemy(int d) {
    final b = battle!;
    b.enemy.hp = math.max(0, b.enemy.hp - d);
    b.enemyShake = 1;
    b.floats.add(FloatText('-$d', true));
  }

  void _turn(List<Msg> Function(_Sim) playerPart, bool speedOrder) {
    final b = battle!;
    final e = b.enemy;
    final sim = _Sim(e.hp, player.hp);
    final msgs = <Msg>[];
    final enemyFirst = speedOrder && e.spd > player.spd;
    var over = false;

    void enemy() {
      msgs.addAll(_enemyAttack(sim));
      if (sim.pHp <= 0) {
        over = true;
        msgs.addAll(_defeatMsgs());
      }
    }

    if (enemyFirst) enemy();
    if (!over) {
      msgs.addAll(playerPart(sim));
      if (sim.fled) {
        over = true;
        msgs.add(Msg('', () {
          battle = null;
          dialog.clear();
        }));
      } else if (sim.eHp <= 0) {
        over = true;
        msgs.addAll(_victoryMsgs());
      } else if (!enemyFirst) {
        enemy();
      }
    }
    say(msgs.where((m) => m.text.isNotEmpty || m.effect != null).toList(), over ? null : _battleMenu);
    // handle the "flee" sentinel: an empty message ends the battle immediately once shown
    if (dialog.isNotEmpty && dialog.first.text.isEmpty) advanceDialog();
  }

  List<Msg> _victoryMsgs() {
    final b = battle!;
    final e = b.enemy;
    final xp = e.type.xp * e.level;
    return [
      Msg('The ${e.type.name} was erased!', () => b.enemyDead = true),
      Msg('You gained $xp XP!', () {
        final lv = player.gainXp(xp);
        final extra = <Msg>[];
        if (lv > 0) extra.add(Msg('Level up! You are now Lv ${player.level}. Stats increased & HP restored!'));
        if (b.boss) {
          player.addItem('crown');
          player.addItem('compass');
          extra.add(Msg('The Crayon Knight dropped the Crayon Crown and a Compass Spear!'));
          extra.add(Msg('You are the champion of the page! Thanks for playing Pencils Up!'));
        } else if (rng.nextDouble() < 0.5 && e.type.drops.isNotEmpty) {
          final id = e.type.drops[rng.nextInt(e.type.drops.length)];
          player.addItem(id);
          extra.add(Msg('It dropped a ${items[id]!.name}!'));
        }
        insertNext(extra);
      }),
      Msg('', () {
        if (b.boss) {
          bossDefeated = true;
          for (var y = 0; y < mapH; y++) {
            for (var x = 0; x < mapW; x++) {
              if (grid[y][x] == 'B') grid[y][x] = '.';
            }
          }
        }
        battle = null;
        dialog.clear();
      }),
    ];
  }

  List<Msg> _defeatMsgs() => [
        Msg('You got erased...'),
        Msg('...but someone redraws you back in Pencil Town.', () {
          battle = null;
          player.hp = player.maxHp;
          px = fromX = startX;
          py = fromY = startY;
          moveT = 1;
          moving = false;
          facing = Facing.down;
        }),
      ];

  void dispose() => input.dispose();
}

