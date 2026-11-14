import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import 'auth_errors.dart';
import 'password_rules.dart';

/// Result of a sign-up attempt.
typedef SignUpResult = ({String? error, bool needsConfirmation});

/// Session and account of the user.
///
/// Two backends share this API:
///  * **Supabase Auth**, used when `SUPABASE_URL` and `SUPABASE_ANON_KEY`
///    are provided at build time (see [AppConfig]). It sends the
///    confirmation and password-recovery e-mails.
///  * a **local account** kept on the device (salted SHA-256 hash, never
///    plain text), used when Supabase is not configured: development, tests
///    and the offline demo. It has no e-mail features.
class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final instance = AuthStore._();

  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';
  static const _saltKey = 'auth_salt';
  static const _hashKey = 'auth_hash';
  static const _sessionKey = 'auth_logged_in';

  static const recoveryUnavailable =
      'A recuperação por e-mail precisa de uma conta online. '
      'Nesta versão a conta fica salva só neste aparelho.';

  String? name;
  String? email;
  String? _salt;
  String? _hash;
  bool loggedIn = false;

  bool _backendReady = false;
  StreamSubscription<AuthState>? _authSub;

  /// True after the user opened the password-recovery link from the e-mail.
  final recoveryPending = ValueNotifier<bool>(false);

  /// Whether the Supabase backend is active.
  bool get usesBackend => _backendReady;

  bool get hasAccount =>
      usesBackend ? email != null : (email != null && _hash != null);

  String get firstName => (name ?? '').trim().split(RegExp(r'\s+')).first;

  String get initial {
    final base = firstName.isNotEmpty ? firstName : (email ?? '');
    return base.isEmpty ? '?' : base.substring(0, 1).toUpperCase();
  }

  /// Starts Supabase when it is configured. Safe to call when it is not.
  Future<void> initBackend() async {
    if (!AppConfig.hasSupabase || _backendReady) return;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        // The implicit flow puts the tokens in the link itself, so the
        // recovery e-mail also works when it opens in Safari while the app
        // was installed as a PWA (they don't share storage).
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      _backendReady = true;
      final auth = Supabase.instance.client.auth;
      _authSub = auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          recoveryPending.value = true;
        }
        _applyUser(data.session?.user);
      });
      _applyUser(auth.currentSession?.user);
    } catch (e) {
      debugPrint('Supabase indisponível, usando conta local: $e');
      _backendReady = false;
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      email ??= prefs.getString(_emailKey);
      if (usesBackend) {
        _applyUser(Supabase.instance.client.auth.currentUser);
        return;
      }
      name = prefs.getString(_nameKey);
      email = prefs.getString(_emailKey);
      _salt = prefs.getString(_saltKey);
      _hash = prefs.getString(_hashKey);
      loggedIn = hasAccount && (prefs.getBool(_sessionKey) ?? false);
      notifyListeners();
    } catch (_) {}
  }

  void _applyUser(User? user) {
    if (user == null) {
      loggedIn = false;
    } else {
      email = user.email ?? email;
      final meta = user.userMetadata?['name'];
      name = (meta is String && meta.trim().isNotEmpty)
          ? meta.trim()
          : (email ?? '').split('@').first;
      loggedIn = true;
      _rememberEmail();
    }
    notifyListeners();
  }

  Future<void> _rememberEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (email != null) await prefs.setString(_emailKey, email!);
    } catch (_) {}
  }

  static String? validateName(String v) =>
      v.trim().length < 2 ? 'Digite seu nome.' : null;

  static String? validateEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
      ? null
      : 'E-mail inválido.';

  static String? validatePassword(String v) => PasswordRules.validate(v);

  static String _digest(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// Where the e-mail links (recovery, confirmation) send the user back.
  static String? get redirectUrl {
    if (AppConfig.siteUrl.isNotEmpty) return AppConfig.siteUrl;
    if (!kIsWeb) return null;
    final base = Uri.base;
    final path = base.path.endsWith('/')
        ? base.path
        : base.path.substring(0, base.path.lastIndexOf('/') + 1);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path.isEmpty ? '/' : path,
    ).toString();
  }

  /// Creates the account (online when Supabase is active, else on the
  /// device).
  Future<SignUpResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!usesBackend) {
      await createAccount(name: name, email: email, password: password);
      return (error: null, needsConfirmation: false);
    }
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
        emailRedirectTo: redirectUrl,
      );
      // With e-mail confirmation on, an already-registered address comes
      // back as a user with no identities and no error.
      if (res.user != null && (res.user!.identities?.isEmpty ?? false)) {
        return (
          error: 'Este e-mail já está cadastrado. Tente entrar.',
          needsConfirmation: false,
        );
      }
      this.email = email.trim().toLowerCase();
      await _rememberEmail();
      if (res.session == null) return (error: null, needsConfirmation: true);
      _applyUser(res.user);
      return (error: null, needsConfirmation: false);
    } catch (e) {
      return (error: AuthErrors.humanize(e), needsConfirmation: false);
    }
  }

  /// Local-only account creation.
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final rnd = Random.secure();
    _salt = base64Url.encode(List.generate(16, (_) => rnd.nextInt(256)));
    _hash = _digest(_salt!, password);
    this.name = name.trim();
    this.email = email.trim().toLowerCase();
    loggedIn = true;
    notifyListeners();
    await _save();
  }

  /// Returns an error message, or null when the credentials match.
  Future<String?> login(String email, String password) async {
    if (usesBackend) {
      try {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        _applyUser(res.user);
        return null;
      } catch (e) {
        return AuthErrors.humanize(e);
      }
    }
    if (!hasAccount) return 'Nenhuma conta neste aparelho. Crie uma.';
    if (email.trim().toLowerCase() != this.email ||
        _digest(_salt!, password) != _hash) {
      return 'E-mail ou senha incorretos.';
    }
    loggedIn = true;
    notifyListeners();
    await _save();
    return null;
  }

  /// Sends the password-recovery e-mail. Returns an error message or null.
  Future<String?> sendPasswordReset(String email) async {
    if (!usesBackend) return recoveryUnavailable;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectUrl,
      );
      return null;
    } catch (e) {
      return AuthErrors.humanize(e);
    }
  }

  /// Saves the new password after the recovery link. Signs the user out so
  /// they enter with the new password. Returns an error message or null.
  Future<String?> updatePassword(String newPassword) async {
    if (!usesBackend) return recoveryUnavailable;
    try {
      final auth = Supabase.instance.client.auth;
      await auth.updateUser(UserAttributes(password: newPassword));
      recoveryPending.value = false;
      await auth.signOut();
      return null;
    } catch (e) {
      return AuthErrors.humanize(e);
    }
  }

  Future<void> logout() async {
    if (usesBackend) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      loggedIn = false;
      notifyListeners();
      return;
    }
    loggedIn = false;
    notifyListeners();
    await _save();
  }

  /// Removes the local account from this device (used by "criar nova conta").
  Future<void> deleteAccount() async {
    name = email = _salt = _hash = null;
    loggedIn = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in [_nameKey, _emailKey, _saltKey, _hashKey, _sessionKey]) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, name!);
      await prefs.setString(_emailKey, email!);
      await prefs.setString(_saltKey, _salt!);
      await prefs.setString(_hashKey, _hash!);
      await prefs.setBool(_sessionKey, loggedIn);
    } catch (_) {}
  }

  @visibleForTesting
  Future<void> disposeBackend() async => _authSub?.cancel();
}
