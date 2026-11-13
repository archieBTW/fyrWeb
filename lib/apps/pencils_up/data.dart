import 'dart:math' as math;

enum Slot { head, body, weapon, shield }

enum ItemKind { consumable, equipment }

class Item {
  final String id;
  final String name;
  final String desc;
  final ItemKind kind;
  final Slot? slot;
  final int heal;
  final int atk;
  final int def;
  final int spd;
  final int damage; // thrown damage in battle
  const Item(this.id, this.name, this.desc,
      {this.kind = ItemKind.consumable,
      this.slot,
      this.heal = 0,
      this.atk = 0,
      this.def = 0,
      this.spd = 0,
      this.damage = 0});

  bool get isEquip => kind == ItemKind.equipment;

  String get statLine {
    final parts = <String>[];
    if (heal > 0) parts.add('+$heal HP');
    if (damage > 0) parts.add('$damage dmg');
    if (atk != 0) parts.add('ATK ${atk > 0 ? '+' : ''}$atk');
    if (def != 0) parts.add('DEF ${def > 0 ? '+' : ''}$def');
    if (spd != 0) parts.add('SPD ${spd > 0 ? '+' : ''}$spd');
    return parts.join('  ');
  }
}

const _e = ItemKind.equipment;

final Map<String, Item> items = {
  for (final i in const [
    Item('apple', 'Doodle Apple', 'A crunchy sketched apple.', heal: 15),
    Item('cookie', 'Ink Cookie', 'Chocolate chip... or ink blots?', heal: 35),
    Item('juice', 'Juice Box', 'Fully restores your scribbles.', heal: 999),
    Item('tack', 'Thumbtack', 'Throw it at a foe. Ouch!', damage: 18),
    // equipment
    Item('paperhat', 'Paper Hat', 'A folded newspaper hat.', kind: _e, slot: Slot.head, def: 1),
    Item('helmet', 'Thimble Helm', 'Sturdy sewing-kit helmet.', kind: _e, slot: Slot.head, def: 3),
    Item('crown', 'Crayon Crown', 'Royal and waxy.', kind: _e, slot: Slot.head, def: 2, atk: 2, spd: 1),
    Item('scarf', 'Red Scarf', 'Flaps heroically.', kind: _e, slot: Slot.body, def: 1, spd: 2),
    Item('cardboard', 'Cardboard Armor', 'Box-based protection.', kind: _e, slot: Slot.body, def: 4, spd: -1),
    Item('cape', 'Hero Cape', 'Drawn with a blue marker.', kind: _e, slot: Slot.body, def: 3, spd: 2),
    Item('pencil', 'Pencil Sword', 'Sharpened to a fine point.', kind: _e, slot: Slot.weapon, atk: 3),
    Item('ruler', 'Ruler Blade', '30cm of pure justice.', kind: _e, slot: Slot.weapon, atk: 6),
    Item('compass', 'Compass Spear', 'Pointy geometry tool.', kind: _e, slot: Slot.weapon, atk: 9, spd: 1),
    Item('cap', 'Bottlecap Shield', 'Small but shiny.', kind: _e, slot: Slot.shield, def: 2),
    Item('eraser', 'Eraser Shield', 'Rubs out incoming hits.', kind: _e, slot: Slot.shield, def: 4),
  ])
    i.id: i
};

class EnemyType {
  final String id;
  final String name;
  final int hp, atk, def, spd, xp;
  final List<String> drops;
  const EnemyType(this.id, this.name, this.hp, this.atk, this.def, this.spd, this.xp,
      [this.drops = const []]);
}

const enemyTypes = <EnemyType>[
  EnemyType('blob', 'Eraser Blob', 22, 5, 1, 3, 6, ['apple']),
  EnemyType('spider', 'Ink Spider', 28, 7, 2, 7, 9, ['tack', 'cookie']),
  EnemyType('snake', 'Paperclip Snake', 34, 9, 3, 5, 13, ['cookie', 'apple']),
  EnemyType('knight', 'Crayon Knight', 90, 13, 6, 6, 60, ['juice']),
];

class Enemy {
  final EnemyType type;
  final int level;
  late int maxHp, hp, atk, def, spd;
  Enemy(this.type, this.level) {
    maxHp = type.hp + (level - 1) * 5;
    hp = maxHp;
    atk = type.atk + (level - 1) * 2;
    def = type.def + (level - 1);
    spd = type.spd + (level - 1);
  }
}

class Player {
  int level = 1;
  int xp = 0;
  int baseHp = 40, baseAtk = 6, baseDef = 2, baseSpd = 5;
  late int hp = maxHp;
  final Map<Slot, Item?> equipped = {for (final s in Slot.values) s: null};
  final Map<String, int> bag = {'apple': 3, 'tack': 1};

  int get maxHp => baseHp;
  int _sum(int Function(Item) f) =>
      equipped.values.whereType<Item>().fold(0, (a, i) => a + f(i));
  int get atk => baseAtk + _sum((i) => i.atk);
  int get def => baseDef + _sum((i) => i.def);
  int get spd => math.max(1, baseSpd + _sum((i) => i.spd));
  int get xpNext => 20 + (level - 1) * 15;

  void addItem(String id, [int n = 1]) => bag[id] = (bag[id] ?? 0) + n;

  void removeItem(String id) {
    final n = (bag[id] ?? 0) - 1;
    if (n <= 0) {
      bag.remove(id);
    } else {
      bag[id] = n;
    }
  }

  /// Equip item from bag; previous item returns to bag.
  void equip(Item it) {
    final prev = equipped[it.slot!];
    removeItem(it.id);
    if (prev != null) addItem(prev.id);
    equipped[it.slot!] = it;
  }

  void unequip(Slot s) {
    final prev = equipped[s];
    if (prev != null) addItem(prev.id);
    equipped[s] = null;
  }

  /// Returns number of levels gained.
  int gainXp(int amt) {
    xp += amt;
    var gained = 0;
    while (xp >= xpNext) {
      xp -= xpNext;
      level++;
      gained++;
      baseHp += 8;
      baseAtk += 2;
      baseDef += 1;
      baseSpd += 1;
      hp = maxHp;
    }
    return gained;
  }
}

