import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// =============================================================================
// LOCAL HISTORY STORE (⚠️ client-side only — no server list endpoint)
// =============================================================================

class DiagnosisHistoryStore {
  static final List<DiagnosisHistoryEntry> _entries = [];

  static List<DiagnosisHistoryEntry> get entries => List.unmodifiable(_entries);

  static void add(DiagnosisHistoryEntry entry) {
    _entries.removeWhere((e) => e.sessionId == entry.sessionId);
    _entries.insert(0, entry);
  }

  static void remove(String sessionId) {
    _entries.removeWhere((e) => e.sessionId == sessionId);
  }
}

class DiagnosisHistoryEntry {
  final String sessionId;
  final String? imagePath;
  final String? summary;
  final DateTime createdAt;

  DiagnosisHistoryEntry({
    required this.sessionId,
    this.imagePath,
    this.summary,
    required this.createdAt,
  });
}

// =============================================================================
// SCREEN 20: DIAGNOSE CAPTURE
// =============================================================================

class DiagnoseCaptureScreen extends StatefulWidget {
  const DiagnoseCaptureScreen({super.key});

  @override
  State<DiagnoseCaptureScreen> createState() => _DiagnoseCaptureScreenState();
}

class _DiagnoseCaptureScreenState extends State<DiagnoseCaptureScreen> {
  bool _flashOn = false;
  final Set<String> _selectedSymptoms = {};

  static const _symptomChips = [
    'Yellow leaves',
    'Brown spots',
    'Wilting',
    'Brown stems',
  ];

