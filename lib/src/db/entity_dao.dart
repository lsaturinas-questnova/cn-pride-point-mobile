import 'package:sqflite/sqflite.dart';

import '../models/entities.dart';
import 'app_database.dart';

class EntityDao {
  EntityDao(this._db);

  final AppDatabase _db;

  Future<void> upsertPrograms(List<Map<String, dynamic>> items) async {
    final batch = _db.raw.batch();
    for (final item in items) {
      final id = item['id'];
      final name = item['name'];
      if (id is! String || name is! String) continue;
      batch.insert('programs', {
        'id': id,
        'name': name,
        'type': item['type']?.toString(),
        'startDate': item['startDate']?.toString(),
        'endDate': item['endDate']?.toString(),
        'status': item['status']?.toString(),
        'rawJson': AppDatabase.encodeRawJson(item),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertActivities(List<Map<String, dynamic>> items) async {
    final batch = _db.raw.batch();
    for (final item in items) {
      final id = item['id'];
      final name = item['name'];
      if (id is! String || name is! String) continue;
      batch.insert('activities', {
        'id': id,
        'name': name,
        'activityType': item['activityType']?.toString(),
        'startDate': item['startDate']?.toString(),
        'endDate': item['endDate']?.toString(),
        'status': item['status']?.toString(),
        'rawJson': AppDatabase.encodeRawJson(item),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertYearLevels(List<Map<String, dynamic>> items) async {
    final batch = _db.raw.batch();
    for (final item in items) {
      final id = item['id'];
      final name = item['name'];
      if (id is! String || name is! String) continue;
      batch.insert('year_levels', {
        'id': id,
        'name': name,
        'status': item['status']?.toString(),
        'rawJson': AppDatabase.encodeRawJson(item),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertSections(List<Map<String, dynamic>> items) async {
    final batch = _db.raw.batch();
    for (final item in items) {
      final id = item['id'];
      final name = item['name'];
      if (id is! String || name is! String) continue;
      batch.insert('sections', {
        'id': id,
        'name': name,
        'status': item['status']?.toString(),
        'rawJson': AppDatabase.encodeRawJson(item),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertAttendees(List<Map<String, dynamic>> items) async {
    final batch = _db.raw.batch();
    for (final item in items) {
      final id = item['id'];
      if (id is! String) continue;
      final yearLevel = item['yearLevel'];
      final section = item['section'];
      final profilePic = item['profilePic'];

      batch.insert('attendees', {
        'id': id,
        'code': item['code']?.toString(),
        'lastName': item['lastName']?.toString(),
        'firstName': item['firstName']?.toString(),
        'middleName': item['middleName']?.toString(),
        'displayName': item['displayName']?.toString(),
        'yearLevelId': (yearLevel is Map ? yearLevel['id'] : null)?.toString(),
        'sectionId': (section is Map ? section['id'] : null)?.toString(),
        'profilePicJson': profilePic == null
            ? null
            : AppDatabase.encodeRawJson(profilePic),
        'status': item['status']?.toString(),
        'rawJson': AppDatabase.encodeRawJson(item),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Program>> listPrograms() async {
    final rows = await _db.raw.query('programs', orderBy: 'name ASC');
    return rows
        .map(
          (r) => Program(
            id: r['id'] as String,
            name: r['name'] as String,
            type: r['type'] as String?,
            startDate: r['startDate'] as String?,
            endDate: r['endDate'] as String?,
            status: r['status'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<Activity>> listActivities() async {
    final rows = await _db.raw.query('activities', orderBy: 'name ASC');
    return rows
        .map(
          (r) => Activity(
            id: r['id'] as String,
            name: r['name'] as String,
            activityType: r['activityType'] as String?,
            startDate: r['startDate'] as String?,
            endDate: r['endDate'] as String?,
            status: r['status'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<YearLevel>> listYearLevels() async {
    final rows = await _db.raw.query('year_levels', orderBy: 'name ASC');
    return rows
        .map(
          (r) => YearLevel(
            id: r['id'] as String,
            name: r['name'] as String,
            status: r['status'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<Section>> listSections() async {
    final rows = await _db.raw.query('sections', orderBy: 'name ASC');
    return rows
        .map(
          (r) => Section(
            id: r['id'] as String,
            name: r['name'] as String,
            status: r['status'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<Attendee>> listAttendees() async {
    final rows = await _db.raw.query(
      'attendees',
      orderBy: 'lastName ASC, firstName ASC',
    );
    return rows
        .map(
          (r) => Attendee(
            id: r['id'] as String,
            code: r['code'] as String?,
            lastName: r['lastName'] as String?,
            firstName: r['firstName'] as String?,
            middleName: r['middleName'] as String?,
            displayName: r['displayName'] as String?,
            yearLevelId: r['yearLevelId'] as String?,
            sectionId: r['sectionId'] as String?,
            profilePicJson: r['profilePicJson'] as String?,
            status: r['status'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<Attendee?> getAttendeeByCode(String code) async {
    final rows = await _db.raw.query(
      'attendees',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Attendee(
      id: r['id'] as String,
      code: r['code'] as String?,
      lastName: r['lastName'] as String?,
      firstName: r['firstName'] as String?,
      middleName: r['middleName'] as String?,
      displayName: r['displayName'] as String?,
      yearLevelId: r['yearLevelId'] as String?,
      sectionId: r['sectionId'] as String?,
      profilePicJson: r['profilePicJson'] as String?,
      status: r['status'] as String?,
    );
  }

  Future<int> insertOfflineAttendance({
    required String programId,
    required String activityId,
    required String attendeeId,
    required String mobileReference,
    required DateTime checkedInAt,
    required String status,
    String? notes,
  }) async {
    return _db.raw.insert('activity_attendance_queue', {
      'remoteId': null,
      'mobileReference': mobileReference,
      'programId': programId,
      'activityId': activityId,
      'attendeeId': attendeeId,
      'checkedInAt': checkedInAt.toIso8601String(),
      'checkedOutAt': null,
      'status': status,
      'notes': notes,
      'syncStatus': SyncStatus.pending.name,
      'lastSyncError': null,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<OfflineAttendance>> listPendingOfflineAttendance() async {
    final rows = await _db.raw.query(
      'activity_attendance_queue',
      where: 'syncStatus = ?',
      whereArgs: [SyncStatus.pending.name],
      orderBy: 'checkedInAt DESC',
    );

    return rows
        .map(
          (r) => OfflineAttendance(
            localId: r['localId'] as int,
            remoteId: r['remoteId'] as String?,
            programId: r['programId'] as String,
            activityId: r['activityId'] as String,
            attendeeId: r['attendeeId'] as String,
            mobileReference: (r['mobileReference'] as String?) ?? '',
            checkedInAt: DateTime.parse(r['checkedInAt'] as String),
            checkedOutAt: (r['checkedOutAt'] as String?) == null
                ? null
                : DateTime.parse(r['checkedOutAt'] as String),
            status: r['status'] as String,
            notes: r['notes'] as String?,
            syncStatus: SyncStatus.pending,
            lastSyncError: r['lastSyncError'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<List<OfflineAttendance>> listOfflineAttendanceNotSynced() async {
    final rows = await _db.raw.query(
      'activity_attendance_queue',
      where: 'syncStatus != ?',
      whereArgs: [SyncStatus.synced.name],
      orderBy: 'checkedInAt DESC',
    );

    return rows
        .map(
          (r) => OfflineAttendance(
            localId: r['localId'] as int,
            remoteId: r['remoteId'] as String?,
            programId: r['programId'] as String,
            activityId: r['activityId'] as String,
            attendeeId: r['attendeeId'] as String,
            mobileReference: (r['mobileReference'] as String?) ?? '',
            checkedInAt: DateTime.parse(r['checkedInAt'] as String),
            checkedOutAt: (r['checkedOutAt'] as String?) == null
                ? null
                : DateTime.parse(r['checkedOutAt'] as String),
            status: r['status'] as String,
            notes: r['notes'] as String?,
            syncStatus: _syncStatusFromDb(r['syncStatus'] as String?),
            lastSyncError: r['lastSyncError'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<void> markOfflineAttendanceSynced({
    required List<int> localIds,
    Map<int, String?>? remoteIdsByLocalId,
  }) async {
    if (localIds.isEmpty) return;
    final batch = _db.raw.batch();
    for (final id in localIds) {
      batch.update(
        'activity_attendance_queue',
        {
          'syncStatus': SyncStatus.synced.name,
          'lastSyncError': null,
          if (remoteIdsByLocalId != null) 'remoteId': remoteIdsByLocalId[id],
        },
        where: 'localId = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> markOfflineAttendanceError({
    required int localId,
    required String lastSyncError,
  }) async {
    await _db.raw.update(
      'activity_attendance_queue',
      {
        'syncStatus': SyncStatus.error.name,
        'lastSyncError': lastSyncError,
      },
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  Future<void> updateOfflineAttendanceNotes({
    required int localId,
    required String? notes,
  }) async {
    await _db.raw.update(
      'activity_attendance_queue',
      {'notes': notes},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  Future<void> deleteOfflineAttendance({required int localId}) async {
    await _db.raw.delete(
      'activity_attendance_queue',
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }
}

SyncStatus _syncStatusFromDb(String? raw) {
  return switch (raw) {
    'pending' => SyncStatus.pending,
    'synced' => SyncStatus.synced,
    'error' => SyncStatus.error,
    _ => SyncStatus.pending,
  };
}
