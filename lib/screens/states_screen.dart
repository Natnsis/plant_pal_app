import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';

class StatesScreen extends StatefulWidget {
  const StatesScreen({super.key});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      appBar: AppBar(
        backgroundColor: PP.bone,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: PP.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('First-run & analysing states',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: PP.pale1,
                          borderRadius: BorderRadius.circular(34),
                        ),
                        child: const Icon(LucideIcons.sprout,
                            size: 46, color: PP.forest),
                      ),
                      const SizedBox(height: 20),
                      Text('No plants yet',
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              letterSpacing: PP.track(21, -0.03))),
                      const SizedBox(height: 8),
                      Text(
                        "Scan your first plant and we'll build its care plan and reminders for you.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: PP.inkA(0.5)),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 16),
                          decoration: BoxDecoration(
                            color: PP.ink,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text('Scan a plant',
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: PP.bone)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: PP.forest,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i != 0) const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _c,
                            builder: (context, _) {
                              final phase = (_c.value - i * 0.18) % 1.0;
                              final o = 0.5 +
                                  0.5 *
                                      (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0);
                              return Opacity(
                                opacity: o,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: const BoxDecoration(
                                      color: PP.lime, shape: BoxShape.circle),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Analysing your photo',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: PP.track(18, -0.025),
                            color: PP.bone)),
                    const SizedBox(height: 6),
                    Text(
                      'Matching leaf shape, venation and colour against 12,000 species.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: PP.bone.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        height: 5,
                        color: PP.bone.withValues(alpha: 0.18),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.64,
                          child: Container(color: PP.lime),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PP.amberBg,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.triangleAlert,
                        size: 22, color: PP.amberFg),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Couldn't identify this one",
                              style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: PP.track(15.5, -0.015),
                                  color: PP.amberFg)),
                          const SizedBox(height: 4),
                          Text(
                            'Try again in daylight with the full plant in frame, or add it manually.',
                            style: TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                color: PP.amberFg.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