  Future<File> _createPlaceholderImage() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/diagnosis_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
    return file;
  }

  Future<void> _onCapture() async {
    final file = await _createPlaceholderImage();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DiagnosisStartingScreen(
          imageFile: file,
          symptomHints: _selectedSymptoms.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        // Camera viewfinder placeholder
        Container(
          color: const Color(0xFF2A1A1A),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.camera, color: Colors.white24, size: 80),
              SizedBox(height: 12),
              Text('Camera preview', style: TextStyle(color: Colors.white24, fontSize: 14)),
            ]),
          ),
        ),

        // Amber/red framing guide
        Center(
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFA726).withValues(alpha: 0.5), width: 1.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(children: [
              Positioned(top: -1, left: -1, child: _DiagCornerBracket(tl: true)),
              Positioned(top: -1, right: -1, child: _DiagCornerBracket(tr: true)),
              Positioned(bottom: -1, left: -1, child: _DiagCornerBracket(bl: true)),
              Positioned(bottom: -1, right: -1, child: _DiagCornerBracket(br: true)),
            ]),
          ),
        ),

        // Helper text
        Positioned(
          bottom: 190, left: 0, right: 0,
          child: Center(child: Text(
            'Get close to the affected leaves or stems',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
          )),
        ),

        // Symptom chips
        Positioned(
          bottom: 140, left: 0, right: 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _symptomChips.map((s) {
                final selected = _selectedSymptoms.contains(s);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      selected ? _selectedSymptoms.remove(s) : _selectedSymptoms.add(s);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFFFA726) : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(s, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Top bar: back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 12, left: 20,
          child: _DiagCircleButton(icon: LucideIcons.x, onTap: () => Navigator.of(context).pop()),
        ),

        // Bottom control bar
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DiagCircleButton(icon: LucideIcons.image, size: 44,
                    onTap: _onCapture),
                GestureDetector(
                  onTap: _onCapture,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 58, height: 58,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF6F00),
                        ),
                      ),
                    ),
                  ),
                ),
                _DiagCircleButton(
                  icon: _flashOn ? LucideIcons.zap : LucideIcons.zapOff,
                  size: 44,
                  onTap: () => setState(() => _flashOn = !_flashOn),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// SCREEN 21: DIAGNOSIS SESSION STARTING
// =============================================================================

class DiagnosisStartingScreen extends StatefulWidget {
  const DiagnosisStartingScreen({super.key, required this.imageFile, this.symptomHints = const []});
  final File imageFile;
  final List<String> symptomHints;

  @override
  State<DiagnosisStartingScreen> createState() => _DiagnosisStartingScreenState();
}

class _DiagnosisStartingScreenState extends State<DiagnosisStartingScreen> {
  int _statusIndex = 0;
  Timer? _statusTimer;
  bool _hasError = false;
  String? _errorMsg;

  static const _statuses = [
    'Examining the photo...',
    'Comparing symptoms...',
    'Preparing your diagnosis...',
  ];

  @override
  void initState() {
    super.initState();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _statusIndex = (_statusIndex + 1) % _statuses.length);
    });
    _startDiagnosis();
  }

  @override
  void dispose() { _statusTimer?.cancel(); super.dispose(); }

  Future<void> _startDiagnosis() async {
    setState(() { _hasError = false; _errorMsg = null; });
    try {
      final body = await AuthService.startDiagnosis(widget.imageFile);
      if (!mounted) return;

      // Parse session id defensively
      final sessionId = (body['session_id'] ?? body['id'] ?? '').toString();
      if (sessionId.isEmpty) { _showError('Invalid response'); return; }

      // Persist local history entry
      DiagnosisHistoryStore.add(DiagnosisHistoryEntry(
        sessionId: sessionId,
        imagePath: widget.imageFile.path,
        summary: _extractSummary(body),
        createdAt: DateTime.now(),
      ));

      // Prepend symptom hints as context if selected
      String initialContent = _extractContent(body);
      if (widget.symptomHints.isNotEmpty && initialContent.isNotEmpty) {
        initialContent = 'Observed symptoms: ${widget.symptomHints.join(", ")}.\n\n$initialContent';
      }

      _statusTimer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiagnosisChatScreen(
            sessionId: sessionId,
            initialMessages: [
              ChatMessage(role: 'ai', content: initialContent),
            ],
          ),
        ),
      );
    } on ApiException catch (e) {
      _statusTimer?.cancel();
      if (e.statusCode == 429) {
        _goBackWith('Too many diagnoses right now — please wait a moment and try again.');
      } else if (e.statusCode == 400) {
        _goBackWith("Couldn't read that image — try a clearer, closer photo.");
      } else {
        _showError('Something went wrong');
      }
    } catch (_) {
      _statusTimer?.cancel();
      _showError('Something went wrong');
    }
  }

  void _goBackWith(String msg) {
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    if (mounted) setState(() { _hasError = true; _errorMsg = msg; });
  }

  String _extractContent(Map<String, dynamic> body) {
    for (final key in ['diagnosis', 'message', 'content', 'text', 'summary', 'result']) {
      final val = body[key];
      if (val is String && val.isNotEmpty) return val;
      if (val is Map) return jsonEncode(val);
    }
    return jsonEncode(body);
  }

  String? _extractSummary(Map<String, dynamic> body) {
    for (final key in ['condition', 'diagnosis', 'summary', 'result']) {
      final val = body[key];
      if (val is String && val.isNotEmpty) return val.length > 100 ? '${val.substring(0, 100)}...' : val;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A1A1A),
      body: SafeArea(
        child: Column(children: [
          const Spacer(flex: 2),
          Center(
            child: Container(
              width: 260, padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.cream, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24)],
              ),
              child: _hasError ? _buildErrorContent() : _buildLoadingContent(),
            ),
          ),
          const Spacer(flex: 3),
          if (!_hasError)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15)),
            ),
        ]),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Stethoscope placeholder icon
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.1), shape: BoxShape.circle,
        ),
        child: Center(child: Icon(LucideIcons.stethoscope, size: 32, color: AppColors.accentGreen)),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: 28, height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accentGreen),
      ),
      const SizedBox(height: 16),
      Text(_statuses[_statusIndex],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
    ]);
  }

  Widget _buildErrorContent() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(LucideIcons.alertCircle, color: Color(0xFFE53935), size: 40),
      const SizedBox(height: 12),
      Text(_errorMsg ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 44,
        child: ElevatedButton(
          onPressed: _startDiagnosis,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: const Text('Try Again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Go Back', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
      ),
    ]);
  }
}

// =============================================================================
// SCREEN 22: DIAGNOSIS CHAT THREAD
// =============================================================================

class DiagnosisChatScreen extends StatefulWidget {
  const DiagnosisChatScreen({super.key, required this.sessionId, this.initialMessages = const [], this.titleDate});
  final String sessionId;
  final List<ChatMessage> initialMessages;
  final DateTime? titleDate;

  @override
  State<DiagnosisChatScreen> createState() => _DiagnosisChatScreenState();
}

