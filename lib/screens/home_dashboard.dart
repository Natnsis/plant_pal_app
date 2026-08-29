import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// New design system constants
const _creamBg = Color(0xFFF4F3EC);
const _forestGreen = Color(0xFF2F4A3C);
const _forestGreenLight = Color(0xFF3D6352);
const _textDark = Color(0xFF1A1A1A);
const _textMuted = Color(0xFF8E8E8E);
const _cardWhite = Color(0xFFFFFFFF);
const _cardShadow = Color(0x0D000000);
const _accentGreen = Color(0xFF4CAF64);
const _redBadge = Color(0xFFE53935);

IconData _weatherIcon(String code) {
  if (code.contains('rain') || code.contains('drizzle')) return LucideIcons.cloudRain;
  if (code.contains('cloud')) return LucideIcons.cloud;
  if (code.contains('thunder')) return LucideIcons.cloudLightning;
  if (code.contains('snow')) return LucideIcons.snowflake;
  if (code.contains('fog') || code.contains('mist')) return LucideIcons.cloudFog;
  return LucideIcons.sun;
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _navIndex = 0;
  PlantUser? _user;
  List<Reminder> _reminders = [];
  WeatherForecast? _weather;
  bool _weatherFailed = false;
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshUnreadCount();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        AuthService.getMe(),
        AuthService.getTodayReminders(),
        AuthService.getWeather().catchError((_) => null),
        AuthService.getUnreadNotificationCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = PlantUser.fromJson(results[0] as Map<String, dynamic>);
        _reminders = (results[1] as List)
            .map((r) => Reminder.fromJson(r as Map<String, dynamic>))
            .toList();
        if (results[2] != null) {
          _weather = WeatherForecast.fromJson(results[2] as Map<String, dynamic>);
        } else {
          _weatherFailed = true;
        }
        _unreadCount = results[3] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Couldn\'t load your dashboard'; _isLoading = false; });
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await AuthService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _completeReminder(Reminder reminder) async {
    setState(() { _reminders.removeWhere((r) => r.id == reminder.id); });
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    setState(() => _navIndex = index);
    switch (index) {
      case 0: break;
      case 1: Navigator.of(context).pushNamed('/diagnose'); break;
      case 2: Navigator.of(context).pushNamed('/scan'); break;
      case 3: Navigator.of(context).pushNamed('/community'); break;
      case 4: Navigator.of(context).pushNamed('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingSkeleton();
    if (_error != null) return _buildErrorState();
    return _buildContent();
  }

  // Loading skeleton
  Widget _buildLoadingSkeleton() {
    return const Scaffold(
      backgroundColor: _creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(width: 200, height: 28),
              SizedBox(height: 8),
              _SkeletonBlock(width: 140, height: 16),
              SizedBox(height: 24),
              _SkeletonBlock(width: double.infinity, height: 160),
              SizedBox(height: 24),
              _SkeletonBlock(width: 160, height: 20),
              SizedBox(height: 12),
              _SkeletonBlock(width: double.infinity, height: 80),
              SizedBox(height: 10),
              _SkeletonBlock(width: double.infinity, height: 80),
              SizedBox(height: 10),
              _SkeletonBlock(width: double.infinity, height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Error state
  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: _creamBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.leaf, size: 64, color: _forestGreen),
                const SizedBox(height: 20),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textDark)),
                const SizedBox(height: 24),
                SizedBox(
                  width: 160, height: 48,
                  child: ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _forestGreen, foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Main content
  Widget _buildContent() {
    return Scaffold(
      backgroundColor: _creamBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 20),
                _buildWeatherCard(),
                const SizedBox(height: 28),
                _buildTodayTasks(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildMyPlants(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // Top bar: greeting + bell
  Widget _buildTopBar() {
    final name = _user?.firstName ?? 'there';
    final streak = _user?.careStreakDays ?? 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $name 👋',
                style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                streak > 0 ? '$streak-day care streak 🔥' : 'Start your streak today',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _textMuted),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/notifications'),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _cardWhite,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(LucideIcons.bell, color: _forestGreen, size: 22),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: _redBadge, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Weather card — large card with wavy organic top edge
  Widget _buildWeatherCard() {
    if (_weatherFailed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _cardShadow, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.cloudOff, color: _textMuted.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 10),
            Text('Weather unavailable', style: TextStyle(fontSize: 14, color: _textMuted.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    if (_weather?.current == null) {
      return const _SkeletonBlock(width: double.infinity, height: 180);
    }

    final current = _weather!.current!;
    final hourly = _weather!.hourly.take(6).toList();

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/weather'),
      child: Container(
        decoration: BoxDecoration(
          color: _forestGreen,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: _forestGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            // Top portion with organic wavy shape
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: CustomPaint(
                painter: _WavyTopPainter(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Row(
                    children: [
                      // Current weather info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_weatherIcon(current.icon), size: 36, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            '${current.temp.round()}°',
                            style: const TextStyle(
                              fontSize: 44, fontWeight: FontWeight.w700, color: Colors.white, height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${current.humidity.round()}% humidity',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Hourly strip
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: hourly.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final h = hourly[i];
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    h.hour,
                                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${h.temp.round()}°',
                                    style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom cream portion
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: _creamBg,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.cloudSun, size: 16, color: _forestGreen.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text(
                    'View full forecast',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _forestGreen.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Today's Tasks
  Widget _buildTodayTasks() {
    final incomplete = _reminders.where((r) => !r.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Today's Tasks",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
            ),
            const SizedBox(width: 8),
            Text(
              '${incomplete.length} pending',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _textMuted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (incomplete.isEmpty)
          _buildEmptyTasksState()
        else
          ...incomplete.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TaskCard(reminder: r, onComplete: () => _completeReminder(r)),
          )),
      ],
    );
  }

  Widget _buildEmptyTasksState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.leaf, size: 48, color: _accentGreen),
          const SizedBox(height: 12),
          const Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textDark)),
          const SizedBox(height: 4),
          const Text('No tasks due today.', style: TextStyle(fontSize: 14, color: _textMuted)),
        ],
      ),
    );
  }

  // Quick actions
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/scan'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _forestGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: _forestGreen.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.camera, color: Colors.white, size: 28),
                  const SizedBox(height: 12),
                  const Text('Scan a Plant',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Identify any species',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/diagnose'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _textDark.withValues(alpha: 0.08)),
                boxShadow: [BoxShadow(color: _cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.stethoscope, color: _forestGreen, size: 28),
                  const SizedBox(height: 12),
                  const Text('Diagnose',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textDark)),
                  const SizedBox(height: 4),
                  Text('Check plant health',
                      style: TextStyle(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // My Plants preview
  Widget _buildMyPlants() {
    final plants = _user?.plants ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('My Plants',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
            const Spacer(),
            if (plants.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/my-plants'),
                child: const Text('See all',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _forestGreen)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (plants.isEmpty)
          _buildAddFirstPlant()
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _PlantThumbCard(plant: plants[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildAddFirstPlant() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/scan'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _forestGreen.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [BoxShadow(color: _cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.sprout, size: 36, color: _forestGreen),
            const SizedBox(height: 8),
            const Text('Add your first plant',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _forestGreen)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Floating pill navigation bar
// =============================================================================

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavDef(LucideIcons.compass, 'Home'),
    _NavDef(LucideIcons.stethoscope, 'Diagnose'),
    _NavDef(LucideIcons.camera, 'Scan'),
    _NavDef(LucideIcons.bookOpen, 'Journal'),
    _NavDef(LucideIcons.user, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: _textDark,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isActive = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: isActive
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                    : const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      size: 22,
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavDef {
  const _NavDef(this.icon, this.label);
  final IconData icon;
  final String label;
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.reminder, required this.onComplete});
  final Reminder reminder;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/plant/${reminder.plantId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: _cardShadow, blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Circular icon avatar with pale-green fill
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _accentGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(LucideIcons.leaf, size: 22, color: _forestGreen),
              ),
            ),
            const SizedBox(width: 14),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.taskLabel,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reminder.plant?.nickname ?? 'Plant',
                    style: const TextStyle(fontSize: 13, color: _textMuted),
                  ),
                ],
              ),
            ),
            // Time + checkmark
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  reminder.scheduledTime,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textMuted),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _accentGreen, width: 2),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.check, size: 16, color: _accentGreen),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantThumbCard extends StatelessWidget {
  const _PlantThumbCard({required this.plant});
  final PlantSummary plant;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/plant/${plant.id}'),
      child: SizedBox(
        width: 110,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: 110,
                decoration: BoxDecoration(
                  color: _cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(LucideIcons.flower2, size: 40, color: _forestGreen),
                    ),
                    if (plant.healthScore != null)
                      Positioned(
                        top: 8, right: 8,
                        child: _HealthBadge(score: plant.healthScore!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plant.nickname, maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.score});
  final double score;

  Color get _color {
    if (score >= 70) return _accentGreen;
    if (score >= 40) return const Color(0xFFFFA726);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: _cardWhite,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
      ),
      child: Center(
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _color, width: 2.5),
          ),
          child: Center(
            child: Text(
              '${score.round()}',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _color),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: _textDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// =============================================================================
// Wavy top painter for weather card
// =============================================================================

class _WavyTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _forestGreenLight
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.9,
        size.width * 0.5, size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.6,
        0, size.height * 0.8,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
