import 'dart:io';

/// Mock data service for PlantPal — returns realistic fake data for all endpoints
/// so the app works smoothly without a live backend.
class MockData {
  // --- User ---
  static Map<String, dynamic> get me => {
    'id': 1,
    'full_name': 'Sarah Chen',
    'email': 'sarah@plantpal.com',
    'care_streak_days': 12,
    'total_task_done': 87,
    'total_journial_injuries': 14,
    'plants': [
      {'id': 1, 'nickname': 'Fernando', 'health_score': 92, 'photo_url': null},
      {'id': 2, 'nickname': 'Monstera Mike', 'health_score': 78, 'photo_url': null},
      {'id': 3, 'nickname': 'Sunny', 'health_score': 45, 'status': 'needs_attention', 'photo_url': null},
    ],
  };

  static Map<String, dynamic> updatedMe({
    String fullName = 'Sarah Chen',
    String email = 'sarah@plantpal.com',
  }) => {
    ...me,
    'full_name': fullName,
    'email': email,
  };

  // --- Plants ---
  static List<Map<String, dynamic>> get plants => [
    {
      'id': 1, 'nickname': 'Fernando', 'location': 'Living Room', 'health_score': 92,
      'status': 'good', 'species_id': 1,
      'species': {'id': 1, 'common_name': 'Boston Fern', 'scientific_name': 'Nephrolepis exaltata',
        'family': 'Nephrolepidaceae', 'origin': 'Tropical Americas', 'difficulty_level': 'easy', 'pet_safe': true, 'image_url': null},
      'createdAt': '2024-11-15T10:00:00Z',
    },
    {
      'id': 2, 'nickname': 'Monstera Mike', 'location': 'Bedroom', 'health_score': 78,
      'status': 'good', 'species_id': 2,
      'species': {'id': 2, 'common_name': 'Monstera Deliciosa', 'scientific_name': 'Monstera deliciosa',
        'family': 'Araceae', 'origin': 'Central America', 'difficulty_level': 'medium', 'pet_safe': false, 'image_url': null},
      'createdAt': '2024-10-01T08:00:00Z',
    },
    {
      'id': 3, 'nickname': 'Sunny', 'location': 'Balcony', 'health_score': 45,
      'status': 'needs_attention', 'species_id': 3,
      'species': {'id': 3, 'common_name': 'Sunflower', 'scientific_name': 'Helianthus annuus',
        'family': 'Asteraceae', 'origin': 'North America', 'difficulty_level': 'easy', 'pet_safe': false, 'image_url': null},
      'createdAt': '2024-12-01T14:00:00Z',
    },
    {
      'id': 4, 'nickname': 'Lily', 'location': 'Kitchen', 'health_score': 88,
      'status': 'good', 'species_id': 4,
      'species': {'id': 4, 'common_name': 'Peace Lily', 'scientific_name': 'Spathiphyllum wallisii',
        'family': 'Araceae', 'origin': 'Southeast Asia', 'difficulty_level': 'easy', 'pet_safe': false, 'image_url': null},
      'createdAt': '2024-09-20T11:00:00Z',
    },
  ];

  static List<Map<String, dynamic>> searchPlants(String q) {
    return plants.where((p) => (p['nickname'] as String).toLowerCase().contains(q.toLowerCase())
        || ((p['species'] as Map)['common_name'] as String).toLowerCase().contains(q.toLowerCase())).toList();
  }

  static Map<String, dynamic> get fullPlant => {
    ...plants.first,
    'care_plans': [
      {'watering_frequency_days': 3, 'watering_amount': '200ml', 'watering_method': 'Top watering',
        'wateringTips': 'Let top inch of soil dry between waterings',
        'light_requirement': 'Indirect bright light', 'humidity_requirement': 'High (60-80%)',
        'temperature_min_c': 15, 'temperature_max_c': 27, 'soil_type': 'Peat-based mix',
        'fertilizer_type': 'Balanced liquid 20-20-20', 'pruning_frequency': 'Monthly',
        'repotting_frequency': 'Every 1-2 years'},
    ],
    'activity_logs': [
      {'id': 1, 'activity_type': 'watered', 'logged_date': '2025-01-14', 'notes': 'Gave a good soak', 'photo_url': null},
      {'id': 2, 'activity_type': 'fertilized', 'logged_date': '2025-01-10', 'notes': 'Used balanced liquid feed', 'photo_url': null},
      {'id': 3, 'activity_type': 'photo_node', 'logged_date': '2025-01-08', 'notes': null, 'photo_url': null},
    ],
    'growth_metrics': [
      {'id': 1, 'height_cm': 35, 'growth_rate_status': 'fast', 'recorded_date': '2025-01-14'},
      {'id': 2, 'height_cm': 30, 'growth_rate_status': 'moderate', 'recorded_date': '2024-12-14'},
      {'id': 3, 'height_cm': 25, 'growth_rate_status': 'slow', 'recorded_date': '2024-11-14'},
    ],
    'reminders': todayReminders,
  };

