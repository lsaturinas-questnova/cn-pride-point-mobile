import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entities.dart';
import '../repositories/providers.dart';
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
      appBar: AppBar(title: const Text('Activity Attendance')),
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

                if (_programId != null &&
                    programs.every((p) => p.id != _programId)) {
                  _programId = null;
                }
                if (_activityId != null &&
                    activities.every((a) => a.id != _activityId)) {
                  _activityId = null;
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _programId,
                        items: programs
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
                          ...activities.map(
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
