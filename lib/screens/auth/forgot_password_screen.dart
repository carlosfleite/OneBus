import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_store.dart';
import '../../widgets/ds/app_button.dart';
import '../../widgets/ds/app_text_field.dart';
import 'auth_widgets.dart';

/// Asks for the e-mail and sends the password-recovery link.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  bool _submitted = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  String? get _emailError => AuthStore.validateEmail(_email.text);

  Future<void> _send() async {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_emailError != null) return;
    setState(() => _busy = true);
    final error = await AuthStore.instance.sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final unavailable = !AuthStore.instance.usesBackend;

    return AuthLayout(
      title: 'Recuperar senha',
      subtitle:
          'Informe o e-mail da sua conta e enviaremos um link para '
          'criar uma nova senha.',
      onBack: () => Navigator.of(context).pop(),
      children: [
        if (unavailable)
          const AuthNotice(NoticeKind.info, AuthStore.recoveryUnavailable)
        else if (_sent) ...[
          AuthNotice(
            NoticeKind.success,
            'Se ${_email.text.trim()} estiver cadastrado, você vai receber '
            'um e-mail com o link em instantes. Olhe também o spam.',
          ),
          Text(
            'O link vale por pouco tempo. Se ele abrir no navegador, '
            'crie a nova senha lá e depois entre no app normalmente.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: 'Reenviar e-mail',
            secondary: true,
            loading: _busy,
            onPressed: _send,
          ),
        ] else ...[
          if (_error != null) AuthNotice(NoticeKind.error, _error!),
          AppTextField(
            controller: _email,
            label: 'E-mail',
            icon: Icons.mail_outline_rounded,
            keyboard: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            action: TextInputAction.done,
            errorText: _submitted ? _emailError : null,
            onSubmitted: _send,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: 'Enviar link',
            icon: Icons.send_rounded,
            loading: _busy,
            onPressed: _send,
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar para entrar'),
          ),
        ),
      ],
    );
  }
}