  // --- Reminders ---
  static List<Map<String, dynamic>> get todayReminders => [
    {'id': 1, 'plant_id': 1, 'task_type': 'water', 'scheduled_time': '09:00 AM',
      'is_completed': false, 'snooze_count': 0, 'plant': {'id': 1, 'nickname': 'Fernando', 'location': 'Living Room'}},
    {'id': 2, 'plant_id': 2, 'task_type': 'mist', 'scheduled_time': '10:30 AM',
      'is_completed': false, 'snooze_count': 1, 'plant': {'id': 2, 'nickname': 'Monstera Mike', 'location': 'Bedroom'}},
    {'id': 3, 'plant_id': 3, 'task_type': 'water', 'scheduled_time': '08:00 AM',
      'is_completed': true, 'snooze_count': 0, 'plant': {'id': 3, 'nickname': 'Sunny', 'location': 'Balcony'}},
    {'id': 4, 'plant_id': 4, 'task_type': 'fertilize', 'scheduled_time': '11:00 AM',
      'is_completed': false, 'snooze_count': 0, 'plant': {'id': 4, 'nickname': 'Lily', 'location': 'Kitchen'}},
    {'id': 5, 'plant_id': 1, 'task_type': 'rotate', 'scheduled_time': '02:00 PM',
      'is_completed': false, 'snooze_count': 0, 'plant': {'id': 1, 'nickname': 'Fernando', 'location': 'Living Room'}},
  ];

  static List<Map<String, dynamic>> allReminders({String status = 'pending'}) {
    if (status == 'completed') return todayReminders.where((r) => r['is_completed'] == true).toList();
    if (status == 'all') return todayReminders;
    return todayReminders.where((r) => r['is_completed'] == false).toList();
  }

  static Map<String, dynamic> updatedReminder(int id, Map<String, dynamic> fields) {
    final r = todayReminders.firstWhere((r) => r['id'] == id, orElse: () => todayReminders.first);
    return {...r, ...fields};
  }

  // --- Notifications ---
  static int get unreadCount => 3;

