import '../api/api_client.dart';
import '../auth/auth_session.dart';
import '../db/entity_dao.dart';
import '../models/activity_attendance.dart';
import '../models/entities.dart';

class LocalAttendanceViewItem {
  const LocalAttendanceViewItem({
    required this.attendance,
    required this.programName,
    required this.activityName,
    required this.attendeeDisplayName,
  });

  final OfflineAttendance attendance;
  final String? programName;
  final String? activityName;
  final String? attendeeDisplayName;
}

class OfflineAttendanceRepository {
  OfflineAttendanceRepository({required ApiClient api, required EntityDao dao})
    : _api = api,
      _dao = dao;

  final ApiClient _api;
  final EntityDao _dao;

  Future<List<ActivityAttendanceListItem>> listFromHost({
    required AuthSession session,
    required String activityScheduleId,
  }) async {
    const size = 50;
    final all = <ActivityAttendanceListItem>[];
    var page = 0;
    var last = false;

    while (!last) {
      final query = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
        'sort': 'attendee',
        'dir': 'ASC',
        'activityScheduleId': activityScheduleId,
      };

      final json = await _api.getJson(
        session,
        path: '/attendance/activity-attendance-list',
        queryParameters: query,
      );

      final content = json['content'];
      if (content is List) {
        for (final item in content) {
          if (item is! Map<String, dynamic>) continue;
          final id = item['id']?.toString() ?? '';
          final schedule =
              item['activitySchedule'] ??
              item['activity_schedule'] ??
              item['schedule'];
          final program =
              (schedule is Map ? schedule['program'] : null) ?? item['program'];
          final activity =
              (schedule is Map ? schedule['activity'] : null) ??
              item['activity'];
          final attendee = item['attendee'];
          all.add(
            ActivityAttendanceListItem(
              id: id,
              activityScheduleId: (schedule is Map ? schedule['id'] : null)
                  ?.toString(),
              programName: (program is Map ? program['name'] : null)
                  ?.toString(),
              activityName: (activity is Map ? activity['name'] : null)
                  ?.toString(),
              attendeeDisplayName:
                  (attendee is Map ? attendee['displayName'] : null)
                      ?.toString(),
              status: item['status']?.toString(),
              checkedInAt: item['checkedInAt']?.toString(),
            ),
          );
        }
      }

      final isLast = json['last'];
      if (isLast is bool) {
        last = isLast;
      } else {
        final totalPages = json['totalPages'];
        if (totalPages is num) {
          last = (page + 1) >= totalPages.toInt();
        } else {
          last = true;
        }
      }

      page += 1;
      if (page > 1000) {
        throw const ApiException(statusCode: 500, body: 'Too many pages');
      }
    }

