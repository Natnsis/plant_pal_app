import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

IconData _activityIcon(String type) {
  switch (type) {
    case 'watered': return LucideIcons.droplets;
    case 'fertilized': return LucideIcons.sprout;
    case 'repotted': return LucideIcons.flower2;
    case 'photo_node': return LucideIcons.camera;
    case 'milestone': return LucideIcons.target;
    default: return LucideIcons.clipboardList;
  }
}

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.plantId});
  final int plantId;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen>
    with SingleTickerProviderStateMixin {
  Plant? _plant;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isFavorited = false;

  static const _tabs = ['Overview', 'Care', 'Activity', 'Growth', 'Reminders'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) setState(() {});
      });
    _loadPlant();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlant() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await AuthService.getPlant(widget.plantId);
      if (!mounted) return;
      setState(() { _plant = Plant.fromJson(data); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load plant'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _plant == null) return _buildError();

    final plant = _plant!;
    final species = plant.species;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // Hero image + back/fav/menu
          SliverToBoxAdapter(
            child: Stack(children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.38,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [AppColors.sageTop, AppColors.sageBase]),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: const Center(child: Icon(LucideIcons.leaf, size: 80, color: AppColors.accentGreen)),
              ),
              // Back button
              Positioned(top: MediaQuery.of(context).padding.top + 8, left: 16,
                  child: _CircleButton(icon: LucideIcons.chevronLeft, onTap: () => Navigator.pop(context))),
              // Favorite
              Positioned(top: MediaQuery.of(context).padding.top + 8, right: 60,
                  child: _CircleButton(
                    icon: _isFavorited ? LucideIcons.heart : LucideIcons.heart,
                    color: _isFavorited ? const Color(0xFFE53935) : null,
                    onTap: () => setState(() => _isFavorited = !_isFavorited),
                  )),
              // Menu
              Positioned(top: MediaQuery.of(context).padding.top + 8, right: 16,
                  child: _CircleButton(icon: LucideIcons.circleEllipsis, onTap: () => _showMenu())),
            ]),
          ),

          // Plant info header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(plant.nickname,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                    if (plant.healthScore != null) _HealthBadge(score: plant.healthScore!),
                  ]),
                  const SizedBox(height: 4),
                  if (species != null)
                    Text('${species.commonName}${species.scientificName != null ? ' · ${species.scientificName}' : ''}',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textPrimary.withValues(alpha: 0.5))),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (plant.location != null)
                      _InfoPill(label: plant.location!),
                    const SizedBox(width: 8),
                    _InfoPill(label: plant.status == 'good' ? 'Good' : 'Needs Attention',
                        color: plant.status == 'good' ? AppColors.accentGreen : const Color(0xFFFFA726)),
                  ]),
                ],
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.accentDark,
                unselectedLabelColor: AppColors.textPrimary.withValues(alpha: 0.4),
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                indicatorColor: AppColors.accentGreen,
                indicatorWeight: 3,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),

          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(plant: plant),
                _CareTab(plantId: plant.id, carePlans: plant.carePlans),
                _ActivityTab(plantId: plant.id, activities: plant.activityLogs ?? []),
                _GrowthTab(plantId: plant.id, metrics: plant.growthMetrics ?? []),
                _RemindersTab(plantId: plant.id, reminders: plant.reminders ?? []),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(LucideIcons.leaf, size: 64, color: AppColors.accentGreen),
        const SizedBox(height: 16),
        Text(_error ?? 'Plant not found', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _loadPlant, style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
            child: const Text('Retry')),
      ])),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(LucideIcons.pencil, color: AppColors.textPrimary),
            title: const Text('Edit Plant'), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () { Navigator.pop(context); _showEditSheet(); },
          ),
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: Color(0xFFE53935)),
            title: const Text('Delete Plant', style: TextStyle(color: Color(0xFFE53935))),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () { Navigator.pop(context); _showDeleteConfirmation(); },
          ),
          ListTile(
            title: const Text('Cancel', textAlign: TextAlign.center),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => Navigator.pop(context),
          ),
        ]),
      ),
    );
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditPlantSheet(plant: _plant!, onSaved: (updated) {
        setState(() => _plant = updated);
      }),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${_plant!.nickname}?'),
        content: const Text("This will permanently remove this plant and its history. This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService.deletePlant(_plant!.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plant deleted')));
                  Navigator.pop(context);
                }
              } catch (_) {
                if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Couldn't delete plant, try again")));
              }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab bar delegate
