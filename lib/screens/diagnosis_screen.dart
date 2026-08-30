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
  const DiagnosisScreen({super.key, this.sessionId, this.plantName});

  /// Drives a real `/diagnosis/{id}` session. Every entry point (scan, plant
  /// detail) creates a session first and passes its id here.
  final String? sessionId;

  /// Shown in the header so the user knows which plant is being discussed.
  final String? plantName;

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _api = PlantPalApi.instance;
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _loading = false;

  bool get _live => widget.sessionId != null && widget.sessionId!.isNotEmpty;

  final List<_Msg> _chat = [];

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
    setState(() => _loading = true);
    try {
      final session = await _api.diagnosisHistory(widget.sessionId!);
      if (!mounted) return;
      setState(() {
        _chat
          ..clear()
          ..addAll(session.messages.map((m) => _Msg(m.text, me: m.fromUser)));
      });
      _jump();
    } catch (_) {
      // Keep whatever the start response already showed.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty || _sending || !_live) return;
    setState(() {
      _chat.add(_Msg(text, me: true));
      _draft.clear();
      _sending = true;
    });
    _jump();

    try {
      final session = await _api.sendDiagnosisMessage(widget.sessionId!, text);
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: PP.track(15, -0.02))),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: _live ? PP.lime : PP.inkA(0.3),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                  _live
                                      ? 'Session open${widget.plantName != null && widget.plantName!.isNotEmpty ? ' · ${widget.plantName}' : ''}'
                                      : 'Start a scan to open a session',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: PP.forest)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: PP.plantImage,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.stethoscope,
                        size: 19, color: PP.forest),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading && _chat.isEmpty
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: PP.forest),
                      ),
                    )
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
                      children: [
                        if (_live)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 190,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: PP.plantImage,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(26),
                                      topRight: Radius.circular(26),
                                      bottomLeft: Radius.circular(26),
                                      bottomRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Icon(LucideIcons.image,
                                      size: 46,
                                      color:
                                          PP.forest.withValues(alpha: 0.4)),
                                ),
                                const SizedBox(height: 5),
                                Text('Photo sent to the plant doctor',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: PP.inkA(0.4))),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (_chat.isEmpty && !_sending)
                          _softNote(_live
                              ? 'Reading your photo…'
                              : 'Open the Scan tab and choose Diagnose to start.'),
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

  Widget _softNote(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: PP.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: PP.inkA(0.55))),
      );

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
    final canSend = _live && !_sending;
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 6),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 110),
                child: TextField(
                  controller: _draft,
                  minLines: 1,
                  maxLines: 4,
                  enabled: canSend,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                    hintText: 'Ask a follow-up…',
                    hintStyle: TextStyle(
                        color: PP.inkA(0.4), fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            GestureDetector(
              onTap: canSend ? _send : null,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: canSend ? PP.ink : PP.inkA(0.35),
                    shape: BoxShape.circle),
                child:
                    const Icon(LucideIcons.arrowRight, size: 19, color: PP.lime),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
