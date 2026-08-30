import '../api/json_util.dart';

// ─────────────────────────── auth ───────────────────────────

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
    accessToken: asString(pick(j, ['access_token', 'accessToken'])),
    refreshToken: asString(pick(j, ['refresh_token', 'refreshToken'])),
  );

  bool get isValid => accessToken.isNotEmpty;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.imageUrl,
    required this.careStreakDays,
    required this.tasksDone,
    required this.journalEntries,
  });

  final int id;
  final String fullName;
  final String email;
  final String imageUrl;
  final int careStreakDays;
  final int tasksDone;
  final int journalEntries;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '🙂';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: idOf(j),
    fullName: asString(
      pick(j, ['full_name', 'fullName', 'name']),
      'PlantPal user',
    ),
    email: asString(pick(j, ['email'])),
    imageUrl: asString(pick(j, ['image_url', 'imageUrl'])),
    careStreakDays: asInt(pick(j, ['care_streak_days', 'careStreakDays'])),
    tasksDone: asInt(
      pick(j, ['total_task_done', 'totalTaskDone', 'tasks_done']),
    ),
    journalEntries: asInt(
      pick(j, [
        'total_journal_entries',
        'total_journial_injuries', // API's actual (misspelled) key
        'journal_entries',
      ]),
    ),
  );
}

// ─────────────────────────── plants ───────────────────────────

enum PlantHealth { good, needsAttention }

PlantHealth plantHealthFrom(Object? v) => asString(v) == 'needs_attention'
    ? PlantHealth.needsAttention
    : PlantHealth.good;

enum Difficulty { easy, medium, hard }

Difficulty difficultyFrom(Object? v) => switch (asString(v)) {
  'hard' => Difficulty.hard,
  'medium' => Difficulty.medium,
  _ => Difficulty.easy,
};

class Species {
  const Species({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.family,
    required this.origin,
    required this.difficulty,
    required this.petSafe,
    required this.imageUrl,
  });

  final int id;
  final String commonName;
  final String scientificName;
  final String family;
  final String origin;
  final Difficulty difficulty;
  final bool petSafe;
  final String imageUrl;

  static const empty = Species(
    id: 0,
    commonName: 'Unknown plant',
    scientificName: '',
    family: '',
    origin: '',
    difficulty: Difficulty.easy,
    petSafe: true,
    imageUrl: '',
  );

  factory Species.fromJson(Map<String, dynamic> j) => Species(
    id: idOf(j),
    commonName: asString(
      pick(j, ['common_name', 'commonName']),
      'Unknown plant',
    ),
    scientificName: asString(pick(j, ['scientific_name', 'scientificName'])),
    family: asString(pick(j, ['family'])),
    origin: asString(pick(j, ['origin'])),
    difficulty: difficultyFrom(
      pick(j, ['difficulty_level', 'difficultyLevel']),
    ),
    petSafe: asBool(pick(j, ['pet_safe', 'petSafe']), true),
    imageUrl: asString(pick(j, ['image_url', 'imageUrl'])),
  );
}

class Plant {
  const Plant({
    required this.id,
    required this.nickname,
    required this.location,
    required this.imageUrl,
    required this.healthScore,
    required this.health,
    required this.species,
  });

  final int id;
  final String nickname;
  final String location;
  final String imageUrl;
  final int healthScore;
  final PlantHealth health;
  final Species species;

  bool get needsAttention => health == PlantHealth.needsAttention;
  String get displayName => nickname.isNotEmpty ? nickname : species.commonName;

  /// The plant's own photo, falling back to the species reference image.
  String get photoUrl => imageUrl.isNotEmpty ? imageUrl : species.imageUrl;

  factory Plant.fromJson(Map<String, dynamic> j) {
    final sp = pick(j, ['species', 'Species']);
    return Plant(
      id: idOf(j),
      nickname: asString(pick(j, ['nickname', 'name'])),
      location: asString(pick(j, ['location', 'room'])),
      imageUrl: asString(pick(j, ['image_url', 'imageUrl'])),
      healthScore: asInt(pick(j, ['health_score', 'healthScore']), 0),
      health: plantHealthFrom(pick(j, ['status'])),
      species: sp is Map ? Species.fromJson(asMap(sp)) : Species.empty,
    );
  }
}

class CarePlan {
  const CarePlan({
    required this.wateringFrequencyDays,
    required this.wateringAmount,
    required this.wateringMethod,
    required this.wateringTips,
    required this.lightRequirement,
    required this.humidityRequirement,
    required this.soilType,
    required this.fertilizerType,
    required this.pruningFrequency,
    required this.repottingFrequency,
    required this.tempMinC,
    required this.tempMaxC,
  });

