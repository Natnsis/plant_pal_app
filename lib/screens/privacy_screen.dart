import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_client.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import '../widgets/simple_markdown.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  /// Show the scheme + host head and tail, mask the middle — enough to
  /// reassure "one server, over HTTPS" without publishing the full origin.
  static String _maskUrl(String url) {
    final noScheme = url.replaceFirst(RegExp(r'^https?://'), '');
    final scheme = url.startsWith('https') ? 'https://' : 'http://';
    if (noScheme.length <= 10) return '$scheme$noScheme';
    final head = noScheme.substring(0, 6);
    final tail = noScheme.substring(noScheme.length - 4);
    return '$scheme$head${'•' * 8}$tail';
  }

  static const _doc = '''
# Privacy & data

PlantPal is built to help you keep plants alive — not to profile you. This page
is the plain-English version of what the app stores and why.

## What we keep

- **Your account** — name, email, and a hashed password. The password is stored
  as a bcrypt hash; it is never saved or transmitted in readable form.
- **Your plants** — nicknames, rooms, health scores, care plans, reminders,
  growth measurements, and the activity you log.
- **Photos you scan** — plant photos you send for identification or diagnosis
  are uploaded to image storage so the result can be shown again later.
- **Journal notes** — notes you write stay on this device until you tap
  **Sync to cloud**. Only then are they sent to the server.
- **Community posts** — anything you post to the community feed is visible to
  other PlantPal users, under your display name.

## What we do not do

- We do not sell or share your data with advertisers.
- We do not track your location. Weather uses a city-level coordinate only.
- We do not read your camera roll — the app has no gallery access.
- We do not send you marketing. Notifications are reminders you opted into.

## Your controls

- **Notifications** — turn reminders on or off any time in Profile.
- **Delete a plant** — removes its care plan, reminders, growth history, and
  logged activity with it.
- **Delete a journal note** — removes it from this device; synced copies can be
  removed from the Journal tab.
- **Log out** — clears the saved session token from this device.

## Where your data lives

The app talks to a single backend over HTTPS. Nothing is sent anywhere else.
Session tokens are stored in the app's private support directory on this
device, not in shared storage.
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
                      child: Text('Privacy & data',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PP.pale1,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.shield,
                            size: 18, color: PP.forest),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Single API endpoint\n${_maskUrl(kPlantPalBaseUrl)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                  color: PP.forest)),
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
    );
  }
}
