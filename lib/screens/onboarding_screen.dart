import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      headline: 'Meet your plants',
      body: 'Snap a photo and instantly identify any plant species in seconds.',
      // TODO: replace placeholder image — target: photo of phone camera
      // scanning a real plant, similar framing to reference screenshot's
      // AR-badge photo screen
      placeholderIcon: LucideIcons.camera,
      placeholderLabel: 'Plant Identification',
    ),
    _SlideData(
      headline: 'Catch problems early',
      body:
          'Upload a photo of a sick plant and chat with AI to diagnose and treat it.',
      // TODO: replace placeholder image — target: photo of a leaf with
      // diagnostic overlay badges (disease/pest highlight), echoing the
      // circular progress-ring badge style from the reference app
      placeholderIcon: LucideIcons.stethoscope,
      placeholderLabel: 'Diagnosis & Chat',
    ),
    _SlideData(
      headline: 'Never miss a watering',
      body:
          'Get personalized care plans and reminders tailored to every plant you own.',
      // TODO: replace placeholder image — target: photo of a healthy potted
      // plant with a watering-can icon or reminder badge overlay
      placeholderIcon: LucideIcons.droplets,
      placeholderLabel: 'Care & Reminders',
    ),
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _onSkip() {
    widget.onComplete();
  }

  void _onLogIn() {
    Navigator.of(context).pushNamed('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _currentPage == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sageTop, AppColors.sageBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 24),
                  child: TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.cream.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) =>
                      _OnboardingSlide(data: _slides[index]),
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                child: Column(
                  children: [
                    // Dot indicators
                    _DotIndicator(
                      count: _slides.length,
                      currentIndex: _currentPage,
                    ),

                    const SizedBox(height: 32),

                    // Primary button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBg,
                          foregroundColor: AppColors.buttonLabel,
                          shape: const StadiumBorder(),
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          isLastSlide ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    // Log in link — only on last slide
                    if (isLastSlide) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _onLogIn,
                        child: Text(
                          'Already have an account? Log in',
                          style: TextStyle(
                            color: AppColors.cream.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Slide widget
// ---------------------------------------------------------------------------

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.slideHorizontalPadding,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Hero placeholder image
          Expanded(
            flex: 5,
            child: AspectRatio(
              aspectRatio: AppDimensions.heroAspectRatio,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      data.placeholderIcon,
                      size: 64,
                      color: AppColors.accentGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.placeholderLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Headline
          Text(
            data.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 12),

          // Body
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.cream.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot indicator
// ---------------------------------------------------------------------------

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.currentIndex});
  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accentGreen
                : AppColors.dotMuted,
            borderRadius: const BorderRadius.all(AppRadius.pill),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide data model
// ---------------------------------------------------------------------------

class _SlideData {
  const _SlideData({
    required this.headline,
    required this.body,
    required this.placeholderIcon,
    required this.placeholderLabel,
  });
  final String headline;
  final String body;
  final IconData placeholderIcon;
  final String placeholderLabel;
}
