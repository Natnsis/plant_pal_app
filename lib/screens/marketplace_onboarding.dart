import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// =============================================================================
// iOS Status Bar
// =============================================================================

class IOSStatusBar extends StatelessWidget {
  const IOSStatusBar({super.key});
  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            Text('$hour:$min $period',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            const Spacer(),
            // Signal
            Icon(LucideIcons.signal, size: 16, color: const Color(0xFF1A1A1A).withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            // WiFi
            Icon(LucideIcons.wifi, size: 16, color: const Color(0xFF1A1A1A).withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            // Battery
            Container(
              width: 25, height: 12,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A1A1A).withValues(alpha: 0.7), width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 18, height: 6,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Logo lockup
// =============================================================================

class LogoLockup extends StatelessWidget {
  const LogoLockup({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Swirl icon
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF7FA3C3), Color(0xFF5B8AB5)],
              ),
            ),
            child: const Center(
              child: Text('~', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 8),
          Text('PlantPal –', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
          )),
        ],
      ),
    );
  }
}

// =============================================================================
// Progress indicator
// =============================================================================

class ProgressIndicator extends StatelessWidget {
  const ProgressIndicator({super.key, required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFF1A1A1A).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// SCREEN 1: Overlapping Cards
// =============================================================================

class _Screen1Visual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back card
          Transform.translate(
            offset: const Offset(40, 20),
            child: Container(
              width: 200, height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF2),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DCE6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Center(child: Icon(LucideIcons.leaf, size: 40, color: Color(0xFF6B9CB8))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 80, height: 10, decoration: BoxDecoration(color: const Color(0xFFB8C6D4), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(width: 120, height: 8, decoration: BoxDecoration(color: const Color(0xFFD4DCE6), borderRadius: BorderRadius.circular(4))),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Middle card
          Transform.translate(
            offset: const Offset(10, 10),
            child: Container(
              width: 210, height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F7),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 145,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFFC5D4E3), Color(0xFFA8BDD4)],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Center(child: Icon(LucideIcons.flower2, size: 44, color: Color(0xFF5B8AB5))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 100, height: 10, decoration: BoxDecoration(color: const Color(0xFF9EB3C6), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(width: 140, height: 8, decoration: BoxDecoration(color: const Color(0xFFCBD8E4), borderRadius: BorderRadius.circular(4))),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Front card
          Transform.translate(
            offset: const Offset(-20, 0),
            child: Container(
              width: 220, height: 270,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFFB0C4D8), Color(0xFF8BA4BE)],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Center(child: Icon(LucideIcons.sprout, size: 48, color: Color(0xFF4CAF64))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 110, height: 10, decoration: BoxDecoration(color: const Color(0xFF8BA4BE), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(width: 160, height: 8, decoration: BoxDecoration(color: const Color(0xFFCBD8E4), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 10),
                      Container(width: 70, height: 22, decoration: BoxDecoration(color: const Color(0xFF7FA3C3), borderRadius: BorderRadius.circular(999))),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Action badge
          Positioned(
            top: 30, right: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
              ),                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(LucideIcons.camera, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text('Identify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SCREEN 2: User List
// =============================================================================

class _Screen2Visual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        children: [
          // Floating tag chip
          Positioned(
            top: 0, right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Text('🩺 AI Diagnosis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            ),
          ),

          // User cards
          Padding(
            padding: const EdgeInsets.only(top: 36),
            child: Column(
              children: [
                _UserRow(name: 'Emma Wilson', subtitle: '142 plants · 4.9★', color: const Color(0xFF7FA3C3)),
                const SizedBox(height: 12),
                _UserRow(name: 'James Park', subtitle: '89 plants · 4.8★', color: const Color(0xFF6B9CB8)),
                const SizedBox(height: 12),
                _UserRow(name: 'Sofia Chen', subtitle: '267 plants · 5.0★', color: const Color(0xFF5B8AB5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}class _UserRow extends StatelessWidget {
  const _UserRow({required this.name, required this.subtitle, required this.color});
  final String name;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(name[0], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color))),
          ),
          const SizedBox(width: 12),
          // Name + stat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.badgeCheck, size: 14, color: Color(0xFF4CAF64)),
                ]),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: const Color(0xFF1A1A1A).withValues(alpha: 0.45))),
              ],
            ),
          ),
          // Diagnose button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F7),
              borderRadius: BorderRadius.circular(999),
            ),
              child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4CAF64))),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SCREEN 3: Orbital Layout
// =============================================================================

class _Screen3Visual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floating tag
          Positioned(
            top: 0, left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Text('💧 Smart Care', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
            ),
          ),

          // Orbit rings (dotted circles)
          ...List.generate(2, (i) {
            final size = 140.0 + i * 60;
            return Container(
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
              ),
            );
          }),

          // Dotted orbit lines (using small dots)
          CustomPaint(
            size: const Size(260, 260),
            painter: _OrbitDotsPainter(),
          ),

          // Center icon (largest)
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Center(child: Icon(LucideIcons.leaf, size: 28, color: Color(0xFF4CAF64))),
          ),

          // Orbital bubbles
          _OrbitalBubble(angle: 30, orbitRadius: 90, size: 36, icon: LucideIcons.droplets, color: const Color(0xFF7FA3C3)),
          _OrbitalBubble(angle: 120, orbitRadius: 80, size: 32, icon: LucideIcons.sun, color: const Color(0xFF6B9CB8)),
          _OrbitalBubble(angle: 210, orbitRadius: 100, size: 38, icon: LucideIcons.sprout, color: const Color(0xFF5B8AB5)),
          _OrbitalBubble(angle: 300, orbitRadius: 85, size: 30, icon: LucideIcons.flower2, color: const Color(0xFF8BB5CC)),
          _OrbitalBubble(angle: 60, orbitRadius: 115, size: 28, icon: LucideIcons.heart, color: const Color(0xFF9EC5D6)),
          _OrbitalBubble(angle: 180, orbitRadius: 110, size: 34, icon: LucideIcons.leaf, color: const Color(0xFF7FA3C3)),
        ],
      ),
    );
  }
}

