library;

/// Data models for PlantPal app.

class PlantUser {
  final int id;
  final String fullName;
  final String email;
  final int careStreakDays;
  final int totalTaskDone;
  final int totalJournalInjuries;
  final List<PlantSummary> plants;
  final List<dynamic> notifications;

  PlantUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.careStreakDays,
    required this.totalTaskDone,
    required this.totalJournalInjuries,
    this.plants = const [],
    this.notifications = const [],
  });

  factory PlantUser.fromJson(Map<String, dynamic> json) {
    return PlantUser(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      careStreakDays: json['care_streak_days'] ?? 0,
      totalTaskDone: json['total_task_done'] ?? 0,
      totalJournalInjuries: json['total_journial_injuries'] ?? 0,
      plants: (json['plants'] as List<dynamic>?)
              ?.map((p) => PlantSummary.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      notifications: json['notifications'] as List<dynamic>? ?? [],
    );
  }

  String get firstName => fullName.split(' ').first;
}

class PlantSummary {
  final int id;
  final String nickname;
  final String? photoUrl;
  final double? healthScore;

  PlantSummary({
    required this.id,
    required this.nickname,
    this.photoUrl,
    this.healthScore,
  });

  factory PlantSummary.fromJson(Map<String, dynamic> json) {
    return PlantSummary(
      id: json['id'] ?? 0,
      nickname: json['nickname'] ?? json['name'] ?? 'Unknown',
      photoUrl: json['photo_url'],
      healthScore: (json['health_score'] as num?)?.toDouble(),
    );
  }
}

// ---------------------------------------------------------------------------
// Reminder
// ---------------------------------------------------------------------------

class Reminder {
  final int id;
  final int plantId;
  final String taskType;
  final String scheduledTime;
  final bool isCompleted;
  final int snoozeCount;
  final PlantSummary? plant;

  Reminder({
    required this.id,
    required this.plantId,
    required this.taskType,
    required this.scheduledTime,
    required this.isCompleted,
    this.snoozeCount = 0,
    this.plant,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] ?? 0,
      plantId: json['plant_id'] ?? 0,
      taskType: json['task_type'] ?? 'water',
      scheduledTime: json['scheduled_time'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      snoozeCount: json['snooze_count'] ?? 0,
      plant: json['plant'] != null
          ? PlantSummary.fromJson(json['plant'] as Map<String, dynamic>)
          : null,
    );
  }

  String get taskLabel {
    switch (taskType) {
      case 'water':
        return '💧 Water';
      case 'fertilize':
        return '🌱 Fertilize';
      case 'mist':
        return '💦 Mist';
      case 'rotate':
        return '🔄 Rotate';
      case 'repot':
        return '🪴 Repot';
      default:
        return '📋 Task';
    }
  }
}

// ---------------------------------------------------------------------------
// Weather
// ---------------------------------------------------------------------------

class WeatherForecast {
  final WeatherCurrent? current;
  final List<WeatherDaily> daily;
  final List<WeatherHourly> hourly;

