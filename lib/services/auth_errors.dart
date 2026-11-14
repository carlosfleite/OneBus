import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns authentication failures into short messages a person can act on.
class AuthErrors {
  AuthErrors._();

  static const generic = 'Algo deu errado. Tente novamente.';
  static const offline =
      'Sem conexão. Verifique sua internet e tente de novo.';

  static String humanize(Object error) {
    if (error is AuthException) return _fromAuth(error);
    if (error is TimeoutException) return offline;
    final text = error.toString().toLowerCase();
    if (_looksOffline(text)) return offline;
    return generic;
  }

  static bool _looksOffline(String text) =>
      text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('clientexception') ||
      text.contains('xmlhttprequest') ||
      text.contains('network') ||
      text.contains('connection');

  static String _fromAuth(AuthException e) {
    final code = (e.code ?? '').toLowerCase();
    final msg = e.message.toLowerCase();

    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return 'E-mail ou senha incorretos.';
    }
    if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
      return 'Confirme seu e-mail antes de entrar. Enviamos um link para você.';
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return 'Este e-mail já está cadastrado. Tente entrar.';
    }
    if (code == 'weak_password' || msg.contains('password should be')) {
      return 'Senha fraca. Use 8 ou mais caracteres, com maiúscula, '
          'minúscula, número e símbolo.';
    }
    if (code == 'same_password' || msg.contains('different from the old')) {
      return 'A nova senha precisa ser diferente da atual.';
    }
    if (code.contains('rate_limit') ||
        msg.contains('rate limit') ||
        msg.contains('too many') ||
        e.statusCode == '429') {
      return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
    }
    if (code == 'otp_expired' ||
        code == 'session_not_found' ||
        code == 'session_expired' ||
        msg.contains('expired') ||
        msg.contains('session missing') ||
        msg.contains('invalid token')) {
      return 'O link expirou ou já foi usado. Peça um novo e-mail de '
          'recuperação.';
    }
    if (code == 'signup_disabled' || msg.contains('signups not allowed')) {
      return 'Os cadastros estão desativados no momento.';
    }
    if (code == 'validation_failed' || msg.contains('invalid format')) {
      return 'Confira o e-mail digitado.';
    }
    if (_looksOffline(msg)) return offline;
    return generic;
  }
}
