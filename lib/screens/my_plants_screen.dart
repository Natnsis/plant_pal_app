import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Plant> _plants = [];
  bool _isLoading = true;
  String? _error;
  String _activeFilter = 'All';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await AuthService.getPlants();
      if (!mounted) return;
      setState(() {
        _plants = data.map((j) => Plant.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load plants'; _isLoading = false; });
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (q.trim().isEmpty) { _loadPlants(); return; }
      try {
        final data = await AuthService.searchPlants(q.trim());
        if (!mounted) return;
        setState(() { _plants = data.map((j) => Plant.fromJson(j)).toList(); });
      } catch (_) {}
    });
  }

  List<Plant> get _filtered {
    if (_activeFilter == 'Needs Attention') {
      return _plants.where((p) => p.status == 'needs_attention').toList();
    }
    if (_activeFilter == 'Healthy') {
      return _plants.where((p) => p.status == 'good').toList();
    }
    return _plants;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.sageTop, AppColors.sageBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('My Plants',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.cream)),
                    ),
                    GestureDetector(
                      onTap: () => _showAddPlantSheet(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.plus, color: AppColors.accentDark, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search plants...',
                    hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.35)),
                    prefixIcon: Icon(LucideIcons.search, color: AppColors.textPrimary.withValues(alpha: 0.4)),
                    filled: true, fillColor: AppColors.cream,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  ),
                ),
              ),

              // Filters + view toggle
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                child: Row(
                  children: [
                    _FilterPill(label: 'All', isActive: _activeFilter == 'All', onTap: () => setState(() => _activeFilter = 'All')),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'Needs Attention', isActive: _activeFilter == 'Needs Attention', onTap: () => setState(() => _activeFilter = 'Needs Attention')),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'Healthy', isActive: _activeFilter == 'Healthy', onTap: () => setState(() => _activeFilter = 'Healthy')),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _isGridView = !_isGridView),
                      child: Icon(_isGridView ? LucideIcons.list : LucideIcons.layoutGrid,
                          color: AppColors.cream, size: 22),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildSkeleton();
    if (_error != null) return _buildError();
    final plants = _filtered;
    if (plants.isEmpty && _searchController.text.isNotEmpty) {
      return Center(child: Text("No plants match '${_searchController.text}'",
          style: const TextStyle(color: AppColors.cream, fontSize: 15)));
    }
    if (plants.isEmpty) return _buildEmpty();
    return _isGridView ? _buildGrid(plants) : _buildList(plants);
  }

  Widget _buildGrid(List<Plant> plants) {
    return RefreshIndicator(
      onRefresh: _loadPlants,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
        itemCount: plants.length,
        itemBuilder: (_, i) => _PlantGridCard(plant: plants[i]),
      ),
    );
  }

  Widget _buildList(List<Plant> plants) {
    return RefreshIndicator(
      onRefresh: _loadPlants,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: plants.length,
        itemBuilder: (_, i) => _PlantListTile(plant: plants[i]),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: 0.72,
      children: List.generate(6, (_) => Container(
        decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      )),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, style: const TextStyle(color: AppColors.cream)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadPlants, style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder()),
          child: const Text('Retry')),
    ]));
  }

  Widget _buildEmpty() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(LucideIcons.sprout, size: 64, color: AppColors.cream),
        const SizedBox(height: 16),
        const Text('No plants yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.cream)),
        const SizedBox(height: 8),
        Text('Scan or add your first plant to get started',
            style: TextStyle(fontSize: 14, color: AppColors.cream.withValues(alpha: 0.6))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => Navigator.of(context).pushNamed('/scan'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonBg, foregroundColor: AppColors.buttonLabel, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
            child: const Text('Scan a Plant')),
      ]),
    ));
  }

  void _showAddPlantSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddPlantSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid card
// ---------------------------------------------------------------------------