  final int wateringFrequencyDays;
  final String wateringAmount;
  final String wateringMethod;
  final String wateringTips;
  final String lightRequirement;
  final String humidityRequirement;
  final String soilType;
  final String fertilizerType;
  final String pruningFrequency;
  final String repottingFrequency;
  final int tempMinC;
  final int tempMaxC;

  factory CarePlan.fromJson(Map<String, dynamic> j) => CarePlan(
    wateringFrequencyDays: asInt(
      pick(j, ['watering_frequency_days', 'wateringFrequencyDays']),
    ),
    wateringAmount: asString(pick(j, ['watering_amount', 'wateringAmount'])),
    wateringMethod: asString(pick(j, ['watering_method', 'wateringMethod'])),
    wateringTips: asString(pick(j, ['watering_tips', 'wateringTips'])),
    lightRequirement: asString(
      pick(j, ['light_requirement', 'lightRequirement']),
    ),
    humidityRequirement: asString(
      pick(j, ['humidity_requirement', 'humidityRequirement']),
    ),
    soilType: asString(pick(j, ['soil_type', 'soilType'])),
    fertilizerType: asString(pick(j, ['fertilizer_type', 'fertilizerType'])),
    pruningFrequency: asString(
      pick(j, ['pruning_frequency', 'pruningFrequency']),
    ),
    repottingFrequency: asString(
      pick(j, ['repotting_frequency', 'repottingFrequency']),
    ),
    tempMinC: asInt(pick(j, ['temperature_min_c', 'temperatureMinC'])),
    tempMaxC: asInt(pick(j, ['temperature_max_c', 'temperatureMaxC'])),
  );
}

class GrowthMetric {
  const GrowthMetric({
    required this.heightCm,
    required this.rate,
    required this.recordedDate,
  });

  final double heightCm;
  final String rate;
  final DateTime? recordedDate;

  factory GrowthMetric.fromJson(Map<String, dynamic> j) => GrowthMetric(
    heightCm: asDouble(pick(j, ['height_cm', 'heightCm'])),
    rate: asString(pick(j, ['growth_rate_status', 'growthRateStatus'])),
    recordedDate: asDate(pick(j, ['recorded_date', 'recordedDate'])),
  );
}

class ActivityLog {
  const ActivityLog({
    required this.type,
    required this.notes,
    required this.photoUrl,
    required this.loggedDate,
  });

  final String type;
  final String notes;
  final String photoUrl;
  final DateTime? loggedDate;

  factory ActivityLog.fromJson(Map<String, dynamic> j) => ActivityLog(
    type: asString(pick(j, ['activity_type', 'activityType'])),
    notes: asString(pick(j, ['notes'])),
    photoUrl: asString(pick(j, ['photo_url', 'photoUrl'])),
    loggedDate:
        asDate(pick(j, ['logged_date', 'loggedDate'])) ?? createdAtOf(j),
  );
}

// ─────────────────────────── reminders ───────────────────────────

enum TaskType { water, fertilize, mist, rotate, repot }

TaskType taskTypeFrom(Object? v) => switch (asString(v)) {
  'fertilize' => TaskType.fertilize,
  'mist' => TaskType.mist,
  'rotate' => TaskType.rotate,
  'repot' => TaskType.repot,
  _ => TaskType.water,
};

/// Where a reminder sits in its lifecycle, derived from the raw fields.
enum ReminderStatus { done, skipped, missed, dueToday, upcoming }

class Reminder {
  const Reminder({
    required this.id,
    required this.plantId,
    required this.taskType,
    required this.scheduledTime,
    required this.isCompleted,
    required this.skipped,
    required this.completedAt,
    required this.snoozeCount,
    required this.plantName,
    required this.plantLocation,
  });

  final int id;
  final int plantId;
  final TaskType taskType;
  final DateTime? scheduledTime;
  final bool isCompleted;
  final bool skipped;
  final DateTime? completedAt;
  final int snoozeCount;
  final String plantName;
  final String plantLocation;

  String get verb => switch (taskType) {
        TaskType.water => 'Water',
        TaskType.fertilize => 'Feed',
        TaskType.mist => 'Mist',
        TaskType.rotate => 'Rotate',
        TaskType.repot => 'Repot',
      };

  String get title => plantName.isEmpty ? verb : '$verb $plantName';

