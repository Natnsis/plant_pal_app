import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// =============================================================================
// SCREEN 16: CAMERA CAPTURE
// =============================================================================

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  bool _flashOn = false;
  String? _errorBanner;

  // TODO: wire real camera SDK per platform
  // For now, simulate capture with a placeholder that "creates" a fake image file
  Future<void> _onCapture() async {
    // Simulate captured image — in production, get this from the camera SDK
    final fakeFile = await _createPlaceholderImage();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ScanAnalyzingScreen(imageFile: fakeFile)),
    );
  }

  Future<void> _onGalleryPick() async {
    // TODO: wire real image_picker for gallery selection
    final fakeFile = await _createPlaceholderImage();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ScanAnalyzingScreen(imageFile: fakeFile)),
    );
  }

  Future<File> _createPlaceholderImage() async {
    // Create a minimal placeholder file for the multipart upload
    // In production, this would be the actual captured/selected image
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/plant_scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // minimal JPEG header
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        // Camera viewfinder placeholder
        Container(
          color: const Color(0xFF1A2A1C),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.camera, color: Colors.white24, size: 80),
              SizedBox(height: 12),
              Text('Camera preview', style: TextStyle(color: Colors.white24, fontSize: 14)),
            ]),
          ),
        ),

        // Framing guide overlay
        Center(
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(children: [
              // Corner brackets
              Positioned(top: -1, left: -1, child: _CornerBracket(tl: true)),
              Positioned(top: -1, right: -1, child: _CornerBracket(tr: true)),
              Positioned(bottom: -1, left: -1, child: _CornerBracket(bl: true)),
              Positioned(bottom: -1, right: -1, child: _CornerBracket(br: true)),
            ]),
          ),
        ),

        // Helper text
        Positioned(
          bottom: 160, left: 0, right: 0,
          child: Center(child: Text(
            'Center the plant in frame',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
          )),
        ),

        // Top bar: back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 12, left: 20,
          child: _ScanCircleButton(
            icon: LucideIcons.x,
            onTap: () => Navigator.of(context).pop(),
          ),
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
                // Gallery button
                _ScanCircleButton(
                  icon: LucideIcons.image,
                  size: 44,
                  onTap: _onGalleryPick,
                ),

                // Shutter button
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
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                ),

                // Flash toggle
                _ScanCircleButton(
                  icon: _flashOn ? LucideIcons.zap : LucideIcons.zapOff,
                  size: 44,
                  onTap: () => setState(() => _flashOn = !_flashOn),
                ),
              ],
            ),
          ),
        ),

        // Error banner
        if (_errorBanner != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 20, right: 20,
            child: _ErrorBanner(message: _errorBanner!, onDismiss: () => setState(() => _errorBanner = null)),
          ),
      ]),
    );
  }
}

// =============================================================================
// SCREEN 17: SCAN ANALYZING
// =============================================================================

class ScanAnalyzingScreen extends StatefulWidget {
  const ScanAnalyzingScreen({super.key, required this.imageFile});
  final File imageFile;

  @override
  State<ScanAnalyzingScreen> createState() => _ScanAnalyzingScreenState();
}

class _ScanAnalyzingScreenState extends State<ScanAnalyzingScreen> {
  int _statusIndex = 0;
  Timer? _statusTimer;
  bool _hasError = false;
  String? _errorMsg;
  final bool _isRetrying = false;

