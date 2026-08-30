import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/google_auth.dart';
import '../state/auth_scope.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  int get _strength {
    final p = _password.text;
    var s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[A-Z]')) || p.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    return s;
  }

  Future<void> _google() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await GoogleAuth.signIn();
      if (token == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      await AuthScope.of(context).loginWithGoogle(token);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on GoogleAuthException catch (e) {
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Google sign-in failed. Try email instead.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty || email.isEmpty || password.length < 6) {
      setState(() => _error =
          'Enter your name, a valid email, and a password of at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).register(name, email, password);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      setState(() => _error = e.isConflict
          ? 'An account with that email already exists.'
          : e.message);
    } catch (_) {
      setState(() => _error = 'Could not create your account. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strengthLabel = ['Weak', 'Weak', 'Good', 'Strong'][_strength];
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
              _LabeledField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Abel Tesfaye'),
              const SizedBox(height: 12),
              _LabeledField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Password',
                controller: _password,
                hint: 'At least 6 characters',
                obscure: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _strengthBar(_strength >= 1 ? PP.forest : PP.pale3)),
                  const SizedBox(width: 7),
                  Expanded(
                      child: _strengthBar(_strength >= 2 ? PP.forest : PP.pale3)),
                  const SizedBox(width: 7),
                  Expanded(
                      child: _strengthBar(_strength >= 3 ? PP.forest : PP.pale3)),
                  const SizedBox(width: 8),
                  Text(strengthLabel,
                      style: const TextStyle(
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
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: PP.amberBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.triangleAlert,
                          size: 18, color: PP.amberFg),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: PP.amberFg)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _busy ? 'Creating account…' : 'Continue',
                background: _busy ? PP.inkA(0.4) : PP.ink,
                fontSize: 16,
                padding: 20,
                onPressed: _busy ? null : _submit,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _busy ? null : _google,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.globe2, size: 18, color: PP.ink),
                      SizedBox(width: 10),
                      Text('Continue with Google',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
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
                          text: 'Terms', style: TextStyle(color: PP.forest)),
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
    required this.controller,
    this.hint = '',
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

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
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isCollapsed: true,
            hintText: hint,
            hintStyle:
                TextStyle(color: PP.inkA(0.4), fontWeight: FontWeight.w500),
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
