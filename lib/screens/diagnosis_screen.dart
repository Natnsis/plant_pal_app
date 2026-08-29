import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';

class _Msg {
  const _Msg(this.text, {required this.me});
  final String text;
  final bool me;
}

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key, this.sessionId});

  /// When set, the screen drives a real `/diagnosis/{id}` session. When null
  /// it shows a local sample conversation (opened from a plant, not a scan).
  final String? sessionId;

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _api = PlantPalApi.instance;
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  bool get _live => widget.sessionId != null && widget.sessionId!.isNotEmpty;

  final List<_Msg> _chat = [
    const _Msg(
      "I see brown crisp edges on the lower leaves and slight yellowing — that reads as underwatering plus low humidity, not a fungal issue.",
      me: false,
    ),
    const _Msg("It sits near a west window. Should I move it?", me: true),
  ];

  @override
  void initState() {
    super.initState();
    if (_live) _loadHistory();
  }

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final session = await _api.diagnosisHistory(widget.sessionId!);
      if (!mounted) return;
      setState(() {
        _chat
          ..clear()
          ..addAll(session.messages
              .map((m) => _Msg(m.text, me: m.fromUser)));
      });
      _jump();
    } catch (_) {
      // Keep whatever the start response already showed.
    }
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _chat.add(_Msg(text, me: true));
      _draft.clear();
      _sending = true;
    });
    _jump();

    if (!_live) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _chat.add(const _Msg(
          "West light is fine — just pull it back about a metre so the midday sun isn't direct, and mist the leaves twice a week.",
          me: false,
        ));
        _sending = false;
      });
      _jump();
      return;
    }

    try {
      final session =
          await _api.sendDiagnosisMessage(widget.sessionId!, text);
      if (!mounted) return;
      setState(() {
        _chat
          ..clear()
          ..addAll(session.messages.map((m) => _Msg(m.text, me: m.fromUser)));
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _chat.add(_Msg('(${e.message})', me: false)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _jump();
    }
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
              child: Row(
                children: [
                  SquircleIconButton(
                    icon: LucideIcons.chevronLeft,
                    background: PP.card.withValues(alpha: 0.8),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plant doctor',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: PP.track(15, -0.02))),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: PP.lime, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            const Text('Session open · Golden Pothos',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: PP.forest)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: PP.plantImage,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(LucideIcons.sprout,
                        size: 20, color: PP.forest),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 200,
                          height: 132,
                          decoration: BoxDecoration(
                            gradient: PP.plantImage,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(26),
                              topRight: Radius.circular(26),
                              bottomLeft: Radius.circular(26),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Icon(LucideIcons.sprout,
                              size: 62,
                              color: PP.forest.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(height: 5),
                        Text('Uploaded · 9:38',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: PP.inkA(0.4))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_live) ...[
                    _likelyIssueCard(),
                    const SizedBox(height: 12),
                    _treatmentCard(),
                    const SizedBox(height: 12),
                  ],
                  for (final m in _chat) ...[
                    _bubble(m),
                    const SizedBox(height: 12),
                  ],
                  if (_sending)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: PP.forest),
                          ),
                          const SizedBox(width: 10),
                          Text('Plant doctor is typing…',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: PP.inkA(0.5))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _likelyIssueCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PP.forest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LIKELY ISSUE',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: PP.bone.withValues(alpha: 0.6))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PP.lime,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Moderate',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: PP.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Leaf-tip scorch',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: PP.track(22, -0.03),
                  color: PP.bone)),
          const SizedBox(height: 8),
          Text(
            'Dry air and inconsistent watering, not a pathogen. Confidence 88%.',
            style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: PP.bone.withValues(alpha: 0.78)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _softTag('Not contagious'),
              _softTag('Recoverable'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _softTag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: PP.bone.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: PP.bone)),
      );

  Widget _treatmentCard() {
    const steps = [
      "Trim scorched tips with clean shears — don't cut into green tissue.",
      "Water when the top 3 cm dries — roughly every 6 days indoors.",
      "Group with other plants or add a pebble tray to raise humidity.",
    ];
    return SurfaceCard(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Treatment plan',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: PP.pale2,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PP.forest)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(steps[i],
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            if (i != steps.length - 1) const SizedBox(height: 11),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: PP.pale1,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: const Text('Add these as reminders',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: PP.forest)),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          decoration: BoxDecoration(
            color: m.me ? PP.ink : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(26),
              topRight: const Radius.circular(26),
              bottomLeft: Radius.circular(m.me ? 26 : 8),
              bottomRight: Radius.circular(m.me ? 8 : 26),
            ),
          ),
          child: Text(m.text,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: m.me ? PP.bone : PP.ink)),
        ),
      ),
    );
  }

  Widget _composer() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          22, 0, 22, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                  color: PP.field, shape: BoxShape.circle),
              child: const Icon(LucideIcons.plus, size: 19, color: PP.ink),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: _draft,
                onSubmitted: (_) => _send(),
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Ask a follow-up…',
                  hintStyle: TextStyle(
                      color: PP.inkA(0.4), fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 9),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                    color: PP.ink, shape: BoxShape.circle),
                child: const Icon(LucideIcons.arrowRight,
                    size: 19, color: PP.lime),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
