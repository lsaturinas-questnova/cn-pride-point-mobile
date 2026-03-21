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
