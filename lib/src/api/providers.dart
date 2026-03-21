import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ref.watch(httpClientProvider);
  return ApiClient(client);
});
