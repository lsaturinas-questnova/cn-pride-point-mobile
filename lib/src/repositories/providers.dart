import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/providers.dart';
import '../db/dao_providers.dart';
import 'entity_sync_repository.dart';
import 'offline_attendance_repository.dart';

final entitySyncRepositoryProvider = FutureProvider<EntitySyncRepository>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  final dao = await ref.watch(entityDaoProvider.future);
  return EntitySyncRepository(api: api, dao: dao);
});

final offlineAttendanceRepositoryProvider =
    FutureProvider<OfflineAttendanceRepository>((ref) async {
      final api = ref.watch(apiClientProvider);
      final dao = await ref.watch(entityDaoProvider.future);
      return OfflineAttendanceRepository(api: api, dao: dao);
    });
