import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'root_shell.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SquircleIconButton(
                    icon: LucideIcons.chevronLeft,
                    radius: 16,
                    size: 44,
                    iconSize: 19,
                    background: PP.card.withValues(alpha: 0.7),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: PP.pale3,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: PP.forest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('1 / 2',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: PP.inkA(0.5))),
                ],
              ),
              const SizedBox(height: 26),
              Text('Create your\ngarden profile',
                  style: TextStyle(
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: PP.track(34))),
              const SizedBox(height: 10),
              Text('We use this to time reminders to your local weather.',
                  style: TextStyle(
                      fontSize: 14.5, height: 1.5, color: PP.inkA(0.55))),
              const SizedBox(height: 26),
              const _LabeledField(label: 'Full name', value: 'Abel Tesfaye'),
              const SizedBox(height: 12),
              const _LabeledField(label: 'Email', value: 'abel@pitrontech.et'),
              const SizedBox(height: 12),
              const _LabeledField(
                  label: 'Password', value: 'plantpal01', obscure: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _strengthBar(PP.forest)),
                  const SizedBox(width: 7),
                  Expanded(child: _strengthBar(PP.forest)),
                  const SizedBox(width: 7),
                  Expanded(child: _strengthBar(PP.pale3)),
                  const SizedBox(width: 8),
                  const Text('Good',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PP.forest)),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: PP.pale1,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.info, size: 20, color: PP.forest),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Next you'll scan your first plant — we'll build its care plan automatically.",
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: PP.forest),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                label: 'Continue',
                fontSize: 16,
                padding: 20,
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RootShell()),
                    (_) => false),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing you agree to our ',
                    style: TextStyle(
                        fontSize: 12, height: 1.5, color: PP.inkA(0.45)),
                    children: const [
                      TextSpan(
                          text: 'Terms',
                          style: TextStyle(color: PP.forest)),
                      TextSpan(text: ' and '),
                      TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(color: PP.forest)),
                      TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _strengthBar(Color color) => Container(
        height: 4,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.value,
    this.obscure = false,
  });

  final String label;
  final String value;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: PP.inkA(0.5))),
        ),
        TextFormField(
          initialValue: value,
          obscureText: obscure,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: obscure ? 3 : 0),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isCollapsed: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
