import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase(this._db);

  final Database _db;

  static const schemaVersion = 3;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'cn_pride_point.db');

    final db = await openDatabase(
      path,
      version: schemaVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE activity_attendance_queue ADD COLUMN mobileReference TEXT',
          );
          await db.execute(
            "UPDATE activity_attendance_queue SET mobileReference = 'legacy-' || localId "
            "WHERE mobileReference IS NULL OR mobileReference = ''",
          );
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS activity_attendance_mobile_ref_idx '
            'ON activity_attendance_queue(mobileReference)',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'CREATE TABLE activity_schedules('
            'id TEXT PRIMARY KEY,'
            'programId TEXT NOT NULL,'
            'activityId TEXT NOT NULL,'
            'startDate TEXT,'
            'endDate TEXT,'
            'status TEXT,'
            'notes TEXT,'
            'rawJson TEXT'
            ')',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS activity_schedules_program_idx '
            'ON activity_schedules(programId)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS activity_schedules_activity_idx '
            'ON activity_schedules(activityId)',
          );
        }
      },
    );

    return AppDatabase(db);
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute(
      'CREATE TABLE programs('
      'id TEXT PRIMARY KEY,'
      'name TEXT NOT NULL,'
      'type TEXT,'
      'startDate TEXT,'
      'endDate TEXT,'
      'status TEXT,'
      'rawJson TEXT'
      ')',
    );

    await db.execute(
      'CREATE TABLE activities('
      'id TEXT PRIMARY KEY,'
      'name TEXT NOT NULL,'
      'activityType TEXT,'
      'startDate TEXT,'
      'endDate TEXT,'
      'status TEXT,'
      'rawJson TEXT'
      ')',
    );

    await db.execute(
      'CREATE TABLE activity_schedules('
      'id TEXT PRIMARY KEY,'
      'programId TEXT NOT NULL,'
      'activityId TEXT NOT NULL,'
      'startDate TEXT,'
      'endDate TEXT,'
      'status TEXT,'
      'notes TEXT,'
      'rawJson TEXT'
      ')',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS activity_schedules_program_idx '
      'ON activity_schedules(programId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS activity_schedules_activity_idx '
      'ON activity_schedules(activityId)',
    );

    await db.execute(
      'CREATE TABLE year_levels('
      'id TEXT PRIMARY KEY,'
      'name TEXT NOT NULL,'
      'status TEXT,'
      'rawJson TEXT'
      ')',
    );

    await db.execute(
      'CREATE TABLE sections('
      'id TEXT PRIMARY KEY,'
      'name TEXT NOT NULL,'
      'status TEXT,'
      'rawJson TEXT'
      ')',
    );

    await db.execute(
      'CREATE TABLE attendees('
      'id TEXT PRIMARY KEY,'
      'code TEXT,'
      'lastName TEXT,'
      'firstName TEXT,'
      'middleName TEXT,'
      'displayName TEXT,'
      'yearLevelId TEXT,'
      'sectionId TEXT,'
      'profilePicJson TEXT,'
      'status TEXT,'
      'rawJson TEXT'
      ')',
    );

    await db.execute('CREATE INDEX attendees_code_idx ON attendees(code)');

    await db.execute(
      'CREATE TABLE activity_attendance_queue('
      'localId INTEGER PRIMARY KEY AUTOINCREMENT,'
      'remoteId TEXT,'
      'mobileReference TEXT NOT NULL,'
      'programId TEXT NOT NULL,'
      'activityId TEXT NOT NULL,'
      'attendeeId TEXT NOT NULL,'
      'checkedInAt TEXT NOT NULL,'
      'checkedOutAt TEXT,'
      'status TEXT NOT NULL,'
      'notes TEXT,'
      'syncStatus TEXT NOT NULL,'
      'lastSyncError TEXT'
      ')',
    );

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS activity_attendance_mobile_ref_idx '
      'ON activity_attendance_queue(mobileReference)',
    );
  }

  Database get raw => _db;

  Future<void> close() => _db.close();

  static String encodeRawJson(Object? jsonObject) {
    if (jsonObject == null) return '';
    return jsonEncode(jsonObject);
  }
}
