import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local account kept on the device.
///
/// The user signs up once; the session is remembered, so the login screen
/// only shows again after "Sair". Passwords are stored as a salted
/// SHA-256 hash, never in plain text. There is no server yet: swap this for
/// a real auth backend (e.g. Firebase Auth) when one exists.
class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final instance = AuthStore._();

  static const _nameKey = 'auth_name';
  static const _emailKey = 'auth_email';
  static const _saltKey = 'auth_salt';
  static const _hashKey = 'auth_hash';
  static const _sessionKey = 'auth_logged_in';

  String? name;
  String? email;
  String? _salt;
  String? _hash;
  bool loggedIn = false;

  bool get hasAccount => email != null && _hash != null;

  String get firstName => (name ?? '').trim().split(RegExp(r'\s+')).first;

  String get initial =>
      firstName.isEmpty ? '?' : firstName.substring(0, 1).toUpperCase();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      name = prefs.getString(_nameKey);
      email = prefs.getString(_emailKey);
      _salt = prefs.getString(_saltKey);
      _hash = prefs.getString(_hashKey);
      loggedIn = hasAccount && (prefs.getBool(_sessionKey) ?? false);
      notifyListeners();
    } catch (_) {}
  }

  static String? validateName(String v) =>
      v.trim().length < 2 ? 'Digite seu nome.' : null;

  static String? validateEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
      ? null
      : 'E-mail inválido.';

  static String? validatePassword(String v) =>
      v.length < 6 ? 'A senha precisa ter pelo menos 6 caracteres.' : null;

  static String _digest(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

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

  Future<void> logout() async {
    loggedIn = false;
    notifyListeners();
    await _save();
  }

  /// Removes the account from this device (used by "criar nova conta").
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
}