    return all;
  }

  Future<int> createPendingAttendanceFromScan({
    required String activityScheduleId,
    required String scannedCode,
    required String username,
  }) async {
    final trimmed = scannedCode.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Invalid barcode');
    }
    final attendee = await _dao.getAttendeeByCode(trimmed);
    if (attendee == null) {
      throw const AttendeeNotFoundException();
    }

    final mobileReference = buildMobileReference(
      username: username,
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
    );

    return _dao.insertOfflineAttendance(
      activityScheduleId: activityScheduleId,
      attendeeId: attendee.id,
      mobileReference: mobileReference,
      checkedInAt: DateTime.now(),
      status: 'PRESENT',
    );
  }

  Future<List<OfflineAttendance>> listPending() =>
      _dao.listPendingOfflineAttendance();

  Future<List<OfflineAttendance>> listNotSynced() =>
      _dao.listOfflineAttendanceNotSynced();

  Future<int> pendingCount() async => (await listPending()).length;

  Future<void> updateNotes({
    required int localId,
    required String? notes,
  }) async {
    await _dao.updateOfflineAttendanceNotes(localId: localId, notes: notes);
  }

  Future<void> delete({required int localId}) async {
    await _dao.deleteOfflineAttendance(localId: localId);
  }

  Future<void> resend({required int localId}) async {
    await _dao.markOfflineAttendancePending(localId: localId);
  }

  Future<List<LocalAttendanceViewItem>> listNotSyncedViewItems() async {
    final list = await _dao.listOfflineAttendanceNotSynced();
    if (list.isEmpty) return const [];

    final schedules = await _dao.listActivitySchedules();
    final programs = await _dao.listPrograms();
    final activities = await _dao.listActivities();
    final attendees = await _dao.listAttendees();

    final scheduleById = {for (final s in schedules) s.id: s};
    final programNameById = {for (final p in programs) p.id: p.name};
    final activityNameById = {for (final a in activities) a.id: a.name};
    final attendeeNameById = {
      for (final a in attendees)
        a.id:
            (a.displayName ?? '${a.lastName ?? ''} ${a.firstName ?? ''}'.trim())
                .trim(),
    };

    return list
        .map(
          (a) => LocalAttendanceViewItem(
            attendance: a,
            programName: () {
              final s = scheduleById[a.activityScheduleId];
              if (s == null) return null;
              return programNameById[s.programId];
            }(),
            activityName: () {
              final s = scheduleById[a.activityScheduleId];
              if (s == null) return null;
              return activityNameById[s.activityId];
            }(),
            attendeeDisplayName: attendeeNameById[a.attendeeId],
          ),
        )
        .toList(growable: false);
  }

  Future<SyncResult> syncPending(AuthSession session) async {
    final pending = await _dao.listPendingOfflineAttendance();
    if (pending.isEmpty) return const SyncResult(hasErrors: false, updated: 0);

    final invalid = pending
        .where((p) => p.activityScheduleId.trim().isEmpty)
        .toList(growable: false);
    if (invalid.isNotEmpty) {
      for (final p in invalid) {
        await _dao.markOfflineAttendanceError(
          localId: p.localId,
          lastSyncError: 'Missing activityScheduleId',
        );
      }
      final next = await _dao.listPendingOfflineAttendance();
      if (next.isEmpty) return const SyncResult(hasErrors: true, updated: 0);
      return syncPending(session);
    }

    final payload = pending
        .map(
          (p) => {
            'id': null,
            'activitySchedule': {'id': p.activityScheduleId},
            'checkedInAt': p.checkedInAt.toIso8601String(),
            'checkedOutAt': p.checkedOutAt?.toIso8601String(),
            'attendee': {'id': p.attendeeId},
            'status': p.status,
            'notes': p.notes,
            'mobileReference': p.mobileReference,
          },
        )
        .toList(growable: false);

    final response = await _api.postJson(
      session,
      path: '/attendance/sync',
      body: payload,
    );

    if (response is! Map) {
      throw const ApiException(statusCode: 200, body: 'Invalid sync response');
    }

    final resolution = resolveSyncResponse(
      pending: pending,
      response: response,
    );

    for (final e in resolution.errorByLocalId.entries) {
      await _dao.markOfflineAttendanceError(
        localId: e.key,
        lastSyncError: e.value,
      );
    }

    if (resolution.remoteIdByLocalId.isNotEmpty) {
      await _dao.markOfflineAttendanceSynced(
        localIds: resolution.remoteIdByLocalId.keys.toList(growable: false),
        remoteIdsByLocalId: resolution.remoteIdByLocalId,
      );
    }

    return SyncResult(
      hasErrors: resolution.hasErrors,
      updated: resolution.updated,
    );
  }
}

class SyncResult {
  const SyncResult({required this.hasErrors, required this.updated});

  final bool hasErrors;
  final int updated;
}

class AttendeeNotFoundException implements Exception {
  const AttendeeNotFoundException();
}

String buildMobileReference({
  required String username,
  required int timestampMillis,
}) {
  final u = username.trim().isEmpty ? 'unknown' : username.trim();
  return '$u-$timestampMillis';
}

SyncResolution resolveSyncResponse({
  required List<OfflineAttendance> pending,
  required Map response,
}) {
  final hasErrors = response['errors'] == true;
  final list = response['attendanceList'];
  if (list is! List) {
    throw const ApiException(statusCode: 200, body: 'Missing attendanceList');
  }

  final pendingByMobileRef = <String, OfflineAttendance>{
    for (final p in pending) p.mobileReference: p,
  };

  final remoteIdByLocalId = <int, String?>{};
  final errorByLocalId = <int, String>{};
  var updated = 0;

  for (final item in list) {
    if (item is! Map) continue;
    final mobileReference = item['mobileReference']?.toString() ?? '';
    if (mobileReference.isEmpty) continue;

    final local = pendingByMobileRef[mobileReference];
    if (local == null) continue;

    final id = item['id']?.toString() ?? '';
    final notes = item['notes']?.toString();
    if (id.trim().isNotEmpty) {
      remoteIdByLocalId[local.localId] = id;
      updated += 1;
      continue;
    }

    errorByLocalId[local.localId] = (notes == null || notes.trim().isEmpty)
        ? 'Missing id in sync response'
        : notes;
    updated += 1;
  }

  return SyncResolution(
    hasErrors: hasErrors,
    updated: updated,
    remoteIdByLocalId: remoteIdByLocalId,
    errorByLocalId: errorByLocalId,
  );
}

class SyncResolution {
  const SyncResolution({
    required this.hasErrors,
    required this.updated,
    required this.remoteIdByLocalId,
    required this.errorByLocalId,
  });

  final bool hasErrors;
  final int updated;
  final Map<int, String?> remoteIdByLocalId;
  final Map<int, String> errorByLocalId;
}
