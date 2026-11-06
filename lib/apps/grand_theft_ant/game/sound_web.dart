import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

class CyberSound {
  bool enabled = true;

  void _callJs(String method) {
    if (!enabled) return;
    try {
      final synth = _window['cyberSynth'];
      if (synth != null && synth.isA<JSObject>()) {
        (synth as JSObject).callMethod(method.toJS);
      }
    } catch (_) {}
  }

  void init() => _callJs('init');
  void playLaser() => _callJs('laser');
  void playShotgun() => _callJs('shotgun');
  void playRailgun() => _callJs('railgun');
  void playHit() => _callJs('hit');
  void playExplosion() => _callJs('explosion');
  void playPickup() => _callJs('pickup');
  void playDash() => _callJs('dash');
  void playPlayerDamage() => _callJs('damage');
}

