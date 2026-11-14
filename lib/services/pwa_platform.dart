// Detects how the app is running (installed PWA or a browser tab) on iOS.
// The web implementation reads the user agent and display mode; every other
// platform gets a stub that reports "not a browser".
export 'pwa_platform_stub.dart'
    if (dart.library.js_interop) 'pwa_platform_web.dart';