  static const _statuses = [
    'Analyzing leaf patterns...',
    'Checking species database...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _statusIndex = (_statusIndex + 1) % _statuses.length);
    });
    _submitScan();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitScan() async {
    setState(() { _hasError = false; _errorMsg = null; });
    try {
      final body = await AuthService.submitScan(widget.imageFile);
      if (!mounted) return;

      final scan = Scan.fromJson(body);
      if (scan.id == 0) {
        _showError('Invalid response from server');
        return;
      }

      _statusTimer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ScanResultScreen(scan: scan)),
      );
    } on ApiException catch (e) {
      _statusTimer?.cancel();
      if (e.statusCode == 429) {
        _goBackWithMessage('Too many scans right now — please wait a moment and try again.');
      } else if (e.statusCode == 400) {
        _goBackWithMessage("Couldn't read that image — try a clearer photo.");
      } else {
        _showError('Something went wrong');
      }
    } catch (_) {
      _statusTimer?.cancel();
      _showError('Something went wrong');
    }
  }

  void _goBackWithMessage(String msg) {
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    if (mounted) setState(() { _hasError = true; _errorMsg = msg; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A1C),
      body: SafeArea(
        child: Column(children: [
          const Spacer(flex: 2),

          // Analyzing card
          Center(
            child: Container(
              width: 260, padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.cream, borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24)],
              ),
              child: _hasError ? _buildErrorContent() : _buildAnalyzingContent(),
            ),
          ),

          const Spacer(flex: 3),

          // Cancel link
          if (!_hasError && !_isRetrying)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15)),
            ),
        ]),
      ),
    );
  }

  Widget _buildAnalyzingContent() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Pulsing leaf
      SizedBox(width: 64, height: 64,
        child: CircularProgressIndicator(
          strokeWidth: 3, color: AppColors.accentGreen,
          backgroundColor: AppColors.accentGreen.withValues(alpha: 0.15),
        ),
      ),
      const SizedBox(height: 20),
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
          onPressed: _isRetrying ? null : _submitScan,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: _isRetrying
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Try Again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
// SCREEN 18: SCAN RESULT / PREVIEW
// =============================================================================

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, required this.scan});
  final Scan scan;

  @override
  Widget build(BuildContext context) {
    final name = scan.commonName ?? 'Unknown Plant';
    final sciName = scan.scientificName;
    final confidence = scan.confidenceScore;
    final desc = scan.description;
    final isLowConfidence = confidence != null && confidence < 50;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Hero image
          Stack(children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [AppColors.sageTop, AppColors.sageBase]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: const Center(child: Icon(LucideIcons.leaf, size: 80, color: AppColors.accentGreen)),
            ),
            // Back button
            Positioned(top: MediaQuery.of(context).padding.top + 12, left: 16,
                child: _ScanCircleButton(
                  icon: LucideIcons.chevronLeft,
                  onTap: () => Navigator.of(context).pop(),
                )),
            // Confidence badge
            if (confidence != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12, right: 16,
                child: _ConfidenceBadge(score: confidence),
              ),
          ]),

          // Plant info
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (sciName != null) ...[
                const SizedBox(height: 4),
                Text(sciName, style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: AppColors.textPrimary.withValues(alpha: 0.5))),
              ],
              if (desc != null && desc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(desc, style: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.6), height: 1.5)),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Not the right plant? Retake Photo",
                    style: TextStyle(fontSize: 14, color: AppColors.accentGreen)),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Low confidence warning
          if (isLowConfidence)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(LucideIcons.alertTriangle, color: Color(0xFFFFA726), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    "We're not fully confident in this match — double check before continuing.",
                    style: TextStyle(fontSize: 13, color: const Color(0xFFE65100).withValues(alpha: 0.8)),
                  )),
                ]),
              ),
            ),

          // CTA button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ConfirmScanScreen(scan: scan)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel,
                  shape: const StadiumBorder(), elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                ),
                child: const Text('Looks Good — Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// =============================================================================
// SCREEN 19: CONFIRM SCAN
// =============================================================================

class ConfirmScanScreen extends StatefulWidget {
  const ConfirmScanScreen({super.key, required this.scan});
  final Scan scan;

  @override
  State<ConfirmScanScreen> createState() => _ConfirmScanScreenState();
}

class _ConfirmScanScreenState extends State<ConfirmScanScreen> {
  late TextEditingController _nicknameCtrl;
  final _locationCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill nickname with identified common name
    _nicknameCtrl = TextEditingController(text: widget.scan.commonName ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_nicknameCtrl.text.trim().isEmpty) return;
    setState(() { _isSubmitting = true; _error = null; });

    try {
      final body = await AuthService.confirmScan(
        widget.scan.id,
        nickname: _nicknameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
      );

      if (!mounted) return;

      final plantId = body['id'] ?? body['plant_id'] ?? body['plant']?['id'];
      if (plantId != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => _PlantDetailPlaceholder(plantId: plantId is int ? plantId : int.tryParse(plantId.toString()) ?? 0)),
          (route) => route.isFirst,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🌿 ${_nicknameCtrl.text} added to your plants!')),
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌿 Plant added to your plants!')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404) {
        setState(() => _error = 'This scan has expired — please scan again.');
      } else {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't reach PlantPal. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.scan.commonName ?? 'Plant';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.sageBase.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 24),
              ),
            ),

            const SizedBox(height: 24),

            const Text('Add to your collection',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),

            const SizedBox(height: 20),

            // Species recap card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06)),
              ),
              child: Row(children: [
                Container(width: 52, height: 52,
                    decoration: BoxDecoration(color: AppColors.sageBase, borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Icon(LucideIcons.leaf, size: 26, color: AppColors.accentGreen))),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    if (widget.scan.scientificName != null)
                      Text(widget.scan.scientificName!,
                          style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textPrimary.withValues(alpha: 0.5))),
                  ],
                )),
                if (widget.scan.confidenceScore != null)
                  _ConfidenceBadge(score: widget.scan.confidenceScore!),
              ]),
            ),

            const SizedBox(height: 28),

            // Error banner
            if (_error != null) ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(16)),
                child: Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFD32F2F), fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 16),
            ],

            // Nickname field
            const _FieldLabel('Nickname'),
            TextField(
              controller: _nicknameCtrl,
              enabled: !_isSubmitting,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _inputDecoration('e.g. Living Room Fig'),
            ),

            const SizedBox(height: 16),

            // Location field
            const _FieldLabel('Location'),
            TextField(
              controller: _locationCtrl,
              enabled: !_isSubmitting,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _inputDecoration('e.g. Living Room, Balcony'),
            ),

            const SizedBox(height: 32),

            // Add Plant button
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting || _nicknameCtrl.text.trim().isEmpty ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel,
                  disabledBackgroundColor: AppColors.buttonBg.withValues(alpha: 0.4),
                  shape: const StadiumBorder(),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Add Plant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                "We'll set up a personalized care plan and reminders for you automatically.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.4)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3)),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.accentGreen, width: 1.5)),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _ScanCircleButton extends StatelessWidget {
  const _ScanCircleButton({required this.icon, required this.onTap, this.size = 44});
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(LucideIcons.alertCircle, color: Color(0xFFD32F2F), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFFD32F2F), fontWeight: FontWeight.w500))),
        GestureDetector(onTap: onDismiss, child: const Icon(LucideIcons.x, size: 18, color: Color(0xFFD32F2F))),
      ]),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.score});
  final double score;

  Color get _color {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 50) return const Color(0xFFFFA726);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cream, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: SizedBox(
        width: 40, height: 40,
        child: Stack(fit: StackFit.expand, children: [
          CircularProgressIndicator(value: score / 100, strokeWidth: 3,
              backgroundColor: _color.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation(_color)),
          Center(child: Text('${score.round()}%',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _color))),
        ]),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({this.tl = false, this.tr = false, this.bl = false, this.br = false});
  final bool tl, tr, bl, br;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _BracketPainter(tl: tl, tr: tr, bl: bl, br: br));
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({this.tl = false, this.tr = false, this.bl = false, this.br = false});
  final bool tl, tr, bl, br;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)));
  }
}

// =============================================================================
// PLACEHOLDER: navigates to Plant Detail after scan confirm
// =============================================================================

class _PlantDetailPlaceholder extends StatelessWidget {
  const _PlantDetailPlaceholder({required this.plantId});
  final int plantId;

  @override
  Widget build(BuildContext context) {
    // Reuses the existing PlantDetailScreen from main.dart routing
    // This is used when navigating from scan confirm
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.leaf, size: 64, color: AppColors.accentGreen),
          const SizedBox(height: 16),
          Text('Loading plant #$plantId...', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
            child: const Text('Go to Home'),
          ),
        ]),
      ),
    );
  }
}
