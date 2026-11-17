import 'package:flutter/material.dart';

import '../../services/auth_store.dart';
import '../../widgets/ds/app_button.dart';
import '../../widgets/ds/app_text_field.dart';
import '../auth_screen.dart';
import 'auth_widgets.dart';

/// Shown when the user opens the recovery link from the e-mail: sets the
/// new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? get _passwordError => AuthStore.validatePassword(_password.text);
  String? get _confirmError => _confirm.text.isEmpty
      ? 'Repita a senha.'
      : (_confirm.text != _password.text ? 'As senhas não coincidem.' : null);
  bool get _canSubmit => _passwordError == null && _confirmError == null;

  Future<void> _save() async {
    if (_busy || !_canSubmit) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await AuthStore.instance.updatePassword(_password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    replaceWith(
      context,
      const AuthScreen(
        startOnLogin: true,
        notice:
            'Senha alterada com sucesso! Entre com a nova senha. Se você '
            'instalou o app na Tela de Início, abra-o por lá.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Crie uma nova senha',
      subtitle:
          'Escolha uma senha forte. Você vai usá-la para entrar no '
          'OneBus.',
      children: [
        if (_error != null) AuthNotice(NoticeKind.error, _error!),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _password,
                label: 'Nova senha',
                icon: Icons.lock_outline_rounded,
                password: true,
                autofillHints: const [AutofillHints.newPassword],
                action: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              PasswordRequirements(password: _password.text),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirm,
                label: 'Confirmar nova senha',
                icon: Icons.lock_outline_rounded,
                password: true,
                autofillHints: const [AutofillHints.newPassword],
                action: TextInputAction.done,
                errorText: _confirm.text.isNotEmpty ? _confirmError : null,
                onSubmitted: _canSubmit ? _save : null,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AppButton(
          label: 'Salvar nova senha',
          loading: _busy,
          onPressed: _canSubmit ? _save : null,
        ),
      ],
    );
  }
}