// =============================================================================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);
  @override double get maxExtent => tabBar.preferredSize.height;
  @override double get minExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(covariant _TabBarDelegate old) => false;
  @override Widget build(BuildContext ctx, double sh, bool overlaps) {
    return Container(color: AppColors.cream, child: tabBar);
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.9), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)]),
          child: Icon(icon, color: color ?? AppColors.textPrimary, size: 20)),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.score});
  final double score;
  Color get _color => score >= 80 ? AppColors.accentGreen : score >= 50 ? const Color(0xFFFFA726) : const Color(0xFFE53935);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text('${score.round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c)),
    );
  }
}

// =============================================================================
// OVERVIEW TAB
// =============================================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final species = plant.species;
    final upcomingReminder = plant.reminders?.where((r) => !r.isCompleted).toList();
    upcomingReminder?.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final recentActivities = (plant.activityLogs ?? []).take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info cards
          if (species != null) ...[
            _InfoGrid(items: [
              if (species.family != null) _InfoItem(label: 'Family', value: species.family!),
              if (species.origin != null) _InfoItem(label: 'Origin', value: species.origin!),
              if (species.difficultyLevel != null) _InfoItem(label: 'Difficulty', value: species.difficultyLevel!,
                  badge: _DifficultyBadge(level: species.difficultyLevel!)),
              if (species.petSafe != null) _InfoItem(label: 'Pet Safety',
                  value: species.petSafe! ? '🐾 Pet-Safe' : '⚠️ Not Pet-Safe'),
            ]),
            const SizedBox(height: 20),
          ],

          // Next up
          if (upcomingReminder != null && upcomingReminder.isNotEmpty) ...[
            const Text('Next Up', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () { /* switch to Reminders tab */ },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06))),
                child: Row(children: [
                  Text(upcomingReminder.first.taskLabel.split(' ').first, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(upcomingReminder.first.taskLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text(upcomingReminder.first.scheduledTime, style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.5))),
                    ],
                  )),
                  const Icon(LucideIcons.chevronRight, color: AppColors.textPrimary),
                ]),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Recent activity
          if (recentActivities.isNotEmpty) ...[
            Row(children: [
              const Text('Recent Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              TextButton(onPressed: () { /* switch to Activity tab */ },
                  child: Text('See all', style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.5)))),
            ]),
            ...recentActivities.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(_activityIcon(a.activityType), size: 20, color: AppColors.accentGreen),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.activityType.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (a.notes != null) Text(a.notes!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.5))),
                ])),
                Text(a.loggedDate, style: TextStyle(fontSize: 11, color: AppColors.textPrimary.withValues(alpha: 0.4))),
              ]),
            )),
          ],
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});
  final List<_InfoItem> items;
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(item.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary.withValues(alpha: 0.5))),
          const SizedBox(height: 2),
          item.badge ?? Text(item.value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ]),
      )).toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value, this.badge});
  final String label;
  final String value;
  final Widget? badge;
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.level});
  final String level;
  Color get _color {
    switch (level.toLowerCase()) {
      case 'easy': return AppColors.accentGreen;
      case 'medium': return const Color(0xFFFFA726);
      default: return const Color(0xFFE53935);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(level, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

// =============================================================================
// CARE TAB
// =============================================================================

class _CareTab extends StatefulWidget {
  const _CareTab({required this.plantId, required this.carePlans});
  final int plantId;
  final List<CarePlan>? carePlans;
  @override
  State<_CareTab> createState() => _CareTabState();
}

class _CareTabState extends State<_CareTab> {
  CarePlan? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.carePlans != null && widget.carePlans!.isNotEmpty) {
      _plan = widget.carePlans!.first;
      _isLoading = false;
    } else {
      _loadPlan();
    }
  }

  Future<void> _loadPlan() async {
    try {
      final data = await AuthService.getCarePlan(widget.plantId);
      if (mounted) setState(() { _plan = CarePlan.fromJson(data); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_plan == null) return _buildEmpty();
    return _buildContent();
  }

  Widget _buildEmpty() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('📋', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('No care plan yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Set up a care plan for this plant', style: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.5))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _showEditCare, style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
            child: const Text('Set up care plan')),
      ]),
    ));
  }

  Widget _buildContent() {
    final plan = _plan!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _CareCard(title: '💧 Watering', items: [
          if (plan.wateringFrequencyDays != null) _CareRow(label: 'Frequency', value: 'Every ${plan.wateringFrequencyDays} days'),
          if (plan.wateringAmount != null) _CareRow(label: 'Amount', value: plan.wateringAmount!),
          if (plan.wateringMethod != null) _CareRow(label: 'Method', value: plan.wateringMethod!),
          if (plan.wateringTips != null) _CareRow(label: 'Tips', value: plan.wateringTips!),
        ], onEdit: _showEditCare),
        _CareCard(title: '☀️ Light', items: [
          if (plan.lightRequirement != null) _CareRow(label: 'Requirement', value: plan.lightRequirement!),
        ], onEdit: _showEditCare),
        _CareCard(title: '💦 Humidity', items: [
          if (plan.humidityRequirement != null) _CareRow(label: 'Requirement', value: plan.humidityRequirement!),
        ], onEdit: _showEditCare),
        _CareCard(title: '🌡️ Temperature', items: [
          if (plan.temperatureMinC != null && plan.temperatureMaxC != null)
            _CareRow(label: 'Range', value: '${plan.temperatureMinC!.round()}°C – ${plan.temperatureMaxC!.round()}°C'),
        ], onEdit: _showEditCare),
        _CareCard(title: '🪨 Soil', items: [
          if (plan.soilType != null) _CareRow(label: 'Type', value: plan.soilType!),
        ], onEdit: _showEditCare),
        _CareCard(title: '🌱 Fertilizer', items: [
          if (plan.fertilizerType != null) _CareRow(label: 'Type', value: plan.fertilizerType!),
        ], onEdit: _showEditCare),
        _CareCard(title: '✂️ Pruning', items: [
          if (plan.pruningFrequency != null) _CareRow(label: 'Frequency', value: plan.pruningFrequency!),
        ], onEdit: _showEditCare),
        _CareCard(title: '🪴 Repotting', items: [
          if (plan.repottingFrequency != null) _CareRow(label: 'Frequency', value: plan.repottingFrequency!),
        ], onEdit: _showEditCare),
      ]),
    );
  }

  void _showEditCare() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditCareSheet(plantId: widget.plantId, plan: _plan, onSaved: (p) {
        setState(() => _plan = p);
      }),
    );
  }
}