class _PlantGridCard extends StatelessWidget {
  const _PlantGridCard({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/plant/${plant.id}'),
      child: Container(
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo placeholder
            Expanded(
              flex: 5,
              child: Stack(fit: StackFit.expand, children: [
                Container(color: AppColors.sageBase, child: const Center(child: Icon(LucideIcons.leaf, size: 40, color: AppColors.accentGreen))),
                // Health badge
                if (plant.healthScore != null)
                  Positioned(bottom: -10, right: 10,
                      child: _HealthRingBadge(score: plant.healthScore!)),
              ]),
            ),
            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.nickname, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(plant.species?.commonName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.45))),
                    const Spacer(),
                    Row(children: [
                      if (plant.location != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.sageBase.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                          child: Text(plant.location!, style: TextStyle(fontSize: 10, color: AppColors.textPrimary.withValues(alpha: 0.5))),
                        ),
                      const Spacer(),
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                              color: plant.status == 'good' ? AppColors.accentGreen : const Color(0xFFFFA726))),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List tile
// ---------------------------------------------------------------------------

class _PlantListTile extends StatelessWidget {
  const _PlantListTile({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/plant/${plant.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          // Thumbnail
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.sageBase, borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Icon(LucideIcons.leaf, size: 26, color: AppColors.accentGreen))),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plant.nickname, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(plant.species?.commonName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary.withValues(alpha: 0.45))),
              if (plant.location != null) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.sageBase.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                  child: Text(plant.location!, style: TextStyle(fontSize: 10, color: AppColors.textPrimary.withValues(alpha: 0.5))),
                ),
              ],
            ],
          )),
          if (plant.healthScore != null) _HealthRingBadge(score: plant.healthScore!),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Health ring badge
// ---------------------------------------------------------------------------

class _HealthRingBadge extends StatelessWidget {
  const _HealthRingBadge({required this.score});
  final double score;

  Color get _color {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 50) return const Color(0xFFFFA726);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppColors.cream, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]),
      child: Center(
        child: SizedBox(width: 28, height: 28,
          child: CircularProgressIndicator(value: score / 100, strokeWidth: 3,
              backgroundColor: _color.withValues(alpha: 0.15), valueColor: AlwaysStoppedAnimation(_color)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter pill
// ---------------------------------------------------------------------------

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDark : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: isActive ? null : Border.all(color: AppColors.cream.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: isActive ? AppColors.cream : AppColors.cream.withValues(alpha: 0.7))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Plant Bottom Sheet
// ---------------------------------------------------------------------------

class _AddPlantSheet extends StatefulWidget {
  @override
  State<_AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends State<_AddPlantSheet> {
  bool _showManualForm = false;
  final _nicknameController = TextEditingController();
  final _locationController = TextEditingController();
  final _speciesController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nicknameController.dispose();
    _locationController.dispose();
    _speciesController.dispose();
    super.dispose();
  }

  Future<void> _onAddPlant() async {
    if (_nicknameController.text.trim().isEmpty) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final speciesId = int.tryParse(_speciesController.text.trim());
      final plant = await AuthService.createPlant(
        nickname: _nicknameController.text.trim(),
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        speciesId: speciesId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed('/plant/${plant['id']}');
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showManualForm) return _buildManualForm();
    return _buildChoiceSheet();
  }

  Widget _buildChoiceSheet() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999))),
        const SizedBox(height: 20),
        const Text('Add a Plant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        // Scan option
        _AddOptionCard(
          icon: LucideIcons.camera, title: 'Scan a Plant',
          subtitle: 'Let AI identify it for you',
          onTap: () { Navigator.of(context).pop(); Navigator.of(context).pushNamed('/scan'); },
        ),
        const SizedBox(height: 12),
        // Manual option
        _AddOptionCard(
          icon: LucideIcons.pencil, title: 'Add Manually',
          subtitle: 'Enter details yourself',
          onTap: () => setState(() => _showManualForm = true),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _buildManualForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(onTap: () => setState(() => _showManualForm = false),
                child: const Icon(LucideIcons.chevronLeft, size: 24)),
            const SizedBox(width: 8),
            const Text('Add Manually', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13))),
            const SizedBox(height: 16),
          ],
          _FieldLabel('Nickname'),
          TextField(controller: _nicknameController,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _inputDecoration('e.g. Fiddle Leaf')),
          const SizedBox(height: 14),
          _FieldLabel('Location'),
          TextField(controller: _locationController,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _inputDecoration('e.g. Living Room, Balcony')),
          const SizedBox(height: 14),
          // TODO: replace with a proper species picker once species-list/search endpoint is available
          _FieldLabel('Species ID (optional)'),
          TextField(controller: _speciesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _inputDecoration('Numeric ID')),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _nicknameController.text.trim().isEmpty || _isSubmitting ? null : _onAddPlant,
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
        ]),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3)),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.accentGreen, width: 1.5)),
    );
  }
}

class _AddOptionCard extends StatelessWidget {
  const _AddOptionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.sageBase.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.accentDark, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.5))),
            ],
          )),
          const Icon(LucideIcons.chevronRight, color: AppColors.textPrimary, size: 22),
        ]),
      ),
    );
  }
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
