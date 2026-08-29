import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'mock_data.dart';

/// Simulate network latency for mock mode
Future<void> _mockDelay() => Future.delayed(const Duration(milliseconds: 400));

/// Mock mode: set to true to use local fake data instead of live API.
/// Set to false when ready to integrate with the real PlantPal backend.
bool useMockData = true;

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class TokenStore {
  static String? _token;
  static String? refreshToken;

  static String? get token => _token;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static void save(String accessToken, [String? refresh]) {
    _token = accessToken;
    refreshToken = refresh;
  }

  static void clear() {
    _token = null;
    refreshToken = null;
  }

  static Map<String, String> get authHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };
}

class AuthService {
  static const _baseUrl = 'https://plant-pal-api-ohhx.onrender.com';

  /// Register a new user. Returns the response body on success.
  static Future<Map<String, dynamic>> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    if (useMockData) {
      await _mockDelay();
      TokenStore.save('mock_access_token_${DateTime.now().millisecondsSinceEpoch}', 'mock_refresh');
      return MockData.me;
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    _handleError(response);
  }

  /// Log in with email and password. Returns the response body on success.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (useMockData) {
      await _mockDelay();
      TokenStore.save('mock_access_token_${DateTime.now().millisecondsSinceEpoch}', 'mock_refresh');
      return {'access_token': TokenStore.token, 'refresh_token': 'mock_refresh', 'user': MockData.me};
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    _handleError(response);
  }

  /// Authenticate with a Google id_token. Returns the response body on success.
  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    if (useMockData) {
      await _mockDelay();
      TokenStore.save('mock_g_token_${DateTime.now().millisecondsSinceEpoch}', 'mock_refresh');
      return {'access_token': TokenStore.token, 'refresh_token': 'mock_refresh', 'user': MockData.me};
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    _handleError(response);
  }

  /// GET /users/me — fetches the authenticated user profile.
  static Future<Map<String, dynamic>> getMe() async {
    if (useMockData) { await _mockDelay(); return MockData.me; }
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: TokenStore.authHeaders,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _handleError(response);
  }

  /// GET /reminders/today — fetches today's reminders.
  static Future<List<Map<String, dynamic>>> getTodayReminders() async {
    if (useMockData) { await _mockDelay(); return MockData.todayReminders; }
    final response = await http.get(
      Uri.parse('$_baseUrl/reminders/today'),
      headers: TokenStore.authHeaders,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      if (body is Map && body.containsKey('reminders')) {
        return (body['reminders'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    _handleError(response);
  }

  /// GET /notifications/unread-count — returns { count: N } or similar.
  static Future<int> getUnreadNotificationCount() async {
    if (useMockData) { await _mockDelay(); return MockData.unreadCount; }
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/unread-count'),
      headers: TokenStore.authHeaders,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      // Read defensively — key name not fixed
      for (final key in ['count', 'unread_count', 'unreadCount', 'total']) {
        if (body.containsKey(key)) {
          final val = body[key];
          if (val is int) return val;
          if (val is String) return int.tryParse(val) ?? 0;
          if (val is num) return val.toInt();
        }
      }
      return 0;
    }
    // Don't throw for badge count — degrade gracefully
    return 0;
  }

  /// GET /weather?lat=&lng= — fetch weather forecast.
  /// Returns null on 502 (upstream weather provider down).
  static Future<Map<String, dynamic>?> getWeather({
    double? lat,
    double? lng,
  }) async {
    if (useMockData) { await _mockDelay(); return MockData.weather; }
    final params = <String, String>{};
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    final uri = Uri.parse('$_baseUrl/weather').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: TokenStore.authHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 502) return null; // degrade gracefully
    _handleError(response);
  }

  /// GET /notifications/inbox — fetch paginated notification list.
  static Future<List<Map<String, dynamic>>> getNotificationInbox({
    int offset = 0,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    if (useMockData) { await _mockDelay(); return MockData.notificationInbox; }
    final params = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
    };
    if (unreadOnly == true) params['unreadOnly'] = 'true';
    final uri = Uri.parse('$_baseUrl/notifications/inbox').replace(
      queryParameters: params,
    );
    final response = await http.get(uri, headers: TokenStore.authHeaders);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) return body.cast<Map<String, dynamic>>();
      if (body is Map && body.containsKey('notifications')) {
        return (body['notifications'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    _handleError(response);
  }

  /// PATCH /notifications/{id}/read — mark a single notification as read.
  static Future<void> markNotificationRead(int id) async {
    if (useMockData) { await _mockDelay(); return; }
    final response = await http.patch(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: TokenStore.authHeaders,
    );
    if (response.statusCode != 200) _handleError(response);
  }

  /// POST /notifications/read-all — mark all as read.
  static Future<void> markAllNotificationsRead() async {
    if (useMockData) { await _mockDelay(); return; }
    final response = await http.post(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: TokenStore.authHeaders,
    );
    if (response.statusCode != 200) _handleError(response);
  }

  /// DELETE /notifications/{id} — delete a notification.
  static Future<void> deleteNotification(int id) async {
    if (useMockData) { await _mockDelay(); return; }
    final response = await http.delete(
      Uri.parse('$_baseUrl/notifications/$id'),
      headers: TokenStore.authHeaders,
    );
    if (response.statusCode != 200) _handleError(response);
  }

  static Never _handleError(http.Response response) {
    String msg;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      msg = (body['error'] ?? body['message'] ?? 'Unknown error').toString();
    } catch (_) {
      msg = 'Something went wrong. Please try again.';
    }
    throw ApiException(response.statusCode, msg);
  }

  // -----------------------------------------------------------------------
  // Scan
  // -----------------------------------------------------------------------

  static Future<Map<String, dynamic>> submitScan(File imageFile) async {
    if (useMockData) { await _mockDelay(); return MockData.scanResult(1); }
    final uri = Uri.parse('$_baseUrl/scan');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${TokenStore.token}';
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _handleError(response);
  }

  static Future<Map<String, dynamic>> getScan(int id) async {
    if (useMockData) { await _mockDelay(); return MockData.scanResult(id); }
    final r = await http.get(Uri.parse('$_baseUrl/scan/$id'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<Map<String, dynamic>> confirmScan(int id, {String? nickname, String? location}) async {
    if (useMockData) { await _mockDelay(); return MockData.scanConfirm(id, nickname: nickname ?? 'Plant', location: location); }
    final r = await http.post(
      Uri.parse('$_baseUrl/scan/$id/confirm'),
      headers: TokenStore.authHeaders,
      body: jsonEncode({
        if (nickname != null) 'nickname': nickname,
        if (location != null && location.isNotEmpty) 'location': location,
      }),
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  /// Extract a token from a loosely-typed API response.
  static String? extractToken(Map<String, dynamic> body) {
    for (final key in ['access_token', 'token', 'accessToken']) {
      if (body.containsKey(key)) return body[key]?.toString();
    }
    return null;
  }

  /// Extract refresh token from response body.
  static String? extractRefreshToken(Map<String, dynamic> body) {
    for (final key in ['refresh_token', 'refreshToken']) {
      if (body.containsKey(key)) return body[key]?.toString();
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // Plants
  // -----------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getPlants() async {
    if (useMockData) { await _mockDelay(); return MockData.plants; }
    final r = await http.get(Uri.parse('$_baseUrl/plants'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) {
      final b = jsonDecode(r.body);
      if (b is List) return b.cast<Map<String, dynamic>>();
      if (b is Map && b.containsKey('plants')) {
        return (b['plants'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    _handleError(r);
  }

  static Future<List<Map<String, dynamic>>> searchPlants(String q) async {
    if (useMockData) { await _mockDelay(); return MockData.searchPlants(q); }
    final r = await http.get(
      Uri.parse('$_baseUrl/plants/search?q=$q'),
      headers: TokenStore.authHeaders,
    );
    if (r.statusCode == 200) {
      final b = jsonDecode(r.body);
      if (b is List) return b.cast<Map<String, dynamic>>();
      return [];
    }
    _handleError(r);
  }

  static Future<Map<String, dynamic>> getPlant(int id) async {
    if (useMockData) { await _mockDelay(); return MockData.fullPlant; }
    final r = await http.get(Uri.parse('$_baseUrl/plants/$id'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<Map<String, dynamic>> createPlant({
    required String nickname,
    String? location,
    int? speciesId,
  }) async {
    if (useMockData) { await _mockDelay(); return {'id': 99, 'nickname': nickname, 'location': location}; }
    final r = await http.post(
      Uri.parse('$_baseUrl/plants'),
      headers: TokenStore.authHeaders,
      body: jsonEncode({
        'nickname': nickname,
        if (location != null && location.isNotEmpty) 'location': location,
        if (speciesId != null) 'species_id': speciesId,
      }),
    );
    if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<Map<String, dynamic>> updatePlant(int id, Map<String, dynamic> fields) async {
    if (useMockData) { await _mockDelay(); return MockData.plants.firstWhere((p) => p['id'] == id, orElse: () => MockData.plants.first); }
    final r = await http.put(
      Uri.parse('$_baseUrl/plants/$id'),
      headers: TokenStore.authHeaders,
      body: jsonEncode(fields),
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<void> deletePlant(int id) async {
    if (useMockData) { await _mockDelay(); return; }
    final r = await http.delete(Uri.parse('$_baseUrl/plants/$id'), headers: TokenStore.authHeaders);
    if (r.statusCode != 200) _handleError(r);
  }

  // -----------------------------------------------------------------------
  // Care Plan
  // -----------------------------------------------------------------------

  static Future<Map<String, dynamic>> getCarePlan(int plantId) async {
    if (useMockData) { await _mockDelay(); return (MockData.fullPlant['care_plans'] as List).first as Map<String, dynamic>; }
    final r = await http.get(Uri.parse('$_baseUrl/plants/$plantId/care-plan'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<Map<String, dynamic>> updateCarePlan(int plantId, Map<String, dynamic> fields) async {
    if (useMockData) { await _mockDelay(); return fields; }
    final r = await http.put(
      Uri.parse('$_baseUrl/plants/$plantId/care-plan'),
      headers: TokenStore.authHeaders,
      body: jsonEncode(fields),
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  // -----------------------------------------------------------------------
  // Activities
  // -----------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getActivities(int plantId) async {
    if (useMockData) { await _mockDelay(); return (MockData.fullPlant['activity_logs'] as List).cast<Map<String, dynamic>>(); }
    final r = await http.get(Uri.parse('$_baseUrl/plants/$plantId/activities'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) {
      final b = jsonDecode(r.body);
      if (b is List) return b.cast<Map<String, dynamic>>();
      return [];
    }
    _handleError(r);
  }

  static Future<Map<String, dynamic>> logActivity(int plantId, {required String type, String? notes, String? photoUrl}) async {
    if (useMockData) { await _mockDelay(); return {'id': 99, 'activity_type': type, 'logged_date': DateTime.now().toIso8601String(), 'notes': notes}; }
    final r = await http.post(
      Uri.parse('$_baseUrl/plants/$plantId/activities'),
      headers: TokenStore.authHeaders,
      body: jsonEncode({
        'activity_type': type,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (photoUrl != null) 'photo_url': photoUrl,
      }),
    );
    if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  // -----------------------------------------------------------------------
  // Growth
  // -----------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getGrowth(int plantId) async {
    if (useMockData) { await _mockDelay(); return (MockData.fullPlant['growth_metrics'] as List).cast<Map<String, dynamic>>(); }
    final r = await http.get(Uri.parse('$_baseUrl/plants/$plantId/growth'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) {
      final b = jsonDecode(r.body);
      if (b is List) return b.cast<Map<String, dynamic>>();
      return [];
    }
    _handleError(r);
  }

  static Future<Map<String, dynamic>> logGrowth(int plantId, {required double heightCm, required String status}) async {
    if (useMockData) { await _mockDelay(); return {'id': 99, 'height_cm': heightCm, 'growth_rate_status': status, 'recorded_date': DateTime.now().toIso8601String()}; }
    final r = await http.post(
      Uri.parse('$_baseUrl/plants/$plantId/growth'),
      headers: TokenStore.authHeaders,
      body: jsonEncode({
        'height_cm': heightCm,
        'growth_rate_status': status,
      }),
    );
    if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  // -----------------------------------------------------------------------
  // Plant Reminders
  // -----------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getPlantReminders(int plantId) async {
    if (useMockData) { await _mockDelay(); return MockData.todayReminders.where((r) => r['plant_id'] == plantId).toList(); }
    final r = await http.get(Uri.parse('$_baseUrl/plants/$plantId/reminders'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) {
      final b = jsonDecode(r.body);
      if (b is List) return b.cast<Map<String, dynamic>>();
      return [];
    }
    _handleError(r);
  }

  static Future<Map<String, dynamic>> createPlantReminder(int plantId, {required String taskType, required String scheduledTime}) async {
    if (useMockData) { await _mockDelay(); return {'id': 99, 'plant_id': plantId, 'task_type': taskType, 'scheduled_time': scheduledTime, 'is_completed': false, 'snooze_count': 0}; }
    final r = await http.post(
      Uri.parse('$_baseUrl/plants/$plantId/reminders'),
      headers: TokenStore.authHeaders,
      body: jsonEncode({
        'task_type': taskType,
        'scheduled_time': scheduledTime,
      }),
    );
    if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  // -----------------------------------------------------------------------
  // Reminder actions (reuse from home)
  // -----------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getAllReminders({int? plantId, String status = 'pending'}) async {
    if (useMockData) { await _mockDelay(); return MockData.allReminders(status: status); }
    final params = <String, String>{'status': status};
    if (plantId != null) params['plant_id'] = plantId.toString();
    final uri = Uri.parse('$_baseUrl/reminders').replace(queryParameters: params);
    final r = await http.get(uri, headers: TokenStore.authHeaders);
    if (r.statusCode == 200) {
      final b = jsonDecode(r.body);
      if (b is List) return b.cast<Map<String, dynamic>>();
      return [];
    }
    _handleError(r);
  }

  static Future<Map<String, dynamic>> updateReminder(int id, Map<String, dynamic> fields) async {
    if (useMockData) { await _mockDelay(); return MockData.updatedReminder(id, fields); }
    final r = await http.put(
      Uri.parse('$_baseUrl/reminders/$id'),
      headers: TokenStore.authHeaders,
      body: jsonEncode(fields),
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<void> deleteReminder(int id) async {
    if (useMockData) { await _mockDelay(); return; }
    final r = await http.delete(Uri.parse('$_baseUrl/reminders/$id'), headers: TokenStore.authHeaders);
    if (r.statusCode != 200) _handleError(r);
  }

  // -----------------------------------------------------------------------
  // Diagnosis
  // -----------------------------------------------------------------------

  static Future<Map<String, dynamic>> startDiagnosis(File imageFile) async {
    if (useMockData) { await _mockDelay(); return MockData.diagnosisStart('mock_session_${DateTime.now().millisecondsSinceEpoch}'); }
    final uri = Uri.parse('$_baseUrl/diagnosis');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${TokenStore.token}';
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _handleError(response);
  }

  static Future<Map<String, dynamic>> getDiagnosis(String sessionId) async {
    if (useMockData) { await _mockDelay(); return {'messages': [{'role': 'ai', 'content': MockData.diagnosisStart(sessionId)['diagnosis']}]}; }
    final r = await http.get(Uri.parse('$_baseUrl/diagnosis/$sessionId'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<Map<String, dynamic>> sendDiagnosisMessage(String sessionId, String message) async {
    if (useMockData) { await _mockDelay(); return MockData.diagnosisChat(sessionId); }
    final r = await http.post(
      Uri.parse('$_baseUrl/diagnosis/$sessionId/chat'),
      headers: TokenStore.authHeaders,
      body: jsonEncode({'message': message}),
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  // -----------------------------------------------------------------------
  // Community
  // -----------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> getCommunityPosts({
    String category = 'all',
    int offset = 0,
    int limit = 20,
  }) async {
    if (useMockData) {
      await _mockDelay();
      var posts = MockData.communityPosts;
      if (category != 'all') posts = posts.where((p) => p['category'] == category).toList();
      return posts.skip(offset).take(limit).toList();
    }
    final params = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
    };
    if (category != 'all') params['category'] = category;
    final uri = Uri.parse('$_baseUrl/community/posts').replace(queryParameters: params);
    final r = await http.get(uri, headers: TokenStore.authHeaders);
    if (r.statusCode == 200) {
      final b = jsonDecode(r.body);
      if (b is List) return b.cast<Map<String, dynamic>>();
      return [];
    }
    _handleError(r);
  }

  static Future<Map<String, dynamic>> createCommunityPost({
    required String category,
    required String text,
    String? emoji,
  }) async {
    if (useMockData) { await _mockDelay(); return MockData.newPost(99, category: category, text: text, emoji: emoji); }
    final r = await http.post(
      Uri.parse('$_baseUrl/community/posts'),
      headers: TokenStore.authHeaders,
      body: jsonEncode({
        'category': category,
        'text': text,
        if (emoji != null) 'emoji': emoji,
      }),
    );
    if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<Map<String, dynamic>> likePost(int id) async {
    if (useMockData) {
      await _mockDelay();
      final post = MockData.communityPosts.firstWhere((p) => p['id'] == id, orElse: () => MockData.communityPosts.first);
      return {...post, 'liked_by_me': true, 'likes': (post['likes'] as int) + 1};
    }
    final r = await http.post(
      Uri.parse('$_baseUrl/community/posts/$id/like'),
      headers: TokenStore.authHeaders,
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<Map<String, dynamic>> unlikePost(int id) async {
    if (useMockData) {
      await _mockDelay();
      final post = MockData.communityPosts.firstWhere((p) => p['id'] == id, orElse: () => MockData.communityPosts.first);
      return {...post, 'liked_by_me': false, 'likes': (post['likes'] as int) - 1};
    }
    final r = await http.delete(
      Uri.parse('$_baseUrl/community/posts/$id/like'),
      headers: TokenStore.authHeaders,
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  // -----------------------------------------------------------------------
  // Profile / Settings
  // -----------------------------------------------------------------------

  static Future<Map<String, dynamic>> updateMe({String? fullName, String? email}) async {
    if (useMockData) { await _mockDelay(); return MockData.updatedMe(fullName: fullName ?? MockData.me['full_name'], email: email ?? MockData.me['email']); }
    final r = await http.put(
      Uri.parse('$_baseUrl/users/me'),
      headers: TokenStore.authHeaders,
      body: jsonEncode({
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
      }),
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<void> logout() async {
    if (useMockData) { await _mockDelay(); return; }
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: TokenStore.authHeaders,
        body: jsonEncode({'refresh_token': TokenStore.refreshToken}),
      );
    } catch (_) {
      // Logout should never be blocked by server failure
    }
  }

  static Future<Map<String, dynamic>> getNotificationSettings() async {
    if (useMockData) { await _mockDelay(); return MockData.notificationSettings; }
    final r = await http.get(Uri.parse('$_baseUrl/notifications'), headers: TokenStore.authHeaders);
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }

  static Future<Map<String, dynamic>> updateNotificationSettings(Map<String, dynamic> fields) async {
    if (useMockData) { await _mockDelay(); return {...MockData.notificationSettings, ...fields}; }
    final r = await http.put(
      Uri.parse('$_baseUrl/notifications'),
      headers: TokenStore.authHeaders,
      body: jsonEncode(fields),
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    _handleError(r);
  }
}
