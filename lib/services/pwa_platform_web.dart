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
/// Flutter web doesn't always forward them as `MediaQuery.padding` on iOS,
/// so they are read live from a hidden probe styled with
/// `env(safe-area-inset-*)` (see index.html).
({double top, double bottom, double left, double right}) get webSafeInsets {
  const none = (top: 0.0, bottom: 0.0, left: 0.0, right: 0.0);
  try {
    final probe = web.document.getElementById('safe-probe');
    if (probe == null) return none;
    final style = web.window.getComputedStyle(probe);
    double px(String v) => double.tryParse(v.replaceAll('px', '').trim()) ?? 0;
    var insets = (
      top: px(style.paddingTop),
      bottom: px(style.paddingBottom),
      left: px(style.paddingLeft),
      right: px(style.paddingRight),
    );
    // Installed on iOS the translucent status bar always covers the top of
    // the page. If the browser reported nothing, keep content below it
    // anyway (47 is the usual notch height; smaller phones just get a
    // little extra space).
    if (insets.top == 0 && isIosSafariBrowser && isStandalone) {
      insets = (
        top: 47.0,
        bottom: insets.bottom,
        left: insets.left,
        right: insets.right,
      );
    }
    return insets;
  } catch (_) {
    return none;
  }
}
