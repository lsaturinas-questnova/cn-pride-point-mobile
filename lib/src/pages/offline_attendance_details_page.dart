import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../models/entities.dart';
import '../repositories/providers.dart';
import '../ui/date_format.dart';
import '../ui/cn_app_bar.dart';

class OfflineAttendanceDetailsPage extends ConsumerStatefulWidget {
  const OfflineAttendanceDetailsPage({super.key, required this.attendance});

  final OfflineAttendance attendance;

  @override
  ConsumerState<OfflineAttendanceDetailsPage> createState() => _OfflineAttendanceDetailsPageState();
}

class _OfflineAttendanceDetailsPageState extends ConsumerState<OfflineAttendanceDetailsPage> {
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.attendance.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(offlineAttendanceRepositoryProvider);
    final entityRepo = ref.watch(entitySyncRepositoryProvider);

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
            final a = widget.attendance;
            return entityRepo.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (entityRepo) {
                return FutureBuilder(
                  future: Future.wait([
                    entityRepo.listPrograms(),
                    entityRepo.listActivities(),
                    entityRepo.listActivitySchedules(),
                    entityRepo.listAttendees(),
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final programs = snapshot.data![0] as List<Program>;
                    final activities = snapshot.data![1] as List<Activity>;
                    final schedules = snapshot.data![2] as List<ActivitySchedule>;
                    final attendees = snapshot.data![3] as List<Attendee>;

                    final schedule = schedules
                        .where((s) => s.id == a.activityScheduleId)
                        .cast<ActivitySchedule?>()
                        .firstOrNull;

                    final programName = programs
                        .where((p) => p.id == schedule?.programId)
                        .map((p) => p.name)
                        .firstOrNull;
                    final activityName = activities
                        .where((p) => p.id == schedule?.activityId)
                        .map((p) => p.name)
                        .firstOrNull;
                    final attendeeName = attendees
                        .where((p) => p.id == a.attendeeId)
                        .map((p) => (p.displayName ?? '${p.lastName ?? ''} ${p.firstName ?? ''}'.trim()).trim())
                        .firstOrNull;

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _kv('Mobile reference', a.mobileReference),
                          _kv('Sync status', a.syncStatus.name),
                          if ((a.lastSyncError ?? '').trim().isNotEmpty)
                            _kv('Last sync error', a.lastSyncError!),
                          _kv('Activity schedule', a.activityScheduleId),
                          _kv('Program', (programName ?? schedule?.programId ?? '-').trim()),
                          _kv('Activity', (activityName ?? schedule?.activityId ?? '-').trim()),
                          _kv('Attendee', (attendeeName ?? a.attendeeId).trim()),
                          _kv('Checked in at', formatDateTimeYmdHm(a.checkedInAt)),
                          _kv('Status', a.status),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    setState(() => _saving = true);
                                    try {
                                      await repo.updateNotes(
                                        localId: a.localId,
                                        notes: _notesController.text.trim().isEmpty
                                            ? null
                                            : _notesController.text.trim(),
                                      );
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop(true);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    } finally {
                                      if (mounted) setState(() => _saving = false);
                                    }
                                  },
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(k)),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
