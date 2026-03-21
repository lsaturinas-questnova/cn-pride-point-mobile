import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