class _DiagnosisChatScreenState extends State<DiagnosisChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late List<ChatMessage> _messages;
  bool _isLoadingHistory = false;
  bool _isSending = false;
  String? _error;

  // ignore: unused_field
  static const _quickReplies = [
    'How often should I water it now?',
    'Is this contagious to other plants?',
    'What treatment should I start?',
  ];

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.initialMessages);
    if (_messages.isEmpty) _loadHistory();
  }

  @override
  void dispose() { _inputCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final body = await AuthService.getDiagnosis(widget.sessionId);
      if (!mounted) return;

      // Parse messages defensively
      final messages = <ChatMessage>[];
      for (final key in ['messages', 'history', 'chat', 'conversation']) {
        if (body[key] is List) {
          for (final m in body[key] as List) {
            if (m is Map) {
              final role = (m['role'] ?? m['sender'] ?? m['type'] ?? 'ai').toString();
              final content = (m['content'] ?? m['message'] ?? m['text'] ?? '').toString();
              if (content.isNotEmpty) {
                messages.add(ChatMessage(
                  role: role.contains('user') ? 'user' : 'ai',
                  content: content,
                ));
              }
            }
          }
          break;
        }
      }

      setState(() { _messages = messages; _isLoadingHistory = false; });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Session expired — show degraded state
        DiagnosisHistoryStore.remove(widget.sessionId);
        if (mounted) {
          setState(() => _isLoadingHistory = false);
          _showSessionExpired();
        }
      } else {
        if (mounted) setState(() { _isLoadingHistory = false; _error = 'Failed to load chat'; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoadingHistory = false; _error = 'Failed to load chat'; });
    }
  }

  void _showSessionExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Session unavailable'),
        content: const Text('This diagnosis session is no longer available.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DiagnoseCaptureScreen()),
                (r) => r.isFirst,
              );
            },
            child: const Text('Start New Diagnosis'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final body = await AuthService.sendDiagnosisMessage(widget.sessionId, text);
      if (!mounted) return;

      final reply = _extractReply(body);
      setState(() {
        _messages.add(ChatMessage(role: 'ai', content: reply));
        _isSending = false;
      });
      _scrollToBottom();
    } on ApiException catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'error', content: "Couldn't send that — try again."));
          _isSending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'error', content: "Couldn't send that — try again."));
          _isSending = false;
        });
      }
    }
  }

  String _extractReply(Map<String, dynamic> body) {
    for (final key in ['reply', 'message', 'content', 'text', 'response', 'answer']) {
      final val = body[key];
      if (val is String && val.isNotEmpty) return val;
      if (val is Map) return jsonEncode(val);
    }
    return jsonEncode(body);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageBase,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: AppColors.cream,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.sageBase.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plant Diagnosis', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (widget.titleDate != null)
                    Text(_formatDate(widget.titleDate!), style: TextStyle(fontSize: 11, color: AppColors.textPrimary.withValues(alpha: 0.4))),
                ],
              )),
              // Delete from history
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') {
                    DiagnosisHistoryStore.remove(widget.sessionId);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from history')));
                  }
                },
                itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('Delete from history'))],
                icon: const Icon(LucideIcons.circleEllipsis, size: 20),
              ),
            ]),
          ),

          // Chat body
          Expanded(child: _isLoadingHistory
              ? _buildSkeleton()
              : _error != null
                  ? _buildError()
                  : _buildChatList()),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(color: AppColors.cream, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask a follow-up question...',
                    hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3)),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _inputCtrl.text.trim().isEmpty ? AppColors.buttonBg.withValues(alpha: 0.3) : AppColors.buttonBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        return _buildBubble(_messages[i]);
      },
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    final isError = msg.role == 'error';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isError ? const Color(0xFFFDECEA) : AppColors.cream,
                shape: BoxShape.circle,
                border: isError ? null : Border.all(color: AppColors.sageBase),
              ),
              child: Center(child: Icon(isError ? LucideIcons.alertTriangle : LucideIcons.leaf, size: 16, color: isError ? Color(0xFFE53935) : AppColors.accentGreen)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.accentDark
                    : isError
                        ? const Color(0xFFFDECEA)
                        : AppColors.cream,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser
                      ? Colors.white
                      : isError
                          ? const Color(0xFFD32F2F)
                          : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: AppColors.cream, shape: BoxShape.circle, border: Border.all(color: AppColors.sageBase)),
          child: const Center(child: Icon(LucideIcons.leaf, size: 16, color: AppColors.accentGreen)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(18)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _PulsingDot(delay: 0), const SizedBox(width: 4),
            _PulsingDot(delay: 200), const SizedBox(width: 4),
            _PulsingDot(delay: 400),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 4,
      itemBuilder: (_, i) {
        final isRight = i % 2 == 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isRight) Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.3), shape: BoxShape.circle)),
              if (!isRight) const SizedBox(width: 8),
              Container(
                width: 180 + (i * 20.0), height: 48,
                decoration: BoxDecoration(
                  color: isRight ? AppColors.accentDark.withValues(alpha: 0.3) : AppColors.cream.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(child: Text(_error!, style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.5))));
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// =============================================================================
// SCREEN 23: DIAGNOSIS HISTORY (⚠️ local-only)
// =============================================================================

