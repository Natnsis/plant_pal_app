import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import '../widgets/simple_markdown.dart';
import 'scan_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _doc = '''
# Help & plant guides

## Getting started

- Tap the **scan button** in the centre of the bottom bar.
- Choose **Identify** to add a new plant, or **Diagnose** to check a sick one.
- After identifying, name your plant and pick a room — PlantPal builds its
  care plan and the first reminders automatically.

## Your daily care

- **Home** shows what's due today. Tap the circle to mark a task done.
- Marking care done keeps your **care streak** going and feeds your profile
  stats.
- **All tasks** opens the full schedule, where you can snooze or add a reminder.

## The plant page

- **Care** — the watering, light, temperature and humidity plan. Use **Log
  care** to record watering, feeding, misting, rotating or repotting.
- **Growth** — log a height measurement and a growth rate to build a history.
- **Journal** — write notes about the plant. They stay on your device until you
  tap **Sync to cloud**; after that you can read them on any device.
- **Info** — the full species reference: family, origin, soil, fertiliser,
  pruning and repotting guidance.
- The **stethoscope** opens the plant doctor with this plant's photo.

## Watering, the short version

- Check the top 2–3 cm of soil with a finger before watering — the calendar
  lies, the soil doesn't.
- Most house plants prefer to dry out slightly between waterings.
- Yellow lower leaves usually mean too much water; crispy brown edges usually
  mean too little, or dry air.

## Light

- **Bright indirect** = a couple of metres back from a bright window.
- **Low light** tolerant is not the same as **no light** — everything needs
  some.
- Rotate a quarter turn each week so growth stays even.

## Troubleshooting the app

- **"Server took too long"** — the backend may be waking from sleep; retry.
- **Scan says the photo is blurry** — the identifier needs a sharp, well-lit
  shot of the whole plant.
- **Daily scan limit** — identification and diagnosis are capped at 5 per day
  each.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
              child: Row(
                children: [
                  SquircleIconButton(
                    icon: LucideIcons.chevronLeft,
                    background: PP.card.withValues(alpha: 0.8),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Help & plant guides',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 40),
                children: [
                  const SimpleMarkdown(_doc),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ScanScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: PP.forest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.scan,
                              size: 20, color: PP.lime),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text('Scan your first plant',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: PP.bone)),
                          ),
                          Icon(LucideIcons.chevronRight,
                              size: 18,
                              color: PP.bone.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
