import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Text field with a leading icon, floating label, clear focus ring and an
/// optional show/hide button for passwords.
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool password;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboard;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;
  final TextInputAction? action;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.password = false,
    this.errorText,
    this.helperText,
    this.keyboard,
    this.capitalization = TextCapitalization.none,
    this.autofillHints,
    this.action,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: widget.password && _hidden,
      keyboardType: widget.password
          ? TextInputType.visiblePassword
          : widget.keyboard,
      textCapitalization: widget.capitalization,
      autofillHints: widget.autofillHints,
      textInputAction: widget.action,
      autocorrect: false,
      enableSuggestions: !widget.password,
      style: Theme.of(context).textTheme.bodyLarge,
      cursorColor: p.tint,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted == null
          ? null
          : (_) => widget.onSubmitted!(),
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        helperText: widget.helperText,
        errorMaxLines: 2,
        prefixIcon: Icon(widget.icon, size: 22, color: p.secondaryLabel),
        suffixIcon: widget.password
            ? IconButton(
                tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 22,
                  color: p.secondaryLabel,
                ),
              )
            : null,
      ),
    );
  }
}