class _CareCard extends StatelessWidget {
  const _CareCard({required this.title, required this.items, this.onEdit});
  final String title;
  final List<_CareRow> items;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Spacer(),
          if (onEdit != null)
            GestureDetector(onTap: onEdit, child: Icon(LucideIcons.pencil, size: 16, color: AppColors.textPrimary.withValues(alpha: 0.3))),
        ]),
        const SizedBox(height: 10),
        ...items.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 90, child: Text(r.label, style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.5)))),
            Expanded(child: Text(r.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          ]),
        )),
      ]),
    );
  }
}

class _CareRow {
  const _CareRow({required this.label, required this.value});
  final String label;
  final String value;
}

// =============================================================================
// ACTIVITY TAB
// =============================================================================

class _ActivityTab extends StatefulWidget {
  const _ActivityTab({required this.plantId, required this.activities});
  final int plantId;
  final List<ActivityLog> activities;
  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  late List<ActivityLog> _activities;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activities = List.from(widget.activities);
    _isLoading = false;
    if (_activities.isEmpty) _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.getActivities(widget.plantId);
      if (mounted) setState(() { _activities = data.map((j) => ActivityLog.fromJson(j)).toList(); _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_activities.isEmpty) return _buildEmpty();

    return Stack(children: [
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        itemCount: _activities.length,
        itemBuilder: (_, i) {
          final a = _activities[i];
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Timeline
            SizedBox(width: 32, child: Column(children: [
              Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.sageBase.withValues(alpha: 0.3), shape: BoxShape.circle),
                  child: Center(child: Icon(_activityIcon(a.activityType), size: 14, color: AppColors.accentGreen))),
              if (i < _activities.length - 1)
                Container(width: 2, height: 40, color: AppColors.sageBase.withValues(alpha: 0.3)),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(a.activityType.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Spacer(),
                  Text(a.loggedDate, style: TextStyle(fontSize: 11, color: AppColors.textPrimary.withValues(alpha: 0.4))),
                ]),
                if (a.notes != null && a.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(a.notes!, style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.6))),
                ],
              ]),
            )),
          ]);
        },
      ),
      // FAB
      Positioned(bottom: 20, right: 20,
        child: FloatingActionButton(
          onPressed: _showLogActivity, backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white,
          child: const Icon(LucideIcons.plus),
        ),
      ),
    ]);
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('📋', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      const Text('No activity logged yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _showLogActivity, style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: const Text('Log Activity')),
    ]));
  }

  void _showLogActivity() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _LogActivitySheet(plantId: widget.plantId, onLogged: (log) {
        setState(() => _activities.insert(0, log));
      }),
    );
  }
}

