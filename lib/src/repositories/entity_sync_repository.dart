import '../api/api_client.dart';
import '../auth/auth_session.dart';
import '../db/entity_dao.dart';
import '../models/entities.dart';

class EntitySyncRepository {
  EntitySyncRepository({required ApiClient api, required EntityDao dao})
    : _api = api,
      _dao = dao;

  final ApiClient _api;
  final EntityDao _dao;

  Future<void> refreshPrograms(AuthSession session) async {
    final items = await _fetchAllPages(
      session,
      path: '/attendance/programs',
      sort: 'name',
    );
    await _dao.upsertPrograms(items);
  }

  Future<void> refreshActivities(AuthSession session) async {
    final items = await _fetchAllPages(
      session,
      path: '/attendance/activities',
      sort: 'name',
    );
    await _dao.upsertActivities(items);
  }

  Future<void> refreshActivitySchedules(AuthSession session) async {
    final items = await _fetchAllPages(
      session,
      path: '/attendance/activity-schedules',
      sort: 'startDate',
    );

    final programs = <Map<String, dynamic>>[];
    final activities = <Map<String, dynamic>>[];
    for (final item in items) {
      final program = item['program'];
      if (program is Map<String, dynamic>) programs.add(program);
      final activity = item['activity'];
      if (activity is Map<String, dynamic>) activities.add(activity);
    }

    if (programs.isNotEmpty) {
      await _dao.upsertPrograms(programs);
    }
    if (activities.isNotEmpty) {
      await _dao.upsertActivities(activities);
    }
    await _dao.upsertActivitySchedules(items);
  }

  Future<List<ActivitySchedule>> fetchActivitySchedulesFromHost(
    AuthSession session, {
    String? programId,
    String? activityId,
    int size = 50,
  }) async {
    final query = <String, String>{'page': '0', 'size': size.toString()};
    final p = (programId ?? '').trim();
    if (p.isNotEmpty) query['programId'] = p;
    final a = (activityId ?? '').trim();
    if (a.isNotEmpty) query['activityId'] = a;

    final json = await _api.getJson(
      session,
      path: '/attendance/activity-schedules',
      queryParameters: query,
    );

    final content = json['content'];
    final items = <Map<String, dynamic>>[];
    if (content is List) {
      for (final item in content) {
        if (item is Map<String, dynamic>) items.add(item);
      }
    }

    final programs = <Map<String, dynamic>>[];
    final activities = <Map<String, dynamic>>[];
    for (final item in items) {
      final program = item['program'];
      if (program is Map<String, dynamic>) programs.add(program);
      final activity = item['activity'];
      if (activity is Map<String, dynamic>) activities.add(activity);
    }

    if (programs.isNotEmpty) {
      await _dao.upsertPrograms(programs);
    }
    if (activities.isNotEmpty) {
      await _dao.upsertActivities(activities);
    }
    await _dao.upsertActivitySchedules(items);

    final all = await _dao.listActivitySchedules();
    return all
        .where((s) {
          if (p.isNotEmpty && s.programId != p) return false;
          if (a.isNotEmpty && s.activityId != a) return false;
          return true;
        })
        .toList(growable: false);
  }

  Future<void> refreshYearLevels(AuthSession session) async {
    final items = await _fetchAllPages(
      session,
      path: '/attendance/year-levels',
      sort: 'name',
    );
    await _dao.upsertYearLevels(items);
  }

  Future<void> refreshSections(AuthSession session) async {
    final items = await _fetchAllPages(
      session,
      path: '/attendance/sections',
      sort: 'name',
    );
    await _dao.upsertSections(items);
  }

  Future<void> refreshAttendees(AuthSession session) async {
    final items = await _fetchAllPages(
      session,
      path: '/attendance/attendees',
      sort: 'lastName',
    );
    await _dao.upsertAttendees(items);
  }

  Future<List<Program>> listPrograms() => _dao.listPrograms();
  Future<List<Activity>> listActivities() => _dao.listActivities();
  Future<List<ActivitySchedule>> listActivitySchedules() =>
      _dao.listActivitySchedules();
  Future<List<YearLevel>> listYearLevels() => _dao.listYearLevels();
  Future<List<Section>> listSections() => _dao.listSections();
  Future<List<Attendee>> listAttendees() => _dao.listAttendees();

  Future<Attendee?> getAttendeeByCode(String code) =>
      _dao.getAttendeeByCode(code);

  Future<List<Map<String, dynamic>>> _fetchAllPages(
    AuthSession session, {
    required String path,
    required String sort,
  }) async {
    const size = 50;

    final all = <Map<String, dynamic>>[];
    var page = 0;
    var last = false;

    while (!last) {
      final json = await _api.getJson(
        session,
        path: path,
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          'sort': sort,
          'dir': 'ASC',
        },
      );

      final content = json['content'];
      if (content is List) {
        for (final item in content) {
          if (item is Map<String, dynamic>) all.add(item);
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
}
