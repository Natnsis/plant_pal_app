import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 6, 26, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PlantPal',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15)),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    color: PP.forest,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/img/onboarding.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, _) => const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-0.5, -1),
                                end: Alignment(0.5, 1),
                                colors: [
                                  PP.forest,
                                  PP.forestMid,
                                  PP.forestLight
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x3316180F),
                                Color(0x00000000),
                                Color(0xCC16180F),
                              ],
                              stops: [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -120,
                        right: -140,
                        child: Container(
                          width: 420,
                          height: 420,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                PP.lime.withValues(alpha: 0.28),
                                PP.lime.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.62],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 7),
                                decoration: BoxDecoration(
                                  color: PP.bone.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Powered by plant AI',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: PP.bone)),
                              ),
                              const SizedBox(height: 16),
                              Text('Know every\nleaf you own.',
                                  style: TextStyle(
                                      fontSize: 40,
                                      height: 1.02,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: PP.track(40),
                                      color: PP.bone)),
                              const SizedBox(height: 12),
                              Text(
                                'Snap a photo to identify a plant, get a care plan, and catch disease early.',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.5,
                                    color: PP.bone.withValues(alpha: 0.72)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Get started',
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: Container(
                      width: 62,
                      height: 60,
                      decoration: BoxDecoration(
                        color: PP.pale3,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(LucideIcons.arrowRight,
                          size: 20, color: PP.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: Text.rich(
                    TextSpan(
                      text: 'Already growing with us? ',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: PP.inkA(0.55),
                          fontWeight: FontWeight.w400),
                      children: const [
                        TextSpan(
                            text: 'Log in',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: PP.forest)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
