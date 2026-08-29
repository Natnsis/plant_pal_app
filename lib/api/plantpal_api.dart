import 'dart:typed_data';

import '../models/models.dart';
import 'api_client.dart';
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

  Future<UserProfile> updateMe({String? fullName, String? email}) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    return UserProfile.fromJson(
        await _c.putJson<Map<String, dynamic>>('/users/me', body: body));
  }

  // ── plants ──────────────────────────────────────────────────────────────
  Future<List<Plant>> plants() async {
    final list = await _c.getJson<List<dynamic>>('/plants');
    return list.map((e) => Plant.fromJson(asMap(e))).toList();
  }

  Future<Plant> plant(int id) async =>
      Plant.fromJson(await _c.getJson<Map<String, dynamic>>('/plants/$id'));

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

  Future<List<Reminder>> reminders({int? plantId, String? status}) async {
    final q = <String, String>{};
    if (plantId != null) q['plant_id'] = '$plantId';
    if (status != null) q['status'] = status;
    final list = await _c.getJson<List<dynamic>>('/reminders', query: q);
    return list.map((e) => Reminder.fromJson(asMap(e))).toList();
  }

  Future<Reminder> updateReminder(int id,
      {bool? isCompleted, bool? snooze}) async {
    final body = <String, dynamic>{};
    if (isCompleted != null) body['is_completed'] = isCompleted;
    if (snooze != null) body['snooze'] = snooze;
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

  // ── community ───────────────────────────────────────────────────────────
  Future<List<CommunityPost>> communityPosts({
    String? category,
    int offset = 0,
    int limit = 20,
  }) async {
    final q = <String, String>{'offset': '$offset', 'limit': '$limit'};
    if (category != null && category != 'All') q['category'] = category.toLowerCase();
    final list = await _c.getJson<List<dynamic>>('/community/posts', query: q);
    return list.map((e) => CommunityPost.fromJson(asMap(e))).toList();
  }

  Future<CommunityPost> likePost(int id) async => CommunityPost.fromJson(
      await _c.postJson<Map<String, dynamic>>('/community/posts/$id/like'));

  Future<CommunityPost> unlikePost(int id) async => CommunityPost.fromJson(
      await _c.deleteJson<Map<String, dynamic>>('/community/posts/$id/like'));

  // ── weather ─────────────────────────────────────────────────────────────
  Future<Forecast> weather({double lat = 9.03, double lng = 38.74}) async =>
      Forecast.fromJson(await _c.getJson<Map<String, dynamic>>(
        '/weather',
        query: {'lat': '$lat', 'lng': '$lng'},
      ));

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

  Future<DiagnosisSession> sendDiagnosisMessage(
          String sessionId, String message) async =>
      DiagnosisSession.fromJson(await _c.postJson<Map<String, dynamic>>(
        '/diagnosis/$sessionId/chat',
        body: {'message': message},
      ));
}
