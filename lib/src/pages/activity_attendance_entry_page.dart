import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../models/entities.dart';
import '../repositories/providers.dart';
import '../ui/cn_app_bar.dart';
import 'activity_attendance_page.dart';
import '../ui/date_format.dart';

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
  String? _activityScheduleId;

  @override
  void initState() {
    super.initState();
  }

  void _onProgramChanged(String? v) {
    setState(() {
      _programId = v;
      _activityScheduleId = null;
    });
  }

  void _onActivityChanged(String? v) {
    setState(() {
      _activityId = v;
      _activityScheduleId = null;
    });
  }

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
              future: Future.wait([
                repo.listPrograms(),
                repo.listActivities(),
                repo.listActivitySchedules(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final programs = snapshot.data![0] as List<Program>;
                final activities = snapshot.data![1] as List<Activity>;
                final schedules = snapshot.data![2] as List<ActivitySchedule>;

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

                final programId = (_programId ?? '').trim();
                final activityId = (_activityId ?? '').trim();
                final filteredSchedules =
                    schedules
                        .where((s) {
                          if ((s.status ?? '').toUpperCase() != 'ACTIVE') {
                            return false;
                          }
                          if (programId.isNotEmpty &&
                              s.programId != programId) {
                            return false;
                          }
                          if (activityId.isNotEmpty &&
                              s.activityId != activityId) {
                            return false;
                          }
                          return true;
                        })
                        .toList(growable: true)
                      ..sort((a, b) {
                        final aRaw = (a.startDate ?? '').trim();
                        final bRaw = (b.startDate ?? '').trim();
                        final aDt = aRaw.isEmpty
                            ? null
                            : DateTime.tryParse(aRaw);
                        final bDt = bRaw.isEmpty
                            ? null
                            : DateTime.tryParse(bRaw);
                        if (aDt == null && bDt == null) {
                          return a.id.compareTo(b.id);
                        }
                        if (aDt == null) return 1;
                        if (bDt == null) return -1;
                        return aDt.compareTo(bDt);
                      });

                if (_activityScheduleId != null &&
                    filteredSchedules.every(
                      (s) => s.id != _activityScheduleId,
                    )) {
                  _activityScheduleId = null;
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _programId,
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
                        onChanged: _onProgramChanged,
                        decoration: const InputDecoration(
                          labelText: 'Program (required)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: _activityId,
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
                        onChanged: _onActivityChanged,
                        decoration: const InputDecoration(
                          labelText: 'Activity (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredSchedules.isEmpty
                            ? const Center(
                                child: Text('No active schedules found'),
                              )
                            : ListView.separated(
                                itemCount: filteredSchedules.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final s = filteredSchedules[index];
                                  final activityName = activities
                                      .where((a) => a.id == s.activityId)
                                      .map((a) => a.name)
                                      .cast<String?>()
                                      .firstOrNull;
                                  final selected = s.id == _activityScheduleId;
                                  return ListTile(
                                    title: Text(activityName ?? s.activityId),
                                    subtitle: Text(
                                      [
                                            formatDateTimeStringYmdHm(
                                              s.startDate,
                                            ),
                                            s.status ?? '',
                                            if ((s.notes ?? '')
                                                .trim()
                                                .isNotEmpty)
                                              s.notes!.trim(),
                                          ]
                                          .where((t) => t.trim().isNotEmpty)
                                          .join('\n'),
                                    ),
                                    trailing: selected
                                        ? const Icon(Icons.check)
                                        : null,
                                    selected: selected,
                                    onTap: () => setState(
                                      () => _activityScheduleId = s.id,
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: (_activityScheduleId ?? '').isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ActivityAttendancePage(
                                      initialActivityScheduleId:
                                          _activityScheduleId!,
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
