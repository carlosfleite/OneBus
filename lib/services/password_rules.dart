/// One requirement of a good password.
class PasswordRule {
  final String label;
  final bool Function(String password) test;

  const PasswordRule(this.label, this.test);
}

/// Password policy shown live while the user types.
class PasswordRules {
  PasswordRules._();

  static const minLength = 8;

  static final rules = <PasswordRule>[
    const PasswordRule('Mínimo de 8 caracteres', _length),
    PasswordRule('Uma letra maiúscula', (p) => RegExp('[A-Z]').hasMatch(p)),
    PasswordRule('Uma letra minúscula', (p) => RegExp('[a-z]').hasMatch(p)),
    PasswordRule('Um número', (p) => RegExp('[0-9]').hasMatch(p)),
    PasswordRule(
      'Um caractere especial (ex.: ! @ # \$)',
      (p) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p),
    ),
  ];

  static bool _length(String p) => p.length >= minLength;

  /// Each rule paired with whether [password] satisfies it.
  static List<({String label, bool ok})> check(String password) => [
    for (final r in rules) (label: r.label, ok: r.test(password)),
  ];

  static bool isStrong(String password) => rules.every((r) => r.test(password));

  /// Error message for [password], or null when it is strong enough.
  static String? validate(String password) {
    if (password.isEmpty) return 'Crie uma senha.';
    if (!isStrong(password)) {
      return 'A senha ainda não atende a todos os requisitos.';
    }
    return null;
  }
}