class DiagnosisHistoryScreen extends StatefulWidget {
  const DiagnosisHistoryScreen({super.key});

  @override
  State<DiagnosisHistoryScreen> createState() => _DiagnosisHistoryScreenState();
}

class _DiagnosisHistoryScreenState extends State<DiagnosisHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // ⚠️ Local-only history — no server-backed list endpoint exists
    final entries = DiagnosisHistoryStore.entries;

    return Scaffold(
      backgroundColor: AppColors.sageBase,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.25), shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_left_rounded, color: AppColors.cream, size: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Diagnosis History',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.cream))),
            ]),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(child: entries.isEmpty ? _buildEmpty() : _buildList(entries)),
        ]),
      ),
    );
  }

  Widget _buildList(List<DiagnosisHistoryEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return Dismissible(
          key: ValueKey(e.sessionId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.trash2, color: Colors.white),
          ),
          onDismissed: (_) {
            setState(() => DiagnosisHistoryStore.remove(e.sessionId));
          },
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DiagnosisChatScreen(
                  sessionId: e.sessionId,
                  titleDate: e.createdAt,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                // Thumbnail
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.sageBase, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Icon(LucideIcons.stethoscope, size: 24, color: AppColors.accentGreen)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.summary ?? 'Plant Diagnosis',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_relativeTime(e.createdAt),
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.4))),
                  ],
                )),
                Icon(LucideIcons.chevronRight, color: AppColors.textPrimary.withValues(alpha: 0.3), size: 20),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(LucideIcons.search, size: 56, color: AppColors.cream),
        const SizedBox(height: 16),
        const Text('No past diagnoses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.cream)),
        const SizedBox(height: 8),
        Text('Start a diagnosis to see it here',
            style: TextStyle(fontSize: 14, color: AppColors.cream.withValues(alpha: 0.6))),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiagnoseCaptureScreen()));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
          child: const Text('New Diagnosis'),
        ),
      ]),
    ));
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// =============================================================================
// Chat message model
// =============================================================================

class ChatMessage {
  final String role; // 'user', 'ai', 'error'
  final String content;
  ChatMessage({required this.role, required this.content});
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _DiagCircleButton extends StatelessWidget {
  const _DiagCircleButton({required this.icon, required this.onTap, this.size = 44});
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: size, height: size,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: size * 0.45)),
    );
  }
}

class _DiagCornerBracket extends StatelessWidget {
  const _DiagCornerBracket({this.tl = false, this.tr = false, this.bl = false, this.br = false});
  final bool tl, tr, bl, br;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24),
        painter: _DiagBracketPainter(tl: tl, tr: tr, bl: bl, br: br));
  }
}

class _DiagBracketPainter extends CustomPainter {
  const _DiagBracketPainter({this.tl = false, this.tr = false, this.bl = false, this.br = false});
  final bool tl, tr, bl, br;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFA726).withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (tl) { path.moveTo(0, size.height * 0.6); path.lineTo(0, 0); path.lineTo(size.width * 0.6, 0); }
    if (tr) { path.moveTo(size.width * 0.4, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height * 0.6); }
    if (bl) { path.moveTo(0, size.height * 0.4); path.lineTo(0, size.height); path.lineTo(size.width * 0.6, size.height); }
    if (br) { path.moveTo(size.width * 0.4, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, size.height * 0.4); }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({this.delay = 0});
  final int delay;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        width: 6 + (_ctrl.value * 2),
        height: 6 + (_ctrl.value * 2),
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.2 + _ctrl.value * 0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
