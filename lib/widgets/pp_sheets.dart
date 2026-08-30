import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';

/// A rounded bottom sheet in the PlantPal visual language: bone panel,
/// grab handle, title, and a keyboard-aware content area. [builder] receives
/// a context it can `Navigator.pop(context, value)` on to return a result.
Future<T?> showPPSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      return Padding(
        // Lift the whole sheet above the keyboard.
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          // Never taller than most of the screen; the body scrolls if the
          // content (chips + multi-line field + button) doesn't fit.
          constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
          decoration: const BoxDecoration(
            color: PP.bone,
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PP.inkA(0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: PP.track(19, -0.025))),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: builder(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Styled multi/single-line text field used inside sheets.
class PPSheetField extends StatelessWidget {
  const PPSheetField({
    super.key,
    required this.controller,
    this.hint = '',
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      autofocus: autofocus,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle:
            TextStyle(color: PP.inkA(0.4), fontWeight: FontWeight.w500),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// A small selectable pill row, used for choosing a task type / category /
/// growth rate inside sheets.
class PPChoiceChips extends StatelessWidget {
  const PPChoiceChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () => onChanged(o),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: value == o ? PP.ink : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(o,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: value == o ? PP.bone : PP.inkA(0.6))),
            ),
          ),
      ],
    );
  }
}