class _OrbitalBubble extends StatelessWidget {
  const _OrbitalBubble({
    required this.angle,
    required this.orbitRadius,
    required this.size,
    required this.icon,
    required this.color,
  });

  final double angle;
  final double orbitRadius;
  final double size;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rad = angle * 3.14159 / 180;
    final x = orbitRadius * _cos(rad);
    final y = orbitRadius * _sin(rad);

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Center(child: Icon(icon, size: size * 0.45, color: color)),
      ),
    );
  }

  static double _cos(double x) => x;
  static double _sin(double x) => x;
}

class _OrbitDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius1 = 90.0;
    final radius2 = 120.0;

    for (final radius in [radius1, radius2]) {
      for (var angle = 0.0; angle < 360; angle += 20) {
        final rad = angle * 3.14159 / 180;
        final x = center.dx + radius * _cos(rad);
        final y = center.dy + radius * _sin(rad);
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  static double _cos(double x) => x;
  static double _sin(double x) => x;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// MAIN ONBOARDING SCREEN
// =============================================================================

class MarketplaceOnboarding extends StatefulWidget {
  const MarketplaceOnboarding({super.key, this.onComplete});
  final VoidCallback? onComplete;

  @override
  State<MarketplaceOnboarding> createState() => _MarketplaceOnboardingState();
}

class _MarketplaceOnboardingState extends State<MarketplaceOnboarding> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  static final _data = [
    _OnboardData(
      visual: _Screen1Visual(),
      headline: 'Meet your plants',
      subheading: 'Snap a photo and instantly identify any plant species in seconds.',
      buttonText: 'Next',
    ),
    _OnboardData(
      visual: _Screen2Visual(),
      headline: 'Catch problems early',
      subheading: 'Upload a photo of a sick plant and chat with AI to diagnose and treat it.',
      buttonText: 'Next',
    ),
    _OnboardData(
      visual: _Screen3Visual(),
      headline: 'Never miss a watering',
      subheading: 'Get personalized care plans and reminders tailored to every plant you own.',
      buttonText: 'Get Started',
    ),
  ];

  void _onNext() {
    if (_current < 2) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          const IOSStatusBar(),

          // Logo
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LogoLockup(),
          ),

          // Page content
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: 3,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final data = _data[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Visual
                      Expanded(flex: 5, child: data.visual),

                      const SizedBox(height: 24),

                      // Headline
                      Text(
                        data.headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A),
                          height: 1.15, letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Subheading
                      Text(
                        data.subheading,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w400,
                          color: const Color(0xFF1A1A1A).withValues(alpha: 0.45),
                          height: 1.5,
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom controls
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: Column(
              children: [
                // Progress indicator
                ProgressIndicator(current: _current),

                const SizedBox(height: 24),

                // CTA button
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7FA3C3),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 6,
                      shadowColor: const Color(0xFF7FA3C3).withValues(alpha: 0.35),
                    ),
                    child: Text(
                      _data[_current].buttonText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardData {
  const _OnboardData({required this.visual, required this.headline, required this.subheading, required this.buttonText});
  final Widget visual;
  final String headline;
  final String subheading;
  final String buttonText;
}