  static List<Map<String, dynamic>> get notificationInbox => [
    {'id': 1, 'type': 'reminder', 'title': 'Time to water Fernando!', 'body': 'Your Boston Fern is thirsty. Don\'t forget to check the soil moisture.',
      'is_read': false, 'action_url': null, 'related_plant_id': 1, 'related_reminder_id': 1,
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String()},
    {'id': 2, 'type': 'care_tip', 'title': 'Humidity tip for Monstera', 'body': 'Monstera Mike could use more humidity. Consider a pebble tray or humidifier nearby.',
      'is_read': false, 'action_url': null, 'related_plant_id': 2, 'related_reminder_id': null,
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
    {'id': 3, 'type': 'achievement', 'title': '12-day streak! 🔥', 'body': 'Amazing! You\'ve kept your plants happy for 12 days straight.',
      'is_read': false, 'action_url': null, 'related_plant_id': null, 'related_reminder_id': null,
      'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()},
    {'id': 4, 'type': 'system', 'title': 'Welcome to PlantPal!', 'body': 'Start by scanning a plant or adding one manually.',
      'is_read': true, 'action_url': null, 'related_plant_id': null, 'related_reminder_id': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
  ];

  static Map<String, dynamic> get notificationSettings => {
    'id': 1, 'user_id': 1, 'notification_enabled': true, 'daily_summary_enabled': true,
    'sound_alert_enabled': true, 'vibration_enabled': true,
    'preferred_notification_time': '08:00', 'default_snooze_duration_minute': 15,
  };

  // --- Weather ---
  static Map<String, dynamic> get weather => {
    'current': {
      'temp': 22, 'humidity': 65, 'icon': 'partly_cloudy',
    },
    'daily': [
      {'date': 'Mon', 'high': 25, 'low': 16, 'icon': 'sunny'},
      {'date': 'Tue', 'high': 23, 'low': 15, 'icon': 'cloudy'},
      {'date': 'Wed', 'high': 20, 'low': 13, 'icon': 'rainy'},
      {'date': 'Thu', 'high': 19, 'low': 12, 'icon': 'rainy'},
      {'date': 'Fri', 'high': 22, 'low': 14, 'icon': 'partly_cloudy'},
      {'date': 'Sat', 'high': 24, 'low': 15, 'icon': 'sunny'},
      {'date': 'Sun', 'high': 26, 'low': 17, 'icon': 'sunny'},
    ],
    'hourly': [
      {'hour': 'Now', 'temp': 22},
      {'hour': '1PM', 'temp': 23},
      {'hour': '2PM', 'temp': 24},
      {'hour': '3PM', 'temp': 24},
      {'hour': '4PM', 'temp': 23},
      {'hour': '5PM', 'temp': 22},
      {'hour': '6PM', 'temp': 20},
    ],
  };

  // --- Community ---
  static List<Map<String, dynamic>> get communityPosts => [
    {'id': 1, 'author_name': 'Alex Rivera', 'author_initials': 'AR', 'category': 'tips',
      'text': 'Pro tip: always check the soil moisture before watering. Stick your finger 2 inches into the soil — if it\'s dry, water it. If it\'s still moist, wait another day!',
      'emoji': '💡', 'time': '2h ago', 'likes': 24, 'comments': 8, 'liked_by_me': false},
    {'id': 2, 'author_name': 'Maya Patel', 'author_initials': 'MP', 'category': 'showcase',
      'text': 'Check out my Monstera after 6 months of care! The fenestrations are finally coming in beautifully. Consistent indirect light and weekly watering did the trick.',
      'emoji': '🌿', 'time': '5h ago', 'likes': 47, 'comments': 12, 'liked_by_me': true},
    {'id': 3, 'author_name': 'Jordan Lee', 'author_initials': 'JL', 'category': 'qa',
      'text': 'My pothos has yellow leaves even though I water it regularly. Is it getting too much light or too little? It\'s sitting about 3 feet from a north-facing window.',
      'emoji': '❓', 'time': '8h ago', 'likes': 15, 'comments': 6, 'liked_by_me': false},
    {'id': 4, 'author_name': 'Fatima Al-Rashid', 'author_initials': 'FA', 'category': 'local',
      'text': 'Anyone in Addis Ababa know where I can find a good selection of succulents? Looking for a local nursery that carries rare varieties.',
      'emoji': '📍', 'time': '1d ago', 'likes': 8, 'comments': 4, 'liked_by_me': false},
    {'id': 5, 'author_name': 'Sam Okonkwo', 'author_initials': 'SO', 'category': 'tips',
      'text': 'Bottom watering is a game changer for plants that are prone to root rot. Just fill the saucer and let the soil wick up water naturally. The roots grow downward toward the moisture!',
      'emoji': '💧', 'time': '1d ago', 'likes': 33, 'comments': 11, 'liked_by_me': true},
  ];

  static Map<String, dynamic> newPost(int id, {required String category, required String text, String? emoji}) => {
    'id': id, 'author_name': 'Sarah Chen', 'author_initials': 'SC', 'category': category,
    'text': text, 'emoji': emoji, 'time': 'Just now', 'likes': 0, 'comments': 0, 'liked_by_me': false,
  };

  // --- Scan ---
  static Map<String, dynamic> scanResult(int id) => {
    'id': id,
    'captured_image_url': null,
    'confidence_score': 87,
    'json_identification_payload': {
      'common_name': 'Pothos',
      'scientific_name': 'Epipremnum aureum',
      'family': 'Araceae',
      'description': 'A popular trailing houseplant known for its heart-shaped leaves and easy care requirements.',
    },
    'retake': false,
  };

  static Map<String, dynamic> scanConfirm(int id, {String nickname = 'Pothos', String? location}) => {
    'id': id, 'plant_id': 5, 'nickname': nickname, 'location': location,
  };

  // --- Diagnosis ---
  static Map<String, dynamic> diagnosisStart(String sessionId) => {
    'session_id': sessionId,
    'diagnosis': 'Based on the photo, your plant appears to have **Powdery Mildew** — a common fungal disease.\n\n'
        'Severity: Moderate\n\n'
        'Signs: White powdery spots on leaves\n\n'
        'Treatment:\n'
        '1. Isolate the plant from others\n'
        '2. Remove affected leaves\n'
        '3. Apply neem oil solution\n'
        '4. Improve air circulation\n'
        '5. Reduce humidity around the plant',
  };

  static Map<String, dynamic> diagnosisChat(String sessionId) => {
    'reply': 'Great question! For powdery mildew, I recommend applying a neem oil spray every 7-10 days. '
        'You can mix 1 tablespoon of neem oil with 1 quart of water and a few drops of dish soap. '
        'Spray both sides of the leaves in the evening to avoid sun burn.',
  };

  // --- Placeholder image file ---
  static Future<File> placeholderImage() async {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/mock_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
    return file;
  }
}
