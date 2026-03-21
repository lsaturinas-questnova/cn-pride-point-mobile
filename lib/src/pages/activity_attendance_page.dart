import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import '../auth/providers.dart';
import '../models/activity_attendance.dart';
import '../models/entities.dart';
import '../repositories/offline_attendance_repository.dart';
import '../repositories/providers.dart';
import 'offline_attendance_details_page.dart';
import 'scan_page.dart';

class ActivityAttendancePage extends ConsumerStatefulWidget {
  const ActivityAttendancePage({
    super.key,
    required this.initialProgramId,
    this.initialActivityId,
  });

  final String initialProgramId;
  final String? initialActivityId;

  @override
  ConsumerState<ActivityAttendancePage> createState() =>
      _ActivityAttendancePageState();
}

class _ActivityAttendancePageState
    extends ConsumerState<ActivityAttendancePage> {
  String? _programId;
  String? _activityId;
  final _listKey = GlobalKey<_HostAndPendingListState>();

  @override
  void initState() {
    super.initState();
    _programId = widget.initialProgramId;
    _activityId = widget.initialActivityId;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).value;
    final entityRepo = ref.watch(entitySyncRepositoryProvider);
    final offlineRepo = ref.watch(offlineAttendanceRepositoryProvider);

    if (session == null) {
      return const Scaffold(body: Center(child: Text('No session')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Attendance'),
        actions: [
          offlineRepo.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (repo) {
              return FutureBuilder<int>(
                future: repo.pendingCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return IconButton(
                    onPressed: count == 0
                        ? null
                        : () async {
                            try {
                              final result = await repo.syncPending(session);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.hasErrors
                                        ? 'Sync completed with errors'
                                        : 'Sync completed',
                                  ),
                                ),
                              );
                              setState(() {});
                              _listKey.currentState?.reload();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    icon: const Icon(Icons.sync),
                    tooltip: count == 0
                        ? 'No pending records'
                        : 'Sync pending ($count)',
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: entityRepo.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (entityRepo) {
            return FutureBuilder(
              future: Future.wait([
                entityRepo.listPrograms(),
                entityRepo.listActivities(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final programs = snapshot.data![0] as List<Program>;
                final activities = snapshot.data![1] as List<Activity>;

                final selectedProgram = programs
                    .where((p) => p.id == _programId)
                    .cast<Program?>()
                    .firstOrNull;
                final selectedActivity = activities
                    .where((a) => a.id == _activityId)
                    .cast<Activity?>()
                    .firstOrNull;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedProgram?.id,
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
                          labelText: 'Program',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: selectedActivity?.id,
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
                      const SizedBox(height: 12),
                      offlineRepo.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => Text(e.toString()),
                        data: (repo) {
                          final scanEnabled =
                              (_programId ?? '').isNotEmpty &&
                              (_activityId ?? '').isNotEmpty;
                          return Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: !scanEnabled
                                      ? null
                                      : () async {
                                          final code =
                                              await Navigator.of(
                                                context,
                                              ).push<String>(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ScanPage(),
                                                ),
                                              );
                                          if (code == null ||
                                              code.trim().isEmpty) {
                                            return;
                                          }
                                          try {
                                            final authRepo = await ref.read(
                                              authRepositoryProvider.future,
                                            );
                                            final username =
                                                authRepo.getLastUsername() ??
                                                    'admin';
                                            await repo
                                                .createPendingAttendanceFromScan(
                                                  programId: _programId!,
                                                  activityId: _activityId!,
                                                  scannedCode: code,
                                                  username: username,
                                                );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Added pending attendance',
                                                ),
                                              ),
                                            );
                                            setState(() {});
                                            _listKey.currentState?.reload();
                                          } on AttendeeNotFoundException {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Attendee not found',
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(e.toString()),
                                              ),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scan'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: offlineRepo.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text(e.toString())),
                          data: (repo) {
                            final programId = _programId;
                            if (programId == null || programId.isEmpty) {
                              return const Center(
                                child: Text('Select a program'),
                              );
                            }
                            return _HostAndPendingList(
                              key: _listKey,
                              session: session,
                              repo: repo,
                              programId: programId,
                              activityId: _activityId,
                            );
                          },
                        ),
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

class _HostAndPendingList extends StatefulWidget {
  const _HostAndPendingList({
    super.key,
    required this.session,
    required this.repo,
    required this.programId,
    required this.activityId,
  });

  final AuthSession session;
  final OfflineAttendanceRepository repo;
  final String programId;
  final String? activityId;

  @override
  State<_HostAndPendingList> createState() => _HostAndPendingListState();
}

class _HostAndPendingListState extends State<_HostAndPendingList> {
  late Future<List<ActivityAttendanceListItem>> _hostFuture;
  late Future<List<OfflineAttendance>> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant _HostAndPendingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programId != widget.programId ||
        oldWidget.activityId != widget.activityId) {
      _reload();
    }
  }

  void _reload() {
    _hostFuture = widget.repo.listFromHost(
      session: widget.session,
      programId: widget.programId,
      activityId: widget.activityId,
    );
    _pendingFuture = widget.repo.listNotSynced();
  }

  void reload() {
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(_reload);
        await _hostFuture;
      },
      child: ListView(
        children: [
          FutureBuilder<List<OfflineAttendance>>(
            future: _pendingFuture,
            builder: (context, snap) {
              final items = snap.data ?? const [];
              final filtered = items
                  .where((p) {
                    if (p.programId != widget.programId) return false;
                    final activityId = (widget.activityId ?? '').trim();
                    if (activityId.isEmpty) return true;
                    return p.activityId == activityId;
                  })
                  .toList(growable: false);

              return ExpansionTile(
                title: Text('Pending (local) (${filtered.length})'),
                children: filtered.isEmpty
                    ? [const ListTile(title: Text('No pending records'))]
                    : filtered
                          .map(
                            (p) => ListTile(
                              title: Text(p.mobileReference.isEmpty ? p.attendeeId : p.mobileReference),
                              subtitle: Text(
                                [
                                  p.attendeeId,
                                  p.checkedInAt.toIso8601String(),
                                  if ((p.notes ?? '').trim().isNotEmpty) p.notes!,
                                ].where((e) => e.toString().trim().isNotEmpty).join(' • '),
                              ),
                              trailing: Text(p.syncStatus.name),
                              onTap: () async {
                                final saved = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => OfflineAttendanceDetailsPage(attendance: p),
                                  ),
                                );
                                if (saved == true) {
                                  reload();
                                }
                              },
                              onLongPress: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete record?'),
                                      content: const Text('This will remove the local record.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirmed != true) return;
                                await widget.repo.delete(localId: p.localId);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Deleted')),
                                );
                                reload();
                              },
                            ),
                          )
                          .toList(growable: false),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('From host'),
            trailing: IconButton(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh),
              tooltip: 'Update from host',
            ),
          ),
          FutureBuilder<List<ActivityAttendanceListItem>>(
            future: _hostFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                if (snap.hasError) {
                  return ListTile(title: Text(snap.error.toString()));
                }
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final items = snap.data!;
              if (items.isEmpty) {
                return const ListTile(title: Text('No records from host'));
              }

              return Column(
                children: items
                    .map(
                      (i) => ListTile(
                        title: Text(i.attendeeDisplayName ?? i.id),
                        subtitle: Text(
                          [
                                i.programName,
                                i.activityName,
                                i.checkedInAt,
                                i.status,
                              ]
                              .where(
                                (e) => (e ?? '').toString().trim().isNotEmpty,
                              )
                              .join(' • '),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
