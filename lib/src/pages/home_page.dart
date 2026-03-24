import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../ui/cn_app_bar.dart';
import 'activity_attendance_entry_page.dart';
import 'entity_list_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(sessionNoticeProvider);

    return Scaffold(
      appBar: cnAppBar(
        context: context,
        onLogout: () => ref.read(authSessionProvider.notifier).logout(),
      ),
      body: ListView(
        children: [
          if (notice != null && notice.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: MaterialBanner(
                content: Text(notice),
                actions: [
                  TextButton(
                    onPressed: () => ref.read(sessionNoticeProvider.notifier).state = null,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ListTile(
            title: const Text('Programs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const EntityListPage(entity: EntityType.programs),
              ),
            ),
          ),
          ListTile(
            title: const Text('Activities'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const EntityListPage(entity: EntityType.activities),
              ),
            ),
          ),
          ListTile(
            title: const Text('Activity Attendance List'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ActivityAttendanceEntryPage(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Attendees'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const EntityListPage(entity: EntityType.attendees),
              ),
            ),
          ),
          ListTile(
            title: const Text('Sections'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const EntityListPage(entity: EntityType.sections),
              ),
            ),
          ),
          ListTile(
            title: const Text('Year levels'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const EntityListPage(entity: EntityType.yearLevels),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
