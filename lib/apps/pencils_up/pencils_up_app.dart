import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Colors;
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game.dart';
import 'input.dart';
import 'painters.dart';
import 'sketch.dart';

class PencilsUpApp extends StatelessWidget {
  const PencilsUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Sketch.paper,
        colorScheme: const ColorScheme.light(
          primary: Sketch.graphite,
          secondary: Sketch.yellowPencil,
          surface: Sketch.paper,
        ),
      ),
      child: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final game = Game();
  late final Ticker _ticker;
  final FocusNode _focusNode = FocusNode();
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    game.touchControls = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    game.input.onRebound = () => setState(() {});
    _ticker = createTicker((elapsed) {
      final dt = math.min(0.05, (elapsed - _last).inMicroseconds / 1e6);
      _last = elapsed;
      game.update(dt);
      setState(() {});
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final font = GoogleFonts.patrickHand().fontFamily;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        final handled = game.input.handleKeyEvent(event);
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          game.input.clearKeys();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        child: Scaffold(
          backgroundColor: Sketch.paper,
          body: Listener(
            onPointerDown: (e) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
              if (e.kind == PointerDeviceKind.touch && !game.touchControls) {
                game.touchControls = true;
              }
            },
            child: LayoutBuilder(builder: (context, c) {
              final size = Size(c.maxWidth, c.maxHeight);
              final u = math.min(size.width, size.height) / 360;
              final portrait = size.height > size.width;
              final ui = Ui(u, font, portrait, size);
              final inBattle = game.battle != null;
              final panelH = inBattle ? (portrait ? size.height * 0.38 : size.height * 0.36) : 0.0;
              return Stack(children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: inBattle ? BattlePainter(game, ui.u, font, panelH) : WorldPainter(game),
                  ),
                ),
                if (!inBattle) Positioned(left: 8 * u, top: 8 * u, child: _hud(ui)),
                if (game.touchControls && game.exploring) ..._touchControls(ui),
                if (!game.touchControls && game.exploring)
                  Positioned(
                    right: 8 * u,
                    top: 8 * u,
                    child: Text('Arrows/WASD move · Enter talk · Esc menu',
                        style: ui.text(11, color: Sketch.lightGraphite)),
                  ),
                if (game.menus.isNotEmpty) _menuPanel(ui, inBattle, panelH),
                if (game.dialog.isNotEmpty) _dialogPanel(ui, inBattle, panelH),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ HUD
  Widget _hud(Ui ui) {
    final p = game.player;
    return SketchBox(
      ui: ui,
      seed: 5,
      padding: EdgeInsets.symmetric(horizontal: 10 * ui.u, vertical: 6 * ui.u),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('Doodle  Lv ${p.level}', style: ui.text(14)),
        SizedBox(height: 2 * ui.u),
        SizedBox(
          width: 100 * ui.u,
          height: 10 * ui.u,
          child: CustomPaint(painter: BarPainter(p.hp / p.maxHp, 9)),
        ),
        Text('HP ${p.hp}/${p.maxHp}', style: ui.text(11)),
      ]),
    );
  }

  // --------------------------------------------------------------- touch
  List<Widget> _touchControls(Ui ui) {
    final u = ui.u;
    final jr = 50 * u;
    final pad = 16 * u;
    return [
      Positioned(
        left: pad,
        bottom: pad,
        width: jr * 2.8,
        height: jr * 2.8,
        child: Joystick(input: game.input, radius: jr),
      ),
      Positioned(
        right: pad + 6 * u,
        bottom: pad + 50 * u,
        child: DoodleButton(
            ui: ui, label: 'A', size: 58 * u, onDown: () => _btn(Act.confirm, true), onUp: () => _btn(Act.confirm, false)),
      ),
      Positioned(
        right: pad + 66 * u,
        bottom: pad + 4 * u,
        child: DoodleButton(
            ui: ui, label: 'B', size: 46 * u, onDown: () => _btn(Act.cancel, true), onUp: () => _btn(Act.cancel, false)),
      ),
      Positioned(
        right: 8 * u,
        top: 8 * u,
        child: DoodleButton(
            ui: ui,
            label: 'MENU',
            size: 36 * u,
            wide: true,
            onDown: () => _btn(Act.menu, true),
            onUp: () => _btn(Act.menu, false)),
      ),
    ];
  }

  void _btn(Act a, bool down) {
    if (down) {
      game.input.touchHeld.add(a);
      game.input.touchPress(a);
    } else {
      game.input.touchHeld.remove(a);
    }
  }

  // --------------------------------------------------------------- dialog
  Widget _dialogPanel(Ui ui, bool inBattle, double panelH) {
    final u = ui.u;
    final text = game.dialog.first.text;
    final w = math.min(ui.size.width - 16 * u, 620 * u);
    return Positioned(
      left: (ui.size.width - w) / 2,
      width: w,
      bottom: 10 * u,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => game.advanceDialog(),
        child: SketchBox(
          ui: ui,
          seed: 77,
          padding: EdgeInsets.fromLTRB(16 * u, 12 * u, 16 * u, 12 * u),
          child: SizedBox(
            width: double.infinity,
            height: math.max(64 * u, inBattle ? panelH - 40 * u : 70 * u),
            child: Stack(children: [
              Text(text, style: ui.text(18)),
              Positioned(
                right: 0,
                bottom: 0,
                child: Opacity(
                  opacity: ((game.time * 2).floor() % 2 == 0) ? 1 : 0.3,
                  child: Text('▼', style: ui.text(14)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- menu
  Widget _menuPanel(Ui ui, bool inBattle, double panelH) {
    final u = ui.u;
    final m = game.menus.last;
    final opts = m.build();
    if (opts.isNotEmpty) m.index = m.index.clamp(0, opts.length - 1);
    final size = ui.size;

    final double w, h, left, top;
    if (inBattle) {
      w = math.min(size.width - 16 * u, 620 * u);
      h = panelH - 10 * u;
      left = (size.width - w) / 2;
      top = size.height - h - 10 * u;
    } else {
      w = math.min(size.width - 16 * u, ui.portrait ? 360 * u : 600 * u);
      h = math.min(size.height - 16 * u, ui.portrait ? size.height * 0.86 : 340 * u);
      left = (size.width - w) / 2;
      top = (size.height - h) / 2;
    }

    final showSide = m.preview || m.info != null;
    final sideBySide = !ui.portrait || inBattle;
    final sideH = (m.preview ? 110 * u : 0) + (m.info != null ? 70 * u : 0);

    Widget side() {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        if (m.preview)
          SizedBox(
            width: 110 * u,
            height: 110 * u,
            child: CustomPaint(painter: PreviewPainter(game.player.equipped, game.time)),
          ),
        if (m.info != null)
          Padding(
            padding: EdgeInsets.only(top: 4 * u),
            child: Text(m.info!(), textAlign: TextAlign.center, style: ui.text(14)),
          ),
      ]);
    }

    const rowH = 40.0;
    final reserved = 56 * u + (showSide && !sideBySide ? sideH : 0);
    final maxRows = math.max(2, ((h - reserved) / (rowH * u)).floor());
    var start = 0;
    if (opts.length > maxRows) {
      start = (m.index - maxRows ~/ 2).clamp(0, opts.length - maxRows);
    }
    final visible = opts.length > maxRows ? opts.sublist(start, start + maxRows) : opts;

    final list = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) _optionRow(ui, visible[i], start + i, start + i == m.index, rowH * u),
        if (opts.length > maxRows)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _arrow(ui, '▲', start > 0, () => m.index = math.max(0, m.index - 1)),
            SizedBox(width: 20 * u),
            _arrow(ui, '▼', start + visible.length < opts.length, () => m.index = math.min(opts.length - 1, m.index + 1)),
          ]),
      ],
    );

    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: SketchBox(
        ui: ui,
        seed: 31,
        padding: EdgeInsets.all(10 * u),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.title, style: ui.text(20, bold: true)),
          SizedBox(height: 4 * u),
          Expanded(
            child: ClipRect(
              child: showSide && sideBySide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: list),
                      SizedBox(width: 8 * u),
                      SizedBox(width: 150 * u, child: side()),
                    ])
                  : Column(children: [
                      if (showSide) side(),
                      list,
                    ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _arrow(Ui ui, String s, bool enabled, VoidCallback f) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? f : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * ui.u),
          child: Text(s, style: ui.text(14, color: enabled ? Sketch.graphite : const Color(0x22000000))),
        ),
      );

  Widget _optionRow(Ui ui, MenuOption o, int idx, bool sel, double h) {
    final u = ui.u;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => game.selectOption(idx),
      child: SizedBox(
        height: h,
        child: CustomPaint(
          painter: sel ? HighlightPainter(idx) : null,
          child: Row(children: [
            SizedBox(
              width: 18 * u,
              child: sel ? Text('➜', style: ui.text(16, color: Sketch.redPencil)) : null,
            ),
            if (o.icon != null)
              SizedBox(
                width: 30 * u,
                height: 30 * u,
                child: CustomPaint(painter: IconPainter(o.icon!)),
              ),
            if (o.icon != null) SizedBox(width: 6 * u),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ui.text(17, color: o.enabled ? Sketch.graphite : Sketch.lightGraphite)),
                  if (o.sub != null)
                    Text(o.sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ui.text(11.5, color: Sketch.lightGraphite)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// UI scale helper: [u] is 1/360th of the shorter screen side, so the UI looks
/// the same on a phone in portrait and on a 4K TV.
class Ui {
  final double u;
  final String? font;
  final bool portrait;
  final Size size;
  Ui(this.u, this.font, this.portrait, this.size);

  TextStyle text(double s, {Color color = Sketch.graphite, bool bold = false}) => TextStyle(
        fontFamily: font,
        fontSize: s * u,
        color: color,
        height: 1.15,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      );
}

class SketchBox extends StatelessWidget {
  final Ui ui;
  final int seed;
  final Widget child;
  final EdgeInsets padding;
  const SketchBox({super.key, required this.ui, required this.seed, required this.child, required this.padding});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: PaperBoxPainter(seed, ui.u),
        child: Padding(padding: padding, child: child),
      );
}

class Joystick extends StatefulWidget {
  final InputManager input;
  final double radius;
  const Joystick({super.key, required this.input, required this.radius});
  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset knob = Offset.zero;
  int? pointer;
  InputManager? _input;

  void _set(Offset local, Size size) {
    final c = size.center(Offset.zero);
    var d = local - c;
    if (d.distance > widget.radius) d = d / d.distance * widget.radius;
    knob = d;
    widget.input.joystick = d / widget.radius;
  }

  void _end() {
    pointer = null;
    knob = Offset.zero;
    widget.input.joystick = Offset.zero;
  }

  @override
  void initState() {
    super.initState();
    _input = widget.input;
  }

  @override
  void dispose() {
    _input?.joystick = Offset.zero;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          pointer ??= e.pointer;
          if (pointer == e.pointer) setState(() => _set(e.localPosition, size));
        },
        onPointerMove: (e) {
          if (pointer == e.pointer) setState(() => _set(e.localPosition, size));
        },
        onPointerUp: (e) {
          if (pointer == e.pointer) setState(_end);
        },
        onPointerCancel: (e) {
          if (pointer == e.pointer) setState(_end);
        },
        child: CustomPaint(painter: JoystickPainter(knob, widget.radius)),
      );
    });
  }
}

class DoodleButton extends StatefulWidget {
  final Ui ui;
  final String label;
  final double size;
  final bool wide;
  final VoidCallback onDown, onUp;
  const DoodleButton(
      {super.key,
      required this.ui,
      required this.label,
      required this.size,
      required this.onDown,
      required this.onUp,
      this.wide = false});
  @override
  State<DoodleButton> createState() => _DoodleButtonState();
}

class _DoodleButtonState extends State<DoodleButton> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final w = widget.wide ? widget.size * 2.2 : widget.size;
    return Listener(
      onPointerDown: (_) {
        setState(() => down = true);
        widget.onDown();
      },
      onPointerUp: (_) {
        setState(() => down = false);
        widget.onUp();
      },
      onPointerCancel: (_) {
        setState(() => down = false);
        widget.onUp();
      },
      child: SizedBox(
        width: w,
        height: widget.size,
        child: CustomPaint(
          painter: ButtonPainter(down, widget.wide, widget.label.hashCode),
          child: Center(
            child: Text(widget.label,
                style: widget.ui.text(widget.wide ? 15 : widget.size / widget.ui.u * 0.42, bold: true)),
          ),
        ),
      ),
    );
  }
}

