import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../state/auth_scope.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _remember = true;
  bool _busy = false;
  String? _error;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).login(email, password);
      if (mounted) {
        // AuthGate now renders RootShell underneath — drop the auth stack.
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not sign in. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -1),
                  radius: 1.1,
                  colors: [const Color(0xFFDCE7CB), PP.bone.withValues(alpha: 0)],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SquircleIconButton(
                    icon: LucideIcons.chevronLeft,
                    radius: 16,
                    size: 44,
                    iconSize: 19,
                    background: PP.card.withValues(alpha: 0.7),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 34),
                  Text('Welcome\nback.',
                      style: TextStyle(
                          fontSize: 38,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: PP.track(38))),
                  const SizedBox(height: 12),
                  Text(
                    'Time to return to the soil. Log in and keep growing.',
                    style: TextStyle(
                        fontSize: 14.5, height: 1.5, color: PP.inkA(0.55)),
                  ),
                  const SizedBox(height: 30),
                  _Field(
                    controller: _email,
                    hint: 'Email address',
                    trailingIcon: LucideIcons.mail,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _password,
                    hint: 'Password',
                    obscure: true,
                    letterSpacing: 3,
                    trailingIcon: LucideIcons.eyeOff,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _remember = !_remember),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _remember ? PP.forest : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _remember ? PP.forest : PP.inkA(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: _remember
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: PP.bone)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text('Remember me',
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: PP.inkA(0.7))),
                          ],
                        ),
                      ),
                      Text('Forgot password',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: PP.forest,
                              decoration: TextDecoration.underline,
                              decorationColor: PP.forest)),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    _ErrorBanner(_error!),
                  ],
                  const SizedBox(height: 26),
                  PrimaryButton(
                    label: _busy ? 'Signing in…' : 'Log in',
                    background: _busy ? PP.inkA(0.4) : PP.forest,
                    fontSize: 16,
                    padding: 20,
                    onPressed: _busy ? null : _enter,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: PP.inkA(0.12))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('or continue with',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: PP.inkA(0.45))),
                      ),
                      Expanded(child: Container(height: 1, color: PP.inkA(0.12))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _SocialButton(
                              label: 'Google', icon: LucideIcons.globe2)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _SocialButton(
                              label: 'Apple', icon: LucideIcons.apple)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SignupScreen())),
                      child: Text.rich(TextSpan(
                        text: 'No account yet? ',
                        style:
                            TextStyle(fontSize: 13.5, color: PP.inkA(0.55)),
                        children: const [
                          TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, color: PP.forest)),
                        ],
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.trailingIcon,
    this.obscure = false,
    this.letterSpacing = 0,
  });

  final TextEditingController controller;
  final String hint;
  final IconData trailingIcon;
  final bool obscure;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 6, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: letterSpacing),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                    color: PP.inkA(0.4), fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: PP.pale1, borderRadius: BorderRadius.circular(20)),
            child: Icon(trailingIcon, size: 18, color: PP.forest),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: PP.amberBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert, size: 18, color: PP.amberFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: PP.amberFg)),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: PP.ink),
          const SizedBox(width: 10),
          Text(label,
              style:
                  const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
