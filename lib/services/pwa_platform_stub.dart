/// True when the app runs in Safari on an iPhone/iPad (not installed yet).
bool get isIosSafariBrowser => false;

/// True when launched from the home screen icon (standalone display mode).
bool get isStandalone => false;

/// Safe-area insets read from the page (CSS `env(safe-area-inset-*)`).
({double top, double bottom, double left, double right}) get webSafeInsets =>
    (top: 0, bottom: 0, left: 0, right: 0);
