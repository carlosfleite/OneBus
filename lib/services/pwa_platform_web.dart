import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// True when the page runs in Safari on an iPhone/iPad: the only place
/// where "Add to Home Screen" is the way to install the app.
bool get isIosSafariBrowser {
  final nav = web.window.navigator;
  final ua = nav.userAgent;
  final isIos =
      RegExp(r'iPhone|iPad|iPod').hasMatch(ua) ||
      // iPadOS reports itself as a Mac with a touch screen.
      (nav.platform == 'MacIntel' && nav.maxTouchPoints > 1);
  if (!isIos) return false;
  // Chrome, Firefox, Edge and in-app browsers on iOS can't install PWAs
  // the same way; only plain Safari gets the hint.
  final otherBrowser = RegExp(
    r'CriOS|FxiOS|EdgiOS|OPiOS|GSA|FBAN|FBAV|Instagram',
  ).hasMatch(ua);
  return !otherBrowser;
}

/// True when launched from the home screen icon.
bool get isStandalone {
  try {
    if (web.window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }
    // iOS Safari exposes `navigator.standalone`.
    final standalone = (web.window.navigator as JSObject).getProperty<JSAny?>(
      'standalone'.toJS,
    );
    return standalone.isA<JSBoolean>() && (standalone as JSBoolean).toDart;
  } catch (_) {
    return false;
  }
}

/// Safe-area insets (notch, Dynamic Island, home bar) measured by the page.
/// Flutter web doesn't always forward them as `MediaQuery.padding` on iOS.
({double top, double bottom, double left, double right}) get webSafeInsets {
  try {
    final raw = (web.window as JSObject).getProperty<JSAny?>(
      '__onebusInsets'.toJS,
    );
    if (raw == null || !raw.isA<JSObject>()) {
      return (top: 0, bottom: 0, left: 0, right: 0);
    }
    final o = raw as JSObject;
    double v(String k) {
      final n = o.getProperty<JSAny?>(k.toJS);
      return n.isA<JSNumber>() ? (n as JSNumber).toDartDouble : 0;
    }

    return (top: v('top'), bottom: v('bottom'), left: v('left'), right: v('right'));
  } catch (_) {
    return (top: 0, bottom: 0, left: 0, right: 0);
  }
}
