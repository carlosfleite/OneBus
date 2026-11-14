import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Rounded search box with a clear button.
class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    this.controller,
    required this.placeholder,
    this.onChanged,
    this.onTap,
    this.focusNode,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final _controller = widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge,
      cursorColor: p.tint,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        isDense: true,
        fillColor: p.fill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Icon(Icons.search_rounded, color: p.secondaryLabel),
        suffixIcon: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Limpar',
                  icon: Icon(Icons.close_rounded, color: p.secondaryLabel),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
      ),
    );
  }
}
