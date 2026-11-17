import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../services/auth_store.dart';
import '../widgets/ds/app_button.dart';
import '../widgets/ds/app_sheets.dart';
import '../widgets/ds/app_text_field.dart';
import 'app_shell.dart';
import 'auth/auth_widgets.dart';
import 'auth/forgot_password_screen.dart';

/// Fades into [page], replacing the whole navigation stack.
void replaceWith(BuildContext context, Widget page) {
  Navigator.of(context).pushAndRemoveUntil(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, anim, _, child) {
        final t = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: t,
          child: ScaleTransition(
            scale: Tween(begin: 1.04, end: 1.0).animate(t),
            child: child,
          ),
        );
      },
    ),
    (_) => false,
  );
}

/// First access: create the account. Afterwards: log in.
class AuthScreen extends StatefulWidget {
  /// Opens straight on the login form (e.g. after a password change).
  final bool startOnLogin;

  /// Message shown above the form (e.g. "senha alterada").
  final String? notice;

  const AuthScreen({super.key, this.startOnLogin = false, this.notice});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthStore.instance;
  late bool _creating = !widget.startOnLogin && !_auth.hasAccount;

  final _name = TextEditingController();
  late final _email = TextEditingController(text: _auth.email ?? '');
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  bool _submitted = false;
  String? _error;
  late String? _notice = widget.notice;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? get _nameError =>
      _creating ? AuthStore.validateName(_name.text) : null;
  String? get _emailError => AuthStore.validateEmail(_email.text);
  String? get _passwordError => _creating
      ? AuthStore.validatePassword(_password.text)
      : (_password.text.isEmpty ? 'Digite sua senha.' : null);
  String? get _confirmError => !_creating
      ? null
      : (_confirm.text.isEmpty
            ? 'Repita a senha.'
            : (_confirm.text != _password.text
                  ? 'As senhas não coincidem.'
                  : null));

  bool get _canSubmit =>
      !_creating ||
      (_nameError == null &&
          _emailError == null &&
          _passwordError == null &&
          _confirmError == null);

  void _switchMode() => setState(() {
    _creating = !_creating;
    _submitted = false;
    _error = null;
    _notice = null;
    _password.clear();
    _confirm.clear();
  });

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _error = null;
      _notice = null;
    });
    final firstError =
        _nameError ?? _emailError ?? _passwordError ?? _confirmError;
    if (firstError != null) return;

    setState(() => _busy = true);
    String? error;
    var needsConfirmation = false;
    if (_creating) {
      final r = await _auth.signUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      error = r.error;
      needsConfirmation = r.needsConfirmation;
    } else {
      error = await _auth.login(_email.text, _password.text);
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      setState(() => _error = error);
      HapticFeedback.mediumImpact();
      return;
    }
    TextInput.finishAutofillContext();
    if (needsConfirmation) {
      setState(() {
        _creating = false;
        _submitted = false;
        _password.clear();
        _confirm.clear();
        _notice =
            'Enviamos um link de confirmação para ${_email.text.trim()}. '
            'Confirme o e-mail e depois entre.';
      });
      return;
    }
    replaceWith(context, const AppShell());
  }

  Future<void> _startOver() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Criar nova conta?',
      message:
          'A conta salva neste aparelho será substituída. '
          'Favoritos e preferências continuam.',
      confirmLabel: 'Criar nova',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _auth.deleteAccount();
    setState(() {
      _creating = true;
      _submitted = false;
      _error = null;
      _email.clear();
      _password.clear();
      _confirm.clear();
    });
  }

  void _forgot() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordScreen(initialEmail: _email.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final show = _submitted;

    return AuthLayout(
      title: _creating
          ? 'Crie sua conta'
          : (_auth.firstName.isNotEmpty && !_auth.usesBackend
                ? 'Que bom te ver, ${_auth.firstName}'
                : 'Que bom te ver de novo'),
      subtitle: _creating
          ? 'Leva menos de um minuto. Depois é só abrir o app.'
          : 'Entre para ver seus ônibus favoritos.',
      children: [
        if (_notice != null) AuthNotice(NoticeKind.success, _notice!),
        if (_error != null) AuthNotice(NoticeKind.error, _error!),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_creating) ...[
                AppTextField(
                  controller: _name,
                  label: 'Nome',
                  icon: Icons.person_outline_rounded,
                  capitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  action: TextInputAction.next,
                  errorText: show ? _nameError : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
              ],
              AppTextField(
                controller: _email,
                label: 'E-mail',
                icon: Icons.mail_outline_rounded,
                keyboard: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                action: TextInputAction.next,
                errorText: show ? _emailError : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _password,
                label: 'Senha',
                icon: Icons.lock_outline_rounded,
                password: true,
                autofillHints: [
                  _creating
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                action: _creating ? TextInputAction.next : TextInputAction.done,
                errorText: show && !_creating ? _passwordError : null,
                onSubmitted: _creating ? null : _submit,
                onChanged: (_) => setState(() {}),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _creating
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PasswordRequirements(password: _password.text),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _confirm,
                            label: 'Confirmar senha',
                            icon: Icons.lock_outline_rounded,
                            password: true,
                            autofillHints: const [AutofillHints.newPassword],
                            action: TextInputAction.done,
                            errorText: (show || _confirm.text.isNotEmpty)
                                ? _confirmError
                                : null,
                            onSubmitted: _canSubmit ? _submit : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgot,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AppButton(
          label: _creating ? 'Criar conta' : 'Entrar',
          loading: _busy,
          onPressed: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _switchMode,
            child: Text.rich(
              TextSpan(
                style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                children: [
                  TextSpan(
                    text: _creating ? 'Já tem conta? ' : 'Novo por aqui? ',
                  ),
                  TextSpan(
                    text: _creating ? 'Entrar' : 'Criar conta',
                    style: TextStyle(
                      color: p.label,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      decorationColor: p.accent,
                      decorationThickness: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_creating && !_auth.usesBackend && _auth.hasAccount)
          Center(
            child: TextButton(
              onPressed: _startOver,
              child: const Text('Não é você? Criar nova conta'),
            ),
          ),
        if (!_auth.usesBackend) ...[
          const SizedBox(height: 8),
          Text(
            'Sua conta fica salva neste aparelho. Você só precisa '
            'entrar de novo se tocar em "Sair".',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: p.tertiaryLabel),
          ),
        ],
      ],
    );
  }
}
