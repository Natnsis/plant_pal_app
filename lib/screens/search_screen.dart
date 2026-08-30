import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_common.dart';
import 'plant_detail_screen.dart';

/// Searches the user's own plants by nickname, location, or species
/// (`GET /plants/search?q=`).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = PlantPalApi.instance;
  final _query = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  String? _error;
  List<Plant>? _results;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _run(q));
  }

  Future<void> _run(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.searchPlants(q);
      if (!mounted || _query.text.trim() != q) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
              child: Row(
                children: [
                  SquircleIconButton(
                    icon: LucideIcons.chevronLeft,
                    background: PP.card.withValues(alpha: 0.8),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.search,
                              size: 17, color: PP.inkA(0.4)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _query,
                              autofocus: true,
                              onChanged: _onChanged,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                border: InputBorder.none,
                                hintText: 'Search your plants',
                                hintStyle: TextStyle(
                                    color: PP.inkA(0.4),
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          if (_query.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _query.clear();
                                _onChanged('');
                              },
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: PP.inkA(0.4)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: PP.forest),
        ),
      );
    }
    if (_error != null) {
      return _hint(LucideIcons.triangleAlert, _error!);
    }
    final results = _results;
    if (results == null) {
      return _hint(LucideIcons.search,
          'Search by nickname, room, or species name.');
    }
    if (results.isEmpty) {
      return _hint(LucideIcons.sprout, 'No plants match "${_query.text.trim()}".');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _row(results[i]),
    );
  }

  Widget _row(Plant p) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlantDetailScreen(plantId: p.id))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            PlantImage(
                imageUrl: p.photoUrl, width: 54, height: 54, radius: 18),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  Text(
                      [
                        if (p.location.isNotEmpty) p.location,
                        if (p.species.commonName.isNotEmpty)
                          p.species.commonName,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: PP.inkA(0.5))),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: PP.inkA(0.35)),
          ],
        ),
      ),
    );
  }

  Widget _hint(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: PP.pale1,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: PP.forest),
            ),
            const SizedBox(height: 14),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: PP.inkA(0.55))),
          ],
        ),
      ),
    );
  }
}