// =============================================================================
// GROWTH TAB
// =============================================================================

class _GrowthTab extends StatefulWidget {
  const _GrowthTab({required this.plantId, required this.metrics});
  final int plantId;
  final List<GrowthMetric> metrics;
  @override
  State<_GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends State<_GrowthTab> {
  late List<GrowthMetric> _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _metrics = List.from(widget.metrics);
    _isLoading = false;
    if (_metrics.isEmpty) _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.getGrowth(widget.plantId);
      if (mounted) setState(() { _metrics = data.map((j) => GrowthMetric.fromJson(j)).toList(); _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Stack(children: [
      _metrics.isEmpty ? _buildEmpty() : _buildContent(),
      Positioned(bottom: 20, right: 20,
        child: FloatingActionButton(
          onPressed: _showLogGrowth, backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white,
          child: const Icon(LucideIcons.plus),
        ),
      ),
    ]);
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Chart placeholder
        // TODO: wire real chart library
        Container(
          height: 200, width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.lineChart, size: 48, color: AppColors.textPrimary.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text('Growth chart', style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.3))),
          ]),
        ),
        const SizedBox(height: 20),
        // Measurements list
        ..._metrics.map((m) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.heightCm} cm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(m.recordedDate, style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.4))),
            ])),
            _GrowthStatusBadge(status: m.growthRateStatus),
          ]),
        )),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('📏', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      const Text('No growth data yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('Log your first measurement', style: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.5))),
    ]));
  }

  void _showLogGrowth() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _LogGrowthSheet(plantId: widget.plantId, onLogged: (m) {
        setState(() => _metrics.insert(0, m));
      }),
    );
  }
}