  ReminderStatus get status {
    if (isCompleted) return skipped ? ReminderStatus.skipped : ReminderStatus.done;
    final t = scheduledTime;
    if (t == null) return ReminderStatus.dueToday;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    if (t.isBefore(DateTime(now.year, now.month, now.day))) {
      return ReminderStatus.missed;
    }
    if (t.isBefore(endOfToday)) return ReminderStatus.dueToday;
    return ReminderStatus.upcoming;
  }

  /// The calendar day this reminder belongs to (for bucketing into a strip).
  DateTime get day {
    final t = scheduledTime ?? completedAt ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  Reminder copyWith({bool? isCompleted, bool? skipped, int? snoozeCount}) =>
      Reminder(
        id: id,
        plantId: plantId,
        taskType: taskType,
        scheduledTime: scheduledTime,
        isCompleted: isCompleted ?? this.isCompleted,
        skipped: skipped ?? this.skipped,
        completedAt: completedAt,
        snoozeCount: snoozeCount ?? this.snoozeCount,
        plantName: plantName,
        plantLocation: plantLocation,
      );

  factory Reminder.fromJson(Map<String, dynamic> j) {
    final plant = asMap(pick(j, ['plant', 'Plant']));
    final sp = asMap(pick(plant, ['species', 'Species']));
    final name = asString(pick(plant, ['nickname', 'name'])).isNotEmpty
        ? asString(pick(plant, ['nickname', 'name']))
        : asString(pick(sp, ['common_name', 'commonName']));
    return Reminder(
      id: idOf(j),
      plantId: asInt(pick(j, ['plant_id', 'plantId'])),
      taskType: taskTypeFrom(pick(j, ['task_type', 'taskType'])),
      scheduledTime: asDate(pick(j, ['scheduled_time', 'scheduledTime'])),
      isCompleted: asBool(pick(j, ['is_completed', 'isCompleted'])),
      skipped: asBool(pick(j, ['skipped'])),
      completedAt: asDate(pick(j, ['completed_at', 'completedAt'])),
      snoozeCount: asInt(pick(j, ['snooze_count', 'snoozeCount'])),
      plantName: name,
      plantLocation: asString(pick(plant, ['location', 'room'])),
    );
  }
}

// ─────────────────────────── journal ───────────────────────────

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.type,
    required this.note,
    required this.imageUrl,
    required this.hasPhoto,
    required this.date,
    required this.plantName,
  });

  final int id;
  final String type;
  final String note;
  final String imageUrl;
  final bool hasPhoto;
  final DateTime? date;
  final String plantName;

  bool get isMilestone => type == 'growth' || type == 'milestone';

  factory JournalEntry.fromJson(Map<String, dynamic> j) {
    final plant = asMap(pick(j, ['plant', 'Plant']));
    final sp = asMap(pick(plant, ['species', 'Species']));
    return JournalEntry(
      id: idOf(j),
      type: asString(pick(j, ['type']), 'note'),
      note: asString(pick(j, ['note', 'text'])),
      imageUrl: asString(pick(j, ['image_url', 'imageUrl'])),
      hasPhoto: asBool(pick(j, ['has_photo', 'hasPhoto'])),
      date: asDate(pick(j, ['date'])) ?? createdAtOf(j),
      plantName: asString(pick(plant, ['nickname', 'name'])).isNotEmpty
          ? asString(pick(plant, ['nickname', 'name']))
          : asString(pick(sp, ['common_name', 'commonName'])),
    );
  }
}

// ─────────────────────────── community ───────────────────────────

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.time,
    required this.emoji,
    required this.category,
    required this.text,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.likedByMe,
  });

  final int id;
  final String authorName;
  final String authorInitials;
  final String time;
  final String emoji;
  final String category;
  final String text;
  final String imageUrl;
  int likes;
  int comments;
  bool likedByMe;

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
    id: idOf(j),
    authorName: asString(pick(j, ['author_name', 'authorName']), 'Member'),
    authorInitials: asString(
      pick(j, ['author_initials', 'authorInitials']),
      '··',
    ),
    time: asString(pick(j, ['time'])),
    emoji: asString(pick(j, ['emoji'])),
    category: asString(pick(j, ['category']), 'Tips'),
    text: asString(pick(j, ['text'])),
    imageUrl: asString(pick(j, ['image_url', 'imageUrl'])),
    likes: asInt(pick(j, ['likes'])),
    comments: asInt(pick(j, ['comments'])),
    likedByMe: asBool(pick(j, ['liked_by_me', 'likedByMe'])),
  );
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.time,
    required this.text,
  });

  final int id;
  final String authorName;
  final String authorInitials;
  final String time;
  final String text;

  factory CommunityComment.fromJson(Map<String, dynamic> j) => CommunityComment(
        id: idOf(j),
        authorName: asString(pick(j, ['author_name', 'authorName']), 'Member'),
        authorInitials:
            asString(pick(j, ['author_initials', 'authorInitials']), '··'),
        time: asString(pick(j, ['time'])),
        text: asString(pick(j, ['text'])),
      );
}