  WeatherForecast({
    this.current,
    this.daily = const [],
    this.hourly = const [],
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      current: json['current'] != null
          ? WeatherCurrent.fromJson(json['current'] as Map<String, dynamic>)
          : null,
      daily: (json['daily'] as List<dynamic>?)
              ?.map((d) => WeatherDaily.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      hourly: (json['hourly'] as List<dynamic>?)
              ?.map((h) => WeatherHourly.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WeatherCurrent {
  final double temp;
  final double humidity;
  final String icon;

  WeatherCurrent({required this.temp, required this.humidity, required this.icon});

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) {
    return WeatherCurrent(
      temp: (json['temp'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] ?? '☀️',
    );
  }

  String get emoji => _mapWeatherIcon(icon);

  static String _mapWeatherIcon(String code) {
    if (code.contains('rain') || code.contains('drizzle')) return '🌧️';
    if (code.contains('cloud')) return '⛅';
    if (code.contains('thunder')) return '⛈️';
    if (code.contains('snow')) return '❄️';
    if (code.contains('fog') || code.contains('mist')) return '🌫️';
    return '☀️';
  }


}

class WeatherDaily {
  final String date;
  final double high;
  final double low;
  final String icon;

  WeatherDaily({required this.date, required this.high, required this.low, required this.icon});

  factory WeatherDaily.fromJson(Map<String, dynamic> json) {
    return WeatherDaily(
      date: json['date'] ?? '',
      high: (json['high'] as num?)?.toDouble() ?? 0,
      low: (json['low'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] ?? '☀️',
    );
  }
}

class WeatherHourly {
  final String hour;
  final double temp;

  WeatherHourly({required this.hour, required this.temp});

  factory WeatherHourly.fromJson(Map<String, dynamic> json) {
    return WeatherHourly(
      hour: json['hour'] ?? '',
      temp: (json['temp'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Notification
// ---------------------------------------------------------------------------

enum NotificationType { reminder, careTip, system, achievement }

class NotificationItem {
  final int id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String? actionUrl;
  final int? relatedPlantId;
  final int? relatedReminderId;
  final DateTime? createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.actionUrl,
    this.relatedPlantId,
    this.relatedReminderId,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      type: _parseType(json['type']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] ?? false,
      actionUrl: json['action_url'],
      relatedPlantId: json['related_plant_id'],
      relatedReminderId: json['related_reminder_id'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  static NotificationType _parseType(dynamic value) {
    switch (value?.toString()) {
      case 'reminder':
        return NotificationType.reminder;
      case 'care_tip':
        return NotificationType.careTip;
      case 'system':
        return NotificationType.system;
      case 'achievement':
        return NotificationType.achievement;
      default:
        return NotificationType.system;
    }
  }

  String get typeEmoji {
    switch (type) {
      case NotificationType.reminder:
        return '🔔';
      case NotificationType.careTip:
        return '🌿';
      case NotificationType.system:
        return 'ℹ️';
      case NotificationType.achievement:
        return '🏆';
    }
  }



  String get relativeTime {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ---------------------------------------------------------------------------
// Species
// ---------------------------------------------------------------------------

class Species {
  final int? id;
  final String commonName;
  final String? scientificName;
  final String? family;
  final String? origin;
  final String? difficultyLevel;
  final String? imageUrl;
  final bool? petSafe;

  Species({
    this.id,
    required this.commonName,
    this.scientificName,
    this.family,
    this.origin,
    this.difficultyLevel,
    this.imageUrl,
    this.petSafe,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['id'],
      commonName: json['common_name'] ?? 'Unknown',
      scientificName: json['scientific_name'],
      family: json['family'],
      origin: json['origin'],
      difficultyLevel: json['difficulty_level'],
      imageUrl: json['image_url'],
      petSafe: json['pet_safe'] as bool?,
    );
  }
}

// ---------------------------------------------------------------------------
// Plant (full)
// ---------------------------------------------------------------------------

class Plant {
  final int id;
  final String nickname;
  final String? location;
  final double? healthScore;
  final String status;
  final int? speciesId;
  final Species? species;
  final DateTime? createdAt;
  final List<CarePlan>? carePlans;
  final List<ActivityLog>? activityLogs;
  final List<GrowthMetric>? growthMetrics;
  final List<Reminder>? reminders;
  final List<dynamic>? scans;

  Plant({
    required this.id,
    required this.nickname,
    this.location,
    this.healthScore,
    this.status = 'good',
    this.speciesId,
    this.species,
    this.createdAt,
    this.carePlans,
    this.activityLogs,
    this.growthMetrics,
    this.reminders,
    this.scans,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? 0,
      nickname: json['nickname'] ?? '',
      location: json['location'],
      healthScore: (json['health_score'] as num?)?.toDouble(),
      status: json['status'] ?? 'good',
      speciesId: json['species_id'],
      species: json['species'] != null
          ? Species.fromJson(json['species'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      carePlans: (json['care_plans'] as List<dynamic>?)
          ?.map((c) => CarePlan.fromJson(c as Map<String, dynamic>))
          .toList(),
      activityLogs: (json['activity_logs'] as List<dynamic>?)
          ?.map((a) => ActivityLog.fromJson(a as Map<String, dynamic>))
          .toList(),
      growthMetrics: (json['growth_metrics'] as List<dynamic>?)
          ?.map((g) => GrowthMetric.fromJson(g as Map<String, dynamic>))
          .toList(),
      reminders: (json['reminders'] as List<dynamic>?)
          ?.map((r) => Reminder.fromJson(r as Map<String, dynamic>))
          .toList(),
      scans: json['scans'] as List<dynamic>?,
    );
  }
}

// ---------------------------------------------------------------------------
// Care Plan
// ---------------------------------------------------------------------------

class CarePlan {
  final int? wateringFrequencyDays;
  final String? wateringAmount;
  final String? wateringMethod;
  final String? wateringTips;
  final String? fertilizerType;
  final String? lightRequirement;
  final String? humidityRequirement;
  final double? temperatureMinC;
  final double? temperatureMaxC;
  final String? soilType;
  final String? pruningFrequency;
  final String? repottingFrequency;

  CarePlan({
    this.wateringFrequencyDays,
    this.wateringAmount,
    this.wateringMethod,
    this.wateringTips,
    this.fertilizerType,
    this.lightRequirement,
    this.humidityRequirement,
    this.temperatureMinC,
    this.temperatureMaxC,
    this.soilType,
    this.pruningFrequency,
    this.repottingFrequency,
  });

  factory CarePlan.fromJson(Map<String, dynamic> json) {
    return CarePlan(
      wateringFrequencyDays: json['watering_frequency_days'],
      wateringAmount: json['watering_amount']?.toString(),
      wateringMethod: json['watering_method']?.toString(),
      wateringTips: json['watering_tips']?.toString(),
      fertilizerType: json['fertilizer_type']?.toString(),
      lightRequirement: json['light_requirement']?.toString(),
      humidityRequirement: json['humidity_requirement']?.toString(),
      temperatureMinC: (json['temperature_min_c'] as num?)?.toDouble(),
      temperatureMaxC: (json['temperature_max_c'] as num?)?.toDouble(),
      soilType: json['soil_type']?.toString(),
      pruningFrequency: json['pruning_frequency']?.toString(),
      repottingFrequency: json['repotting_frequency']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Log
// ---------------------------------------------------------------------------

class ActivityLog {
  final int id;
  final String activityType;
  final String loggedDate;
  final String? notes;
  final String? photoUrl;

  ActivityLog({
    required this.id,
    required this.activityType,
    required this.loggedDate,
    this.notes,
    this.photoUrl,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] ?? 0,
      activityType: json['activity_type'] ?? '',
      loggedDate: json['logged_date'] ?? '',
      notes: json['notes'],
      photoUrl: json['photo_url'],
    );
  }

  String get emoji {
    switch (activityType) {
      case 'watered': return '💧';
      case 'fertilized': return '🌱';
      case 'repotted': return '🪴';
      case 'photo_node': return '📸';
      case 'milestone': return '🎯';
      default: return '📋';
    }
  }
}

// ---------------------------------------------------------------------------
// Growth Metric
// ---------------------------------------------------------------------------

class GrowthMetric {
  final int id;
  final double heightCm;
  final String growthRateStatus;
  final String recordedDate;

  GrowthMetric({
    required this.id,
    required this.heightCm,
    required this.growthRateStatus,
    required this.recordedDate,
  });

  factory GrowthMetric.fromJson(Map<String, dynamic> json) {
    return GrowthMetric(
      id: json['id'] ?? 0,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 0,
      growthRateStatus: json['growth_rate_status'] ?? 'moderate',
      recordedDate: json['recorded_date'] ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Scan
// ---------------------------------------------------------------------------

class Scan {
  final int id;
  final String? capturedImageUrl;
  final double? confidenceScore;
  final Map<String, dynamic>? identificationPayload;
  final bool? retake;
  final int? plantId;
  final List<dynamic>? selectedSymptoms;
  final DateTime? createdAt;

  Scan({
    required this.id,
    this.capturedImageUrl,
    this.confidenceScore,
    this.identificationPayload,
    this.retake,
    this.plantId,
    this.selectedSymptoms,
    this.createdAt,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      id: json['id'] ?? 0,
      capturedImageUrl: json['captured_image_url']?.toString(),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      identificationPayload: json['json_identification_payload'] is Map
          ? json['json_identification_payload'] as Map<String, dynamic>
          : null,
      retake: json['retake'] as bool?,
      plantId: json['plant_id'],
      selectedSymptoms: json['selectedSymptoms'] as List<dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  String? get commonName {
    if (identificationPayload == null) return null;
    for (final key in ['common_name', 'commonName', 'name']) {
      if (identificationPayload!.containsKey(key)) {
        return identificationPayload![key]?.toString();
      }
    }
    return null;
  }

  String? get scientificName {
    if (identificationPayload == null) return null;
    for (final key in ['scientific_name', 'scientificName']) {
      if (identificationPayload!.containsKey(key)) {
        return identificationPayload![key]?.toString();
      }
    }
    return null;
  }

  String? get description {
    if (identificationPayload == null) return null;
    for (final key in ['description', 'summary', 'details']) {
      if (identificationPayload!.containsKey(key)) {
        return identificationPayload![key]?.toString();
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Community Post
// ---------------------------------------------------------------------------

class CommunityPost {
  final int id;
  final String authorName;
  final String authorInitials;
  final String category;
  final String text;
  final String? emoji;
  final String time;
  final int likes;
  final int comments;
  final bool likedByMe;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.category,
    required this.text,
    this.emoji,
    required this.time,
    required this.likes,
    required this.comments,
    required this.likedByMe,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? 0,
      authorName: json['author_name'] ?? '',
      authorInitials: json['author_initials'] ?? '?',
      category: json['category'] ?? 'all',
      text: json['text'] ?? '',
      emoji: json['emoji']?.toString(),
      time: json['time'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      likedByMe: json['liked_by_me'] ?? false,
    );
  }
}
