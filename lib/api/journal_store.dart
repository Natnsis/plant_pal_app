import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A plant-care note the user wrote on-device. It lives here until the user
/// taps "Sync to cloud", which pushes it to `POST /journal` and flips
/// [synced]. Unsynced notes are still shown in the Journal tab so nothing is
/// lost if the user is offline or hasn't synced yet.
class LocalNote {
  LocalNote({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.text,
    required this.createdAt,
    this.synced = false,
    this.remoteId,
  });

  final String id;
  final int plantId;
  final String plantName;
  final String text;
  final DateTime createdAt;
  bool synced;
  int? remoteId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'plant_id': plantId,
        'plant_name': plantName,
        'text': text,
        'created_at': createdAt.toIso8601String(),
        'synced': synced,
        'remote_id': remoteId,
      };

  factory LocalNote.fromJson(Map<String, dynamic> j) => LocalNote(
        id: (j['id'] ?? '').toString(),
        plantId: (j['plant_id'] as num?)?.toInt() ?? 0,
        plantName: (j['plant_name'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        createdAt:
            DateTime.tryParse((j['created_at'] ?? '').toString()) ?? DateTime.now(),
        synced: j['synced'] == true,
        remoteId: (j['remote_id'] as num?)?.toInt(),
      );
}

/// File-backed store for [LocalNote]s, mirroring `TokenStore`'s plain-JSON-file
/// approach (no `shared_preferences` on this Flutter SDK).
class JournalStore {
  JournalStore._();
  static final JournalStore instance = JournalStore._();

  static const _fileName = 'pp_journal_notes.json';

  List<LocalNote>? _cache;
  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    Directory dir;
    try {
      dir = await getApplicationSupportDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  Future<List<LocalNote>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _file();
      if (!f.existsSync()) return _cache = [];
      final raw = jsonDecode(await f.readAsString());
      if (raw is List) {
        return _cache = raw
            .whereType<Map>()
            .map((e) => LocalNote.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {}
    return _cache = [];
  }

  Future<void> _persist() async {
    try {
      final f = await _file();
      await f.writeAsString(
        jsonEncode((_cache ?? []).map((n) => n.toJson()).toList()),
        flush: true,
      );
    } catch (_) {}
  }

  /// All notes, newest first.
  Future<List<LocalNote>> all() async {
    final list = await _load();
    final copy = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  Future<List<LocalNote>> forPlant(int plantId) async =>
      (await all()).where((n) => n.plantId == plantId).toList();

  Future<LocalNote> add({
    required int plantId,
    required String plantName,
    required String text,
  }) async {
    final list = await _load();
    final note = LocalNote(
      id: 'n${DateTime.now().microsecondsSinceEpoch}',
      plantId: plantId,
      plantName: plantName,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    list.insert(0, note);
    await _persist();
    return note;
  }

  Future<void> markSynced(String id, {int? remoteId}) async {
    final list = await _load();
    for (final n in list) {
      if (n.id == id) {
        n.synced = true;
        n.remoteId = remoteId;
      }
    }
    await _persist();
  }

  Future<void> delete(String id) async {
    final list = await _load();
    list.removeWhere((n) => n.id == id);
    await _persist();
  }

  int unsyncedCount(List<LocalNote> notes) =>
      notes.where((n) => !n.synced).length;
}