// ─────────────────────────── weather ───────────────────────────

class Forecast {
  const Forecast({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  factory Forecast.fromJson(Map<String, dynamic> j) => Forecast(
    current: CurrentWeather.fromJson(asMap(pick(j, ['current']))),
    hourly: asList(pick(j, ['hourly']))
        .map((e) => HourlyWeather.fromJson(asMap(e)))
        .toList(),
    daily: asList(pick(j, ['daily']))
        .map((e) => DailyWeather.fromJson(asMap(e)))
        .toList(),
  );
}

class CurrentWeather {
  const CurrentWeather({
    required this.temp,
    required this.humidity,
    required this.icon,
  });
  final int temp;
  final int humidity;
  final String icon;
  factory CurrentWeather.fromJson(Map<String, dynamic> j) => CurrentWeather(
    temp: asInt(pick(j, ['temp'])),
    humidity: asInt(pick(j, ['humidity'])),
    icon: asString(pick(j, ['icon'])),
  );
}

class HourlyWeather {
  const HourlyWeather({required this.hour, required this.temp});
  final String hour;
  final int temp;
  factory HourlyWeather.fromJson(Map<String, dynamic> j) => HourlyWeather(
    hour: asString(pick(j, ['hour'])),
    temp: asInt(pick(j, ['temp'])),
  );
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.high,
    required this.low,
    required this.icon,
  });
  final String date;
  final int high;
  final int low;
  final String icon;
  factory DailyWeather.fromJson(Map<String, dynamic> j) => DailyWeather(
    date: asString(pick(j, ['date'])),
    high: asInt(pick(j, ['high'])),
    low: asInt(pick(j, ['low'])),
    icon: asString(pick(j, ['icon'])),
  );
}

// ─────────────────────────── notifications ───────────────────────────

class NotificationSettings {
  const NotificationSettings({
    required this.notificationEnabled,
    required this.dailySummaryEnabled,
    required this.soundAlertEnabled,
    required this.vibrationEnabled,
    required this.preferredTime,
    required this.snoozeMinutes,
  });

  final bool notificationEnabled;
  final bool dailySummaryEnabled;
  final bool soundAlertEnabled;
  final bool vibrationEnabled;
  final DateTime? preferredTime;
  final int snoozeMinutes;

  String get preferredTimeLabel {
    final t = preferredTime;
    if (t == null) return '08:00';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  NotificationSettings copyWith({
    bool? notificationEnabled,
    bool? dailySummaryEnabled,
    bool? soundAlertEnabled,
    bool? vibrationEnabled,
    DateTime? preferredTime,
    int? snoozeMinutes,
  }) => NotificationSettings(
    notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
    soundAlertEnabled: soundAlertEnabled ?? this.soundAlertEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    preferredTime: preferredTime ?? this.preferredTime,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
  );

  Map<String, dynamic> toUpdateJson() => {
    'notification_enabled': notificationEnabled,
    'daily_summary_enabled': dailySummaryEnabled,
    'sound_alert_enabled': soundAlertEnabled,
    'vibration_enabled': vibrationEnabled,
    'default_snooze_duration_minute': snoozeMinutes,
    // API rejects bare "HH:mm" — needs a full RFC3339 datetime.
    'preferred_notification_time': '0001-01-01T$preferredTimeLabel:00Z',
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> j) =>
      NotificationSettings(
        notificationEnabled: asBool(
          pick(j, ['notification_enabled', 'notificationEnabled']),
          true,
        ),
        dailySummaryEnabled: asBool(
          pick(j, ['daily_summary_enabled', 'dailySummaryEnabled']),
        ),
        soundAlertEnabled: asBool(
          pick(j, ['sound_alert_enabled', 'soundAlertEnabled']),
        ),
        vibrationEnabled: asBool(
          pick(j, ['vibration_enabled', 'vibrationEnabled']),
          true,
        ),
        preferredTime: asDate(
          pick(j, ['preferred_notification_time', 'preferredNotificationTime']),
        ),
        snoozeMinutes: asInt(
          pick(j, [
            'default_snooze_duration_minute',
            'defaultSnoozeDurationMinute',
          ]),
          15,
        ),
      );
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.actionUrl,
    required this.createdAt,
  });

  final int id;
  final String type; // reminder | care_tip | system | achievement
  final String title;
  final String body;
  final bool isRead;
  final String actionUrl;
  final DateTime? createdAt;

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
    id: idOf(j),
    type: asString(pick(j, ['type']), 'system'),
    title: asString(pick(j, ['title'])),
    body: asString(pick(j, ['body'])),
    isRead: asBool(pick(j, ['is_read', 'isRead'])),
    actionUrl: asString(pick(j, ['action_url', 'actionUrl'])),
    createdAt: createdAtOf(j),
  );
}