class _GrowthStatusBadge extends StatelessWidget {
  const _GrowthStatusBadge({required this.status});
  final String status;
  Color get _color {
    switch (status) {
      case 'fast': return AppColors.accentGreen;
      case 'moderate': return const Color(0xFF42A5F5);
      default: return const Color(0xFFFFA726);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

// =============================================================================
// REMINDERS TAB
// =============================================================================

class _RemindersTab extends StatefulWidget {
  const _RemindersTab({required this.plantId, required this.reminders});
  final int plantId;
  final List<Reminder> reminders;
  @override
  State<_RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<_RemindersTab> {
  late List<Reminder> _reminders;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reminders = List.from(widget.reminders);
    _isLoading = false;
    if (_reminders.isEmpty) _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthService.getPlantReminders(widget.plantId);
      if (mounted) setState(() { _reminders = data.map((j) => Reminder.fromJson(j)).toList(); _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final pending = _reminders.where((r) => !r.isCompleted).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final completed = _reminders.where((r) => r.isCompleted).toList();

    return Stack(children: [
      if (_reminders.isEmpty) _buildEmpty() else _buildContent(pending, completed),
      Positioned(bottom: 20, right: 20,
        child: FloatingActionButton(
          onPressed: _showAddReminder, backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white,
          child: const Icon(LucideIcons.plus),
        ),
      ),
    ]);
  }

  Widget _buildContent(List<Reminder> pending, List<Reminder> completed) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      children: [
        if (pending.isNotEmpty) ...[
          Text('${pending.length} pending', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          ...pending.map((r) => _ReminderRow(reminder: r, onComplete: () => _completeReminder(r), plantId: widget.plantId)),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('${completed.length} completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          ...completed.map((r) => _ReminderRow(reminder: r, onComplete: null, plantId: widget.plantId)),
        ],
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('⏰', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      const Text('No reminders set', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('Add a reminder for this plant', style: TextStyle(fontSize: 14, color: AppColors.textPrimary.withValues(alpha: 0.5))),
    ]));
  }

  Future<void> _completeReminder(Reminder r) async {
    setState(() => _reminders.removeWhere((x) => x.id == r.id));
    try {
      await AuthService.updateReminder(r.id, {'is_completed': true});
    } catch (_) {}
  }

  void _showAddReminder() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(plantId: widget.plantId, onAdded: (r) {
        setState(() => _reminders.add(r));
      }),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder, required this.onComplete, required this.plantId});
  final Reminder reminder;
  final VoidCallback? onComplete;
  final int plantId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Text(reminder.taskLabel.split(' ').first, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reminder.taskLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary.withValues(alpha: onComplete != null ? 1.0 : 0.4))),
          Text(reminder.scheduledTime, style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.4))),
        ])),
        if (onComplete != null)
          GestureDetector(onTap: onComplete,
            child: Container(width: 28, height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accentGreen, width: 2)),
                child: const Icon(LucideIcons.check, size: 16, color: AppColors.accentGreen)),
          ),
      ]),
    );
  }
}

// =============================================================================
// BOTTOM SHEETS
// =============================================================================

class _EditPlantSheet extends StatefulWidget {
  const _EditPlantSheet({required this.plant, required this.onSaved});
  final Plant plant;
  final ValueChanged<Plant> onSaved;
  @override
  State<_EditPlantSheet> createState() => _EditPlantSheetState();
}

class _EditPlantSheetState extends State<_EditPlantSheet> {
  late TextEditingController _nicknameCtrl;
  late TextEditingController _locationCtrl;
  String _status = 'good';
  double _healthScore = 50;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.plant.nickname);
    _locationCtrl = TextEditingController(text: widget.plant.location ?? '');
    _status = widget.plant.status;
    _healthScore = widget.plant.healthScore ?? 50;
  }

  @override
  void dispose() { _nicknameCtrl.dispose(); _locationCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit Plant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _Label('Nickname'), TextField(controller: _nicknameCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: _dec()),
          const SizedBox(height: 14),
          _Label('Location'), TextField(controller: _locationCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: _dec()),
          const SizedBox(height: 14),
          _Label('Status'), Row(children: [
            _StatusChip(label: 'Good', isActive: _status == 'good', onTap: () => setState(() => _status = 'good')),
            const SizedBox(width: 8),
            _StatusChip(label: 'Needs Attention', isActive: _status == 'needs_attention', onTap: () => setState(() => _status = 'needs_attention')),
          ]),
          const SizedBox(height: 14),
          _Label('Health Score: ${_healthScore.round()}%'),
          Slider(value: _healthScore, min: 0, max: 100, activeColor: AppColors.accentGreen,
              onChanged: (v) => setState(() => _healthScore = v)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _onSave,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Save Changes'),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _dec() => InputDecoration(
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
  );

  Future<void> _onSave() async {
    setState(() => _saving = true);
    try {
      final data = await AuthService.updatePlant(widget.plant.id, {
        'nickname': _nicknameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'status': _status,
        'health_score': _healthScore.round(),
      });
      if (!mounted) return;
      widget.onSaved(Plant.fromJson(data));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plant updated')));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? AppColors.accentDark : Colors.white, borderRadius: BorderRadius.circular(999),
            border: isActive ? null : Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1))),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? AppColors.cream : AppColors.textPrimary)),
      ),
    );
  }
}

