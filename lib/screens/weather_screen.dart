import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = PlantPalApi.instance;
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
                      child: Text('Addis Ababa',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: AsyncView<Forecast>(
                load: api.weather,
                builder: (context, f, reload) => RefreshIndicator(
                  color: PP.forest,
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
                    children: [
                      _bigCard(f.current),
                      if (f.hourly.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _nextHours(f.hourly),
                      ],
                      const SizedBox(height: 14),
                      _advice(f),
                      if (f.daily.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        for (final d in f.daily.take(5)) ...[
                          _forecastRow(d),
                          const SizedBox(height: 9),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigCard(CurrentWeather c) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [PP.forestMid, PP.forest],
        ),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c.temp}°',
                        style: TextStyle(
                            fontSize: 64,
                            height: 0.9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: PP.track(64, -0.05),
                            color: PP.bone)),
                    const SizedBox(height: 8),
                    Text(_iconLabel(c.icon),
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: PP.bone.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              Icon(_weatherIcon(c.icon), size: 56, color: PP.lime),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _WStat('Humidity', '${c.humidity}%')),
              const SizedBox(width: 10),
              Expanded(child: _WStat('Feels', '${c.temp}°')),
              const SizedBox(width: 10),
              Expanded(child: _WStat('Sky', _iconLabel(c.icon))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _advice(Forecast f) {
    final humid = f.current.humidity;
    final msg = humid < 40
        ? 'Air is dry ($humid% humidity). Mist humidity-loving plants and keep them away from direct afternoon sun.'
        : humid > 75
            ? 'High humidity today ($humid%). Ease off watering and make sure pots drain freely.'
            : 'Comfortable conditions for most house plants. Water on your normal schedule.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PP.pale2,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sprout, size: 19, color: PP.forest),
              const SizedBox(width: 10),
              Text('WHAT THIS MEANS',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: PP.forest)),
            ],
          ),
          const SizedBox(height: 10),
          Text(msg,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: PP.forest)),
        ],
      ),
    );
  }

  Widget _nextHours(List<HourlyWeather> hours) {
    return SurfaceCard(
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Next hours',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in hours.take(5))
                Column(
                  children: [
                    Text(h.hour,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PP.inkA(0.45))),
                    const SizedBox(height: 8),
                    Text('${h.temp}°',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastRow(DailyWeather d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(_weekday(d.date),
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 14),
          Icon(_weatherIcon(d.icon), size: 19, color: PP.forest),
          const Spacer(),
          Text('${d.low}°  ${d.high}°',
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static String _weekday(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return iso.length >= 3 ? iso.substring(0, 3) : iso;
    const dn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dn[t.weekday - 1];
  }

  static IconData _weatherIcon(String icon) {
    final k = icon.toLowerCase();
    if (k.contains('rain') || k.contains('drizzle')) return LucideIcons.cloudRain;
    if (k.contains('cloud')) return LucideIcons.cloud;
    if (k.contains('storm') || k.contains('thunder')) {
      return LucideIcons.cloudLightning;
    }
    if (k.contains('snow')) return LucideIcons.snowflake;
    return LucideIcons.sun;
  }

  static String _iconLabel(String icon) {
    final k = icon.toLowerCase();
    if (k.contains('rain')) return 'Rain';
    if (k.contains('drizzle')) return 'Drizzle';
    if (k.contains('cloud')) return 'Cloudy';
    if (k.contains('clear') || k.isEmpty) return 'Clear';
    if (k.contains('sun')) return 'Sunny';
    return icon;
  }
}

class _WStat extends StatelessWidget {
  const _WStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: PP.bone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: PP.bone.withValues(alpha: 0.6))),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: PP.bone)),
        ],
      ),
    );
  }
}
