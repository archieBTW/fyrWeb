import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

class WallpaperStorageService {
  Future<bool> saveWallpaper(String base64Data) {
    final completer = Completer<bool>();
    try {
      final storage = _window['fyrWallpaperStorage'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsStorage = storage as JSObject;
        final jsCallback = ((JSBoolean success) {
          completer.complete(success.toDart);
        }).toJS;
        jsStorage.callMethod('save'.toJS, base64Data.toJS, jsCallback);
      } else {
        completer.complete(false);
      }
    } catch (_) {
      completer.complete(false);
    }
    return completer.future;
  }

  Future<String?> loadWallpaper() {
    final completer = Completer<String?>();
    try {
      final storage = _window['fyrWallpaperStorage'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsStorage = storage as JSObject;
        final jsCallback = ((JSAny? data) {
          if (data != null && data.isA<JSString>()) {
            completer.complete((data as JSString).toDart);
          } else {
            completer.complete(null);
          }
        }).toJS;
        jsStorage.callMethod('load'.toJS, jsCallback);
      } else {
        completer.complete(null);
      }
    } catch (_) {
      completer.complete(null);
    }
    return completer.future;
  }

  Future<bool> clearWallpaper() {
    final completer = Completer<bool>();
    try {
      final storage = _window['fyrWallpaperStorage'];
      if (storage != null && storage.isA<JSObject>()) {
        final jsStorage = storage as JSObject;
        final jsCallback = ((JSBoolean success) {
          completer.complete(success.toDart);
        }).toJS;
        jsStorage.callMethod('clear'.toJS, jsCallback);
      } else {
        completer.complete(false);
      }
    } catch (_) {
      completer.complete(false);
    }
    return completer.future;
  }

  Future<String> compressImage(
    String dataUrl, {
    int maxDim = 1920,
    double quality = 0.85,
  }) {
    final completer = Completer<String>();
    try {
      final compressFn = _window['fyrCompressImage'];
      if (compressFn != null && compressFn.isA<JSFunction>()) {
        final fn = compressFn as JSFunction;
        final jsCallback = ((JSString result) {
          completer.complete(result.toDart);
        }).toJS;
        fn.callAsFunction(
          null,
          dataUrl.toJS,
          maxDim.toJS,
          quality.toJS,
          jsCallback,
        );
      } else {
        completer.complete(dataUrl);
      }
    } catch (_) {
      completer.complete(dataUrl);
    }
    return completer.future;
  }
}
