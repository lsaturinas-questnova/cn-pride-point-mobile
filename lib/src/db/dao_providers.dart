import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entity_dao.dart';
import 'providers.dart';

final entityDaoProvider = FutureProvider<EntityDao>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return EntityDao(db);
});
