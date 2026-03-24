import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../models/entities.dart';
import '../repositories/providers.dart';
import '../ui/cn_app_bar.dart';
import 'activity_attendance_page.dart';

class ActivityAttendanceEntryPage extends ConsumerStatefulWidget {
  const ActivityAttendanceEntryPage({super.key});

  @override
  ConsumerState<ActivityAttendanceEntryPage> createState() =>
      _ActivityAttendanceEntryPageState();
}

class _ActivityAttendanceEntryPageState
    extends ConsumerState<ActivityAttendanceEntryPage> {
  String? _programId;
  String? _activityId;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(entitySyncRepositoryProvider);

    return Scaffold(
      appBar: cnAppBar(
        context: context,
        onLogout: () => ref.read(authSessionProvider.notifier).logout(),
      ),
      body: SafeArea(
        child: repo.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (repo) {
            return FutureBuilder(
              future: Future.wait([repo.listPrograms(), repo.listActivities()]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final programs = snapshot.data![0] as List<Program>;
                final activities = snapshot.data![1] as List<Activity>;

                final activePrograms = programs
                    .where((p) => (p.status ?? '').toUpperCase() == 'ACTIVE')
                    .toList(growable: false);
                final activeActivities = activities
                    .where((a) => (a.status ?? '').toUpperCase() == 'ACTIVE')
                    .toList(growable: false);

                if (_programId != null &&
                    activePrograms.every((p) => p.id != _programId)) {
                  _programId = null;
                }
                if (_activityId != null &&
                    activeActivities.every((a) => a.id != _activityId)) {
                  _activityId = null;
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _programId,
                        items: activePrograms
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (v) => setState(() => _programId = v),
                        decoration: const InputDecoration(
                          labelText: 'Program (required)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _activityId,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...activeActivities.map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                a.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _activityId = v),
                        decoration: const InputDecoration(
                          labelText: 'Activity (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: (_programId ?? '').isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ActivityAttendancePage(
                                      initialProgramId: _programId!,
                                      initialActivityId: _activityId,
                                    ),
                                  ),
                                );
                              },
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
