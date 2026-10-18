import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/auth_store.dart';
import '../widgets/ios.dart';
import '../widgets/onebus_logo.dart';
import 'app_shell.dart';

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

/// First access: create the account. After "Sair": log back in.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthStore.instance;
  late bool _creating = !_auth.hasAccount;

  final _name = TextEditingController();
  late final _email = TextEditingController(text: _auth.email ?? '');
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _nameError =>
      _creating ? AuthStore.validateName(_name.text) : null;
  String? get _emailError => AuthStore.validateEmail(_email.text);
  String? get _passwordError => _creating
      ? AuthStore.validatePassword(_password.text)
      : (_password.text.isEmpty ? 'Digite sua senha.' : null);

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    final firstError = _nameError ?? _emailError ?? _passwordError;
    if (firstError != null) return;

    setState(() => _busy = true);
    String? error;
    if (_creating) {
      await _auth.createAccount(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
    } else {
      error = await _auth.login(_email.text, _password.text);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) replaceWith(context, const AppShell());
  }

  void _startOver() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Criar nova conta?'),
        content: const Text(
          'A conta salva neste aparelho será substituída. '
          'Favoritos e preferências continuam.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _auth.deleteAccount();
              setState(() {
                _creating = true;
                _submitted = false;
                _error = null;
                _email.clear();
                _password.clear();
              });
            },
            child: const Text('Criar nova'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    final text = Theme.of(context).textTheme;
    final fieldErrors = _submitted
        ? [_nameError, _emailError, _passwordError].whereType<String>()
        : const <String>[];

    return Scaffold(
      backgroundColor: ios.groupedBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: OneBusLogo(size: 72)),
                    const SizedBox(height: 20),
                    Text(
                      _creating
                          ? 'Crie sua conta'
                          : 'Que bom te ver, ${_auth.firstName}',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _creating
                          ? 'Leva menos de um minuto. Depois é só abrir o app.'
                          : 'Entre para ver seus ônibus favoritos.',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(
                        color: ios.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 28),
                    InsetGroup(
                      separatorIndent: 16,
                      children: [
                        if (_creating)
                          _Field(
                            controller: _name,
                            placeholder: 'Nome',
                            icon: CupertinoIcons.person,
                            autofill: AutofillHints.name,
                            capitalization: TextCapitalization.words,
                            onChanged: () => setState(() {}),
                          ),
                        _Field(
                          controller: _email,
                          placeholder: 'E-mail',
                          icon: CupertinoIcons.mail,
                          autofill: AutofillHints.email,
                          keyboard: TextInputType.emailAddress,
                          onChanged: () => setState(() {}),
                        ),
                        _Field(
                          controller: _password,
                          placeholder: _creating
                              ? 'Senha (mín. 6 caracteres)'
                              : 'Senha',
                          icon: CupertinoIcons.lock,
                          autofill: _creating
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                          obscure: _obscure,
                          onSubmitted: _submit,
                          onChanged: () => setState(() {}),
                          trailing: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                              size: 20,
                              color: ios.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final e in [...fieldErrors, ?_error])
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              size: 15,
                              color: AppColors.red,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e,
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : Text(_creating ? 'Criar conta' : 'Entrar'),
                    ),
                    const SizedBox(height: 12),
                    if (!_creating)
                      CupertinoButton(
                        onPressed: _startOver,
                        child: const Text(
                          'Não é você? Criar nova conta',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Sua conta fica salva neste aparelho. Você só precisa '
                      'entrar de novo se tocar em "Sair".',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: ios.tertiaryLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final String autofill;
  final TextInputType? keyboard;
  final TextCapitalization capitalization;
  final bool obscure;
  final Widget? trailing;
  final VoidCallback onChanged;
  final VoidCallback? onSubmitted;

  const _Field({
    required this.controller,
    required this.placeholder,
    required this.icon,
    required this.autofill,
    required this.onChanged,
    this.keyboard,
    this.capitalization = TextCapitalization.none,
    this.obscure = false,
    this.trailing,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final ios = IosColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ios.secondaryLabel),
          Expanded(
            child: CupertinoTextField.borderless(
              controller: controller,
              placeholder: placeholder,
              placeholderStyle: TextStyle(color: ios.tertiaryLabel),
              style: Theme.of(context).textTheme.bodyLarge,
              keyboardType: keyboard,
              textCapitalization: capitalization,
              autofillHints: [autofill],
              obscureText: obscure,
              autocorrect: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              onChanged: (_) => onChanged(),
              onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