// ─────────────────────────── scan / diagnosis ───────────────────────────

/// `/scan` and `/scan/{id}` return an open-ended object; keep the raw map
/// and expose best-effort accessors.
class ScanResult {
  ScanResult(this.raw);
  final Map<String, dynamic> raw;

  Map<String, dynamic> get _scan {
    final s = pick(raw, ['scan', 'Scan']);
    return s is Map ? asMap(s) : raw;
  }

  /// `/scan` nests the identified species under `identification`.
  Map<String, dynamic> get _ident {
    final i = pick(raw, ['identification', 'Identification']);
    return i is Map ? asMap(i) : const {};
  }

  int get id => idOf(_scan) == 0
      ? asInt(pick(raw, ['id', 'scan_id', 'scanId', 'ID']))
      : idOf(_scan);
  double get confidence =>
      asDouble(
            pick(raw, ['confidence_score', 'confidence', 'confidenceScore']),
          ) ==
          0
      ? asDouble(pick(_scan, ['confidence_score', 'confidenceScore']))
      : asDouble(
          pick(raw, ['confidence_score', 'confidence', 'confidenceScore']),
        );
  int get confidencePercent =>
      (confidence <= 1 ? confidence * 100 : confidence).round();

  /// The photo wasn't a plant at all (the model was told to return
  /// "NOT_A_PLANT" for faces / objects / scenery).
  bool get notAPlant =>
      asBool(pick(raw, ['not_a_plant', 'notAPlant'])) ||
      commonName.toUpperCase().replaceAll(' ', '_') == 'NOT_A_PLANT';

  /// The API sets `retake: true` on a low-confidence identification (score
  /// below 0.7). Also treat a non-plant or plainly-unidentified result as
  /// needing a retake.
  bool get retake =>
      notAPlant ||
      asBool(pick(raw, ['retake', 'Retake'])) ||
      commonName == 'Identified plant' ||
      confidencePercent < 55;

  String get commonName => asString(
        pick(raw, ['common_name', 'commonName', 'name']) ??
            pick(_ident, ['common_name', 'commonName', 'name']),
        'Identified plant',
      );
  String get scientificName => asString(
        pick(raw, ['scientific_name', 'scientificName', 'species']) ??
            pick(_ident, ['scientific_name', 'scientificName', 'species']),
      );
  String get family => asString(
        pick(raw, ['family']) ?? pick(_ident, ['family']),
      );
  String get imageUrl => asString(pick(raw, [
        'captured_image_url',
        'capturedImageUrl',
        'image_url',
        'imageUrl',
      ]));

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(j);
}

class DiagnosisMessage {
  const DiagnosisMessage({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;

  factory DiagnosisMessage.fromJson(Map<String, dynamic> j) {
    // The API's AiChat rows use `sender_type` ("user" | "ai") and
    // `message_body`; keep the older aliases too for safety.
    final role = asString(
      pick(j, ['role', 'sender', 'author', 'sender_type', 'senderType']),
    ).toLowerCase();
    final fromUser = asBool(pick(j, ['is_user', 'isUser', 'me'])) ||
        role == 'user' ||
        role == 'me';
    return DiagnosisMessage(
      fromUser: fromUser,
      text: asString(
        pick(j, ['message', 'text', 'content', 'message_body', 'messageBody']),
      ),
    );
  }
}

class DiagnosisSession {
  DiagnosisSession({
    required this.id,
    required this.messages,
    required this.raw,
  });

  final String id;
  final List<DiagnosisMessage> messages;
  final Map<String, dynamic> raw;

  factory DiagnosisSession.fromJson(Map<String, dynamic> j) {
    final id = asString(pick(j, ['session_id', 'sessionId', 'id', 'ID']));
    final rawMsgs =
        pick(j, ['chat_history', 'chatHistory', 'messages', 'chat', 'history']);
    final msgs = asList(rawMsgs)
        .map((e) => DiagnosisMessage.fromJson(asMap(e)))
        .toList();
    return DiagnosisSession(id: id, messages: msgs, raw: j);
  }
}
