/// Helpers for the PlantPal API, whose JSON mixes GORM's PascalCase
/// (`ID`, `CreatedAt`, `Plants`) with hand-rolled snake_case fields.
library;

Map<String, dynamic> asMap(Object? v) =>
    v is Map ? v.map((k, val) => MapEntry(k.toString(), val)) : <String, dynamic>{};

List<dynamic> asList(Object? v) => v is List ? v : const [];

/// First non-null value among [keys].
Object? pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

int asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double asDouble(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool asBool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return fallback;
}

String asString(Object? v, [String fallback = '']) => v?.toString() ?? fallback;

/// Parses the several timestamp spellings the API returns; `null` for
/// Go's zero time (`0001-01-01T…`) or blank.
DateTime? asDate(Object? v) {
  final s = v?.toString();
  if (s == null || s.isEmpty || s.startsWith('0001-01-01')) return null;
  return DateTime.tryParse(s)?.toLocal();
}

int idOf(Map<String, dynamic> json) =>
    asInt(pick(json, ['id', 'ID', 'Id']));

DateTime? createdAtOf(Map<String, dynamic> json) =>
    asDate(pick(json, ['created_at', 'createdAt', 'CreatedAt']));

DateTime? updatedAtOf(Map<String, dynamic> json) =>
    asDate(pick(json, ['updated_at', 'updatedAt', 'UpdatedAt']));