class _EditCareSheet extends StatefulWidget {
  const _EditCareSheet({required this.plantId, required this.plan, required this.onSaved});
  final int plantId;
  final CarePlan? plan;
  final ValueChanged<CarePlan> onSaved;
  @override
  State<_EditCareSheet> createState() => _EditCareSheetState();
}

class _EditCareSheetState extends State<_EditCareSheet> {
  late TextEditingController _waterFreq;
  late TextEditingController _waterAmount;
  late TextEditingController _lightReq;
  late TextEditingController _humidityReq;
  late TextEditingController _soilType;
  late TextEditingController _fertilizerType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _waterFreq = TextEditingController(text: p?.wateringFrequencyDays?.toString() ?? '');
    _waterAmount = TextEditingController(text: p?.wateringAmount ?? '');
    _lightReq = TextEditingController(text: p?.lightRequirement ?? '');
    _humidityReq = TextEditingController(text: p?.humidityRequirement ?? '');
    _soilType = TextEditingController(text: p?.soilType ?? '');
    _fertilizerType = TextEditingController(text: p?.fertilizerType ?? '');
  }

  @override
  void dispose() {
    _waterFreq.dispose(); _waterAmount.dispose(); _lightReq.dispose();
    _humidityReq.dispose(); _soilType.dispose(); _fertilizerType.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Care Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _Label('Water Frequency (days)'), TextField(controller: _waterFreq, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary), decoration: _dec()),
          const SizedBox(height: 12),
          _Label('Water Amount'), TextField(controller: _waterAmount, style: const TextStyle(color: AppColors.textPrimary), decoration: _dec()),
          const SizedBox(height: 12),
          _Label('Light Requirement'), TextField(controller: _lightReq, style: const TextStyle(color: AppColors.textPrimary), decoration: _dec()),
          const SizedBox(height: 12),
          _Label('Humidity'), TextField(controller: _humidityReq, style: const TextStyle(color: AppColors.textPrimary), decoration: _dec()),
          const SizedBox(height: 12),
          _Label('Soil Type'), TextField(controller: _soilType, style: const TextStyle(color: AppColors.textPrimary), decoration: _dec()),
          const SizedBox(height: 12),
          _Label('Fertilizer Type'), TextField(controller: _fertilizerType, style: const TextStyle(color: AppColors.textPrimary), decoration: _dec()),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _onSave,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Save Care Plan'),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _dec() => InputDecoration(
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
  );

  Future<void> _onSave() async {
    setState(() => _saving = true);
    final fields = <String, dynamic>{};
    if (_waterFreq.text.isNotEmpty) fields['watering_frequency_days'] = int.tryParse(_waterFreq.text);
    if (_waterAmount.text.isNotEmpty) fields['watering_amount'] = _waterAmount.text;
    if (_lightReq.text.isNotEmpty) fields['light_requirement'] = _lightReq.text;
    if (_humidityReq.text.isNotEmpty) fields['humidity_requirement'] = _humidityReq.text;
    if (_soilType.text.isNotEmpty) fields['soil_type'] = _soilType.text;
    if (_fertilizerType.text.isNotEmpty) fields['fertilizer_type'] = _fertilizerType.text;
    try {
      final data = await AuthService.updateCarePlan(widget.plantId, fields);
      if (!mounted) return;
      widget.onSaved(CarePlan.fromJson(data));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _LogActivitySheet extends StatefulWidget {
  const _LogActivitySheet({required this.plantId, required this.onLogged});
  final int plantId;
  final ValueChanged<ActivityLog> onLogged;
  @override
  State<_LogActivitySheet> createState() => _LogActivitySheetState();
}

class _LogActivitySheetState extends State<_LogActivitySheet> {
  String _type = 'watered';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  static const _types = ['watered', 'fertilized', 'repotted'];
  static const _typeIcons = {'watered': LucideIcons.droplets, 'fertilized': LucideIcons.sprout, 'repotted': LucideIcons.flower2};

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Log Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) =>
            GestureDetector(onTap: () => setState(() => _type = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: _type == t ? AppColors.accentDark : Colors.white, borderRadius: BorderRadius.circular(999),
                    border: _type == t ? null : Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_typeIcons[t] ?? Icons.circle, size: 16, color: _type == t ? AppColors.cream : AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text(t, style: TextStyle(color: _type == t ? AppColors.cream : AppColors.textPrimary, fontWeight: FontWeight.w500)),
                ]),
              ),
            )).toList()),
          const SizedBox(height: 14),
          _Label('Notes (optional)'),
          TextField(controller: _notesCtrl, style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 2, decoration: InputDecoration(filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _onLog,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Log Activity'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _onLog() async {
    setState(() => _saving = true);
    try {
      final data = await AuthService.logActivity(widget.plantId, type: _type, notes: _notesCtrl.text);
      if (!mounted) return;
      widget.onLogged(ActivityLog.fromJson(data));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _LogGrowthSheet extends StatefulWidget {
  const _LogGrowthSheet({required this.plantId, required this.onLogged});
  final int plantId;
  final ValueChanged<GrowthMetric> onLogged;
  @override
  State<_LogGrowthSheet> createState() => _LogGrowthSheetState();
}

class _LogGrowthSheetState extends State<_LogGrowthSheet> {
  final _heightCtrl = TextEditingController();
  String _status = 'moderate';
  bool _saving = false;

  @override
  void dispose() { _heightCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Log Growth', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _Label('Height (cm)'),
          TextField(controller: _heightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 14),
          _Label('Growth Rate'),
          Wrap(spacing: 8, children: ['slow', 'moderate', 'fast'].map((s) =>
            GestureDetector(onTap: () => setState(() => _status = s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: _status == s ? AppColors.accentDark : Colors.white, borderRadius: BorderRadius.circular(999),
                    border: _status == s ? null : Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1))),
                child: Text(s, style: TextStyle(color: _status == s ? AppColors.cream : AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ))).toList()),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving || _heightCtrl.text.isEmpty ? null : _onSave,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Log Growth'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);
    try {
      final data = await AuthService.logGrowth(widget.plantId,
          heightCm: double.parse(_heightCtrl.text), status: _status);
      if (!mounted) return;
      widget.onLogged(GrowthMetric.fromJson(data));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet({required this.plantId, required this.onAdded});
  final int plantId;
  final ValueChanged<Reminder> onAdded;
  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  String _taskType = 'water';
  final _timeCtrl = TextEditingController();
  bool _saving = false;

  static const _types = ['water', 'fertilize', 'mist', 'rotate', 'repot'];
  static const _typeIcons = {'water': LucideIcons.droplets, 'fertilize': LucideIcons.sprout, 'mist': LucideIcons.cloudRain, 'rotate': LucideIcons.refreshCw, 'repot': LucideIcons.flower2};

  @override
  void dispose() { _timeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Reminder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) =>
            GestureDetector(onTap: () => setState(() => _taskType = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _taskType == t ? AppColors.accentDark : Colors.white, borderRadius: BorderRadius.circular(999),
                    border: _taskType == t ? null : Border.all(color: AppColors.textPrimary.withValues(alpha: 0.1))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_typeIcons[t] ?? Icons.circle, size: 14, color: _taskType == t ? AppColors.cream : AppColors.textPrimary),
                  const SizedBox(width: 4),
                  Text(t, style: TextStyle(color: _taskType == t ? AppColors.cream : AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                ]),
              ))).toList()),
          const SizedBox(height: 14),
          _Label('Scheduled Time'),
          TextField(controller: _timeCtrl, style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: 'e.g. 09:00', hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3)),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving || _timeCtrl.text.isEmpty ? null : _onSave,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Add Reminder'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _onSave() async {
    setState(() => _saving = true);
    try {
      final data = await AuthService.createPlantReminder(widget.plantId,
          taskType: _taskType, scheduledTime: _timeCtrl.text);
      if (!mounted) return;
      widget.onAdded(Reminder.fromJson(data));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)));
  }
}
