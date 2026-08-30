import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'json_util.dart';
import 'token_store.dart';

/// Typed facade over every PlantPal endpoint the app uses.
class PlantPalApi {
  PlantPalApi._();
  static final PlantPalApi instance = PlantPalApi._();

  final ApiClient _c = ApiClient.instance;

  // ── auth ────────────────────────────────────────────────────────────────
  Future<AuthTokens> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final j = await _c.postJson<Map<String, dynamic>>('/register', body: {
      'full_name': fullName,
      'email': email,
      'password': password,
    });
    final t = AuthTokens.fromJson(j);
    await TokenStore.instance.save(t.accessToken, t.refreshToken);
    return t;
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final j = await _c.postJson<Map<String, dynamic>>('/login', body: {
      'email': email,
      'password': password,
    });
    final t = AuthTokens.fromJson(j);
    await TokenStore.instance.save(t.accessToken, t.refreshToken);
    return t;
  }

  Future<AuthTokens> googleLogin(String idToken) async {
    final j = await _c
        .postJson<Map<String, dynamic>>('/auth/google', body: {'id_token': idToken});
    final t = AuthTokens.fromJson(j);
    await TokenStore.instance.save(t.accessToken, t.refreshToken);
    return t;
  }

  Future<void> logout() async {
    final rt = TokenStore.instance.refreshToken;
    try {
      if (rt != null && rt.isNotEmpty) {
        await _c.postJson<Map<String, dynamic>>('/logout',
            body: {'refresh_token': rt});
      }
    } finally {
      await TokenStore.instance.clear();
    }
  }

  // ── user ────────────────────────────────────────────────────────────────
  Future<UserProfile> me() async =>
      UserProfile.fromJson(await _c.getJson<Map<String, dynamic>>('/users/me'));

  Future<UserProfile> updateMe({
    String? fullName,
    String? email,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    if (imageUrl != null) body['image_url'] = imageUrl;
    return UserProfile.fromJson(
        await _c.putJson<Map<String, dynamic>>('/users/me', body: body));
  }

  Future<UserProfile> uploadAvatar(Uint8List bytes,
          {String filename = 'avatar.jpg'}) async =>
      UserProfile.fromJson(await _c.uploadMultipart<Map<String, dynamic>>(
        '/users/me/avatar',
        method: 'PUT', // route is PUT-only; a POST 404s on gorilla/mux
        imageBytes: bytes,
        filename: filename,
      ));

  // ── plants ──────────────────────────────────────────────────────────────
  Future<List<Plant>> plants() async {
    final list = await _c.getJson<List<dynamic>>('/plants');
    return list.map((e) => Plant.fromJson(asMap(e))).toList();
  }

  Future<Plant> plant(int id) async =>
      Plant.fromJson(await _c.getJson<Map<String, dynamic>>('/plants/$id'));

  Future<Plant> updatePlantPhoto(int id, Uint8List bytes,
          {String filename = 'plant.jpg'}) async =>
      Plant.fromJson(await _c.uploadMultipart<Map<String, dynamic>>(
        '/plants/$id/photo',
        method: 'PUT',
        imageBytes: bytes,
        filename: filename,
      ));

  Future<List<Plant>> searchPlants(String query) async {
    final list = await _c
        .getJson<List<dynamic>>('/plants/search', query: {'q': query});
    return list.map((e) => Plant.fromJson(asMap(e))).toList();
  }

  Future<Plant> updatePlant(
    int id, {
    String? nickname,
    String? location,
    int? healthScore,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (location != null) body['location'] = location;
    if (healthScore != null) body['health_score'] = healthScore;
    if (status != null) body['status'] = status;
    return Plant.fromJson(
        await _c.putJson<Map<String, dynamic>>('/plants/$id', body: body));
  }

  Future<void> deletePlant(int id) =>
      _c.deleteJson<Map<String, dynamic>>('/plants/$id');

  Future<CarePlan> carePlan(int plantId) async => CarePlan.fromJson(
      await _c.getJson<Map<String, dynamic>>('/plants/$plantId/care-plan'));

  Future<List<GrowthMetric>> growth(int plantId) async {
    final list = await _c.getJson<List<dynamic>>('/plants/$plantId/growth');
    return list.map((e) => GrowthMetric.fromJson(asMap(e))).toList();
  }

  Future<GrowthMetric> logGrowth(
    int plantId, {
    required double heightCm,
    String rate = 'moderate',
  }) async =>
      GrowthMetric.fromJson(await _c.postJson<Map<String, dynamic>>(
        '/plants/$plantId/growth',
        body: {'height_cm': heightCm, 'growth_rate_status': rate},
      ));

  Future<void> createReminder(
    int plantId, {
    required String taskType,
    required DateTime scheduledTime,
  }) =>
      _c.postJson<Map<String, dynamic>>('/plants/$plantId/reminders', body: {
        'task_type': taskType,
        'scheduled_time': scheduledTime.toUtc().toIso8601String(),
      });

  Future<List<ActivityLog>> activities(int plantId) async {
    final list = await _c.getJson<List<dynamic>>('/plants/$plantId/activities');
    return list.map((e) => ActivityLog.fromJson(asMap(e))).toList();
  }

  Future<ActivityLog> logActivity(
    int plantId, {
    required String activityType,
    String notes = '',
    String photoUrl = '',
  }) async =>
      ActivityLog.fromJson(await _c.postJson<Map<String, dynamic>>(
        '/plants/$plantId/activities',
        body: {
          'activity_type': activityType,
          'notes': notes,
          'photo_url': photoUrl,
        },
      ));

  // ── reminders ───────────────────────────────────────────────────────────
  Future<List<Reminder>> todayReminders() async {
    final list = await _c.getJson<List<dynamic>>('/reminders/today');
    return list.map((e) => Reminder.fromJson(asMap(e))).toList();
  }

  Future<List<Reminder>> reminders({
    int? plantId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final q = <String, String>{};
    if (plantId != null) q['plant_id'] = '$plantId';
    if (status != null) q['status'] = status;
    if (from != null) q['from'] = _ymd(from);
    if (to != null) q['to'] = _ymd(to);
    final list = await _c.getJson<List<dynamic>>('/reminders', query: q);
    return list.map((e) => Reminder.fromJson(asMap(e))).toList();
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Reminder> updateReminder(int id,
      {bool? isCompleted, bool? snooze, bool? skip}) async {
    final body = <String, dynamic>{};
    if (isCompleted != null) body['is_completed'] = isCompleted;
    if (snooze != null) body['snooze'] = snooze;
    if (skip != null) body['skip'] = skip;
    return Reminder.fromJson(
        await _c.putJson<Map<String, dynamic>>('/reminders/$id', body: body));
  }

  Future<void> deleteReminder(int id) =>
      _c.deleteJson<Map<String, dynamic>>('/reminders/$id');

  // ── journal ─────────────────────────────────────────────────────────────
  Future<List<JournalEntry>> journal({int? plantId}) async {
    final q = plantId == null ? null : {'plant_id': '$plantId'};
    final list = await _c.getJson<List<dynamic>>('/journal', query: q);
    return list.map((e) => JournalEntry.fromJson(asMap(e))).toList();
  }

  Future<JournalEntry> journalEntry(int id) async => JournalEntry.fromJson(
      await _c.getJson<Map<String, dynamic>>('/journal/$id'));

  Future<void> deleteJournalEntry(int id) =>
      _c.deleteJson<Map<String, dynamic>>('/journal/$id');

  /// `POST /journal` is multipart form-data (text fields + optional photo).
  Future<JournalEntry> createJournalEntry({
    required String type,
    int? plantId,
    String note = '',
    DateTime? date,
    Uint8List? imageBytes,
  }) async {
    final fields = <String, String>{'type': type, 'note': note};
    if (plantId != null) fields['plant_id'] = '$plantId';
    if (date != null) {
      fields['date'] =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return JournalEntry.fromJson(await _c.uploadMultipart<Map<String, dynamic>>(
      '/journal',
      fields: fields,
      imageBytes: imageBytes,
    ));
  }

  // ── community ───────────────────────────────────────────────────────────

  /// Maps the app's display labels to the backend's category slugs
  /// (`tips`, `showcase`, `qa`, `local`). "Q&A".toLowerCase() would be
  /// "q&a", which the API doesn't recognise.
  static String categorySlug(String label) => switch (label) {
        'Q&A' => 'qa',
        'Showcase' => 'showcase',
        'Local' => 'local',
        'Tips' => 'tips',
        _ => label.toLowerCase(),
      };

  Future<List<CommunityPost>> communityPosts({
    String? category,
    int offset = 0,
    int limit = 20,
  }) async {
    final q = <String, String>{'offset': '$offset', 'limit': '$limit'};
    if (category != null && category != 'All') {
      q['category'] = categorySlug(category);
    }
    final list = await _c.getJson<List<dynamic>>('/community/posts', query: q);
    return list.map((e) => CommunityPost.fromJson(asMap(e))).toList();
  }

  Future<CommunityPost> likePost(int id) async => CommunityPost.fromJson(
      await _c.postJson<Map<String, dynamic>>('/community/posts/$id/like'));

  Future<CommunityPost> unlikePost(int id) async => CommunityPost.fromJson(
      await _c.deleteJson<Map<String, dynamic>>('/community/posts/$id/like'));

  Future<CommunityPost> createCommunityPost({
    required String category,
    required String text,
    String emoji = '',
    String imageUrl = '',
  }) async =>
      CommunityPost.fromJson(await _c.postJson<Map<String, dynamic>>(
        '/community/posts',
        body: {
          'category': categorySlug(category),
          'text': text,
          'emoji': emoji,
          'image_url': imageUrl,
        },
      ));

  Future<CommunityPost> communityPost(int id) async => CommunityPost.fromJson(
      await _c.getJson<Map<String, dynamic>>('/community/posts/$id'));

  Future<List<CommunityComment>> postComments(int postId) async {
    final list =
        await _c.getJson<List<dynamic>>('/community/posts/$postId/comments');
    return list.map((e) => CommunityComment.fromJson(asMap(e))).toList();
  }

  Future<CommunityComment> createComment(int postId, String text) async =>
      CommunityComment.fromJson(await _c.postJson<Map<String, dynamic>>(
        '/community/posts/$postId/comments',
        body: {'text': text},
      ));

  // ── weather ─────────────────────────────────────────────────────────────

  Forecast? _lastForecast;

  /// Tries the backend `/weather` proxy first; if it's down (it 502s when its
  /// upstream is flaky) falls back to calling Open-Meteo directly from the
  /// app — same free, key-less API the backend uses — so the weather page
  /// isn't at the mercy of one hop. Returns the last good forecast if both
  /// fail.
  Future<Forecast> weather({double lat = 9.03, double lng = 38.74}) async {
    try {
      final f = Forecast.fromJson(await _c.getJson<Map<String, dynamic>>(
        '/weather',
        query: {'lat': '$lat', 'lng': '$lng'},
      ));
      if (f.hourly.isNotEmpty || f.daily.isNotEmpty || f.current.temp != 0) {
        _lastForecast = f;
        return f;
      }
      throw ApiException('empty forecast');
    } catch (_) {
      try {
        final f = await _openMeteo(lat, lng);
        _lastForecast = f;
        return f;
      } catch (e) {
        if (_lastForecast != null) return _lastForecast!;
        throw ApiException(
            'Weather is unavailable right now. Pull to try again.');
      }
    }
  }

  Future<Forecast> _openMeteo(double lat, double lng) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lng&current_weather=true'
      '&hourly=temperature_2m,relative_humidity_2m'
      '&daily=temperature_2m_max,temperature_2m_min,weathercode'
      '&forecast_days=7&timezone=auto',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw ApiException('open-meteo ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final cw = asMap(j['current_weather']);
    final hourly = asMap(j['hourly']);
    final daily = asMap(j['daily']);
    final hTimes = asList(hourly['time']);
    final hTemps = asList(hourly['temperature_2m']);
    final hHum = asList(hourly['relative_humidity_2m']);
    final dTimes = asList(daily['time']);
    final dMax = asList(daily['temperature_2m_max']);
    final dMin = asList(daily['temperature_2m_min']);
    final dCode = asList(daily['weathercode']);

    return Forecast(
      current: CurrentWeather(
        temp: asDouble(cw['temperature']).round(),
        humidity: hHum.isEmpty ? 0 : asDouble(hHum.first).round(),
        icon: _wmoIcon(asInt(cw['weathercode'])),
      ),
      hourly: [
        for (var i = 0; i < hTimes.length && i < hTemps.length && i < 24; i++)
          HourlyWeather(
            hour: hTimes[i].toString().length >= 16
                ? hTimes[i].toString().substring(11, 16)
                : hTimes[i].toString(),
            temp: asDouble(hTemps[i]).round(),
          ),
      ],
      daily: [
        for (var i = 0; i < dTimes.length && i < dMax.length && i < dMin.length; i++)
          DailyWeather(
            date: dTimes[i].toString(),
            high: asDouble(dMax[i]).round(),
            low: asDouble(dMin[i]).round(),
            icon: _wmoIcon(i < dCode.length ? asInt(dCode[i]) : 0),
          ),
      ],
    );
  }

  static String _wmoIcon(int code) {
    if (code == 0) return 'sunny';
    if (code <= 3) return 'cloudy';
    if (code == 45 || code == 48) return 'fog';
    if (code >= 51 && code <= 67) return 'rainy';
    if (code >= 71 && code <= 77) return 'snowy';
    if (code >= 80 && code <= 82) return 'rainy';
    if (code >= 85 && code <= 86) return 'snowy';
    if (code >= 95) return 'stormy';
    return 'cloudy';
  }

  // ── notifications ───────────────────────────────────────────────────────
  Future<NotificationSettings> notificationSettings() async =>
      NotificationSettings.fromJson(
          await _c.getJson<Map<String, dynamic>>('/notifications'));

  Future<NotificationSettings> updateNotificationSettings(
          NotificationSettings s) async =>
      NotificationSettings.fromJson(await _c.putJson<Map<String, dynamic>>(
          '/notifications',
          body: s.toUpdateJson()));

  Future<List<InboxItem>> inbox({
    int offset = 0,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    final list = await _c.getJson<List<dynamic>>('/notifications/inbox', query: {
      'offset': '$offset',
      'limit': '$limit',
      'unreadOnly': '$unreadOnly',
    });
    return list.map((e) => InboxItem.fromJson(asMap(e))).toList();
  }

  Future<int> unreadCount() async {
    final j = await _c.getJson<Map<String, dynamic>>('/notifications/unread-count');
    return asInt(pick(j, ['count', 'unread', 'unread_count']));
  }

  Future<void> markRead(int id) =>
      _c.patchJson<Map<String, dynamic>>('/notifications/$id/read');

  Future<void> markAllRead() =>
      _c.postJson<Map<String, dynamic>>('/notifications/read-all');

  Future<void> deleteNotification(int id) =>
      _c.deleteJson<Map<String, dynamic>>('/notifications/$id');

  // ── scan ────────────────────────────────────────────────────────────────
  Future<ScanResult> scan(Uint8List bytes,
          {String filename = 'plant.jpg'}) async =>
      ScanResult.fromJson(await _c.uploadImage<Map<String, dynamic>>(
        '/scan',
        bytes: bytes,
        filename: filename,
      ));

  Future<ScanResult> scanDetails(int id) async => ScanResult.fromJson(
      await _c.getJson<Map<String, dynamic>>('/scan/$id'));

  Future<Map<String, dynamic>> confirmScan(
    int scanId, {
    required String nickname,
    required String location,
  }) =>
      _c.postJson<Map<String, dynamic>>('/scan/$scanId/confirm', body: {
        'nickname': nickname,
        'location': location,
      });

  // ── diagnosis ───────────────────────────────────────────────────────────
  Future<DiagnosisSession> startDiagnosis(Uint8List bytes,
          {String filename = 'plant.jpg'}) async =>
      DiagnosisSession.fromJson(await _c.uploadImage<Map<String, dynamic>>(
        '/diagnosis',
        bytes: bytes,
        filename: filename,
      ));

  Future<DiagnosisSession> diagnosisHistory(String sessionId) async =>
      DiagnosisSession.fromJson(
          await _c.getJson<Map<String, dynamic>>('/diagnosis/$sessionId'));

  /// Opens a plant-doctor chat with no image (`POST /diagnosis/chat`). Not
  /// rate limited — unlike `/scan` and `/diagnosis`.
  Future<DiagnosisSession> startChat({
    String context = '',
    String message = '',
  }) async =>
      DiagnosisSession.fromJson(await _c.postJson<Map<String, dynamic>>(
        '/diagnosis/chat',
        body: {'context': context, 'message': message},
      ));

  Future<DiagnosisSession> sendDiagnosisMessage(
          String sessionId, String message) async =>
      DiagnosisSession.fromJson(await _c.postJson<Map<String, dynamic>>(
        '/diagnosis/$sessionId/chat',
        body: {'message': message},
      ));
}
