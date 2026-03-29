import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session.dart';
import '../auth/providers.dart';
import '../models/activity_attendance.dart';
import '../models/entities.dart';
import '../repositories/offline_attendance_repository.dart';
import '../repositories/providers.dart';
import '../ui/error_text.dart';
import '../ui/cn_app_bar.dart';
import '../ui/screen_title_bar.dart';
import 'offline_attendance_details_page.dart';
import 'scan_page.dart';
import '../ui/date_format.dart';

class ActivityAttendancePage extends ConsumerStatefulWidget {
  const ActivityAttendancePage({
    super.key,
    required this.initialActivityScheduleId,
  });

  final String initialActivityScheduleId;

  @override
  ConsumerState<ActivityAttendancePage> createState() =>
      _ActivityAttendancePageState();
}

class _ActivityAttendancePageState
    extends ConsumerState<ActivityAttendancePage> {
  String? _activityScheduleId;
  final _listKey = GlobalKey<_HostAndPendingListState>();

  @override
  void initState() {
    super.initState();
    _activityScheduleId = widget.initialActivityScheduleId;
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
      appBar: cnAppBar(
        context: context,
        onLogout: () => ref.read(authSessionProvider.notifier).logout(),
        extraActions: const [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            ScreenTitleBar(
              title: 'Activity Attendance',
              actions: [
                offlineRepo.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
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
                                    final authedSession = await ref
                                        .read(authSessionProvider.notifier)
                                        .sessionForNetwork();
                                    final result = await repo.syncPending(
                                      authedSession,
                                    );
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
                                    if (friendlyErrorText(e) ==
                                        'No connection') {
                                      ref
                                          .read(sessionNoticeProvider.notifier)
                                          .set(
                                            'No connection. Working offline.',
                                          );
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(friendlyErrorText(e)),
                                      ),
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
            Expanded(
              child: entityRepo.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (entityRepo) {
                  return FutureBuilder(
                    future: Future.wait([
                      entityRepo.listPrograms(),
                      entityRepo.listActivities(),
                      entityRepo.listActivitySchedules(),
                    ]),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final programs = snapshot.data![0] as List<Program>;
                      final activities = snapshot.data![1] as List<Activity>;
                      final schedules =
                          snapshot.data![2] as List<ActivitySchedule>;

                      final scheduleId = (_activityScheduleId ?? '').trim();
                      final selectedSchedule = schedules
                          .where((s) => s.id == scheduleId)
                          .cast<ActivitySchedule?>()
                          .firstOrNull;

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (selectedSchedule == null)
                              const Text('Select an activity schedule')
                            else
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activities
                                                .where(
                                                  (a) =>
                                                      a.id ==
                                                      selectedSchedule
                                                          .activityId,
                                                )
                                                .map((a) => a.name)
                                                .cast<String?>()
                                                .firstOrNull ??
                                            selectedSchedule.activityId,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        <String>[
                                              programs
                                                      .where(
                                                        (p) =>
                                                            p.id ==
                                                            selectedSchedule
                                                                .programId,
                                                      )
                                                      .map((p) => p.name)
                                                      .cast<String?>()
                                                      .firstOrNull ??
                                                  selectedSchedule.programId,
                                              formatDateTimeStringYmdHm(
                                                selectedSchedule.startDate,
                                              ),
                                            ]
                                            .where((s) => s.trim().isNotEmpty)
                                            .join(' • '),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            offlineRepo.when(
                              loading: () => const SizedBox.shrink(),
                              error: (e, _) => Text(e.toString()),
                              data: (repo) {
                                final schedule = selectedSchedule;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: schedule == null
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
                                                  final authRepo = await ref
                                                      .read(
                                                        authRepositoryProvider
                                                            .future,
                                                      );
                                                  final username =
                                                      authRepo
                                                          .getLastUsername() ??
                                                      'admin';
                                                  await repo
                                                      .createPendingAttendanceFromScan(
                                                        programId:
                                                            schedule.programId,
                                                        activityId:
                                                            schedule.activityId,
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
                                                  _listKey.currentState
                                                      ?.reload();
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
                                                  if (friendlyErrorText(e) ==
                                                      'No connection') {
                                                    ref
                                                        .read(
                                                          sessionNoticeProvider
                                                              .notifier,
                                                        )
                                                        .set(
                                                          'No connection. Working offline.',
                                                        );
                                                  }
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        friendlyErrorText(e),
                                                      ),
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
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, _) =>
                                    Center(child: Text(e.toString())),
                                data: (repo) {
                                  final schedule = selectedSchedule;
                                  if (schedule == null) {
                                    return const Center(
                                      child: Text('Select a schedule'),
                                    );
                                  }
                                  return _HostAndPendingList(
                                    key: _listKey,
                                    activityScheduleId: schedule.id,
                                    getSessionForHost: () => ref
                                        .read(authSessionProvider.notifier)
                                        .sessionForNetwork(),
                                    repo: repo,
                                    programId: schedule.programId,
                                    activityId: schedule.activityId,
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
          ],
        ),
      ),
    );
  }
}

class _HostAndPendingList extends StatefulWidget {
  const _HostAndPendingList({
    super.key,
    required this.activityScheduleId,
    required this.getSessionForHost,
    required this.repo,
    required this.programId,
    required this.activityId,
  });

  final String activityScheduleId;
  final Future<AuthSession> Function() getSessionForHost;
  final OfflineAttendanceRepository repo;
  final String programId;
  final String? activityId;

  @override
  State<_HostAndPendingList> createState() => _HostAndPendingListState();
}

class _HostAndPendingListState extends State<_HostAndPendingList> {
  late Future<List<ActivityAttendanceListItem>> _hostFuture;
  late Future<List<LocalAttendanceViewItem>> _pendingFuture;

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
    _hostFuture = (() async {
      final session = await widget.getSessionForHost();
      return widget.repo.listFromHost(
        session: session,
        activityScheduleId: widget.activityScheduleId,
      );
    })();
    _pendingFuture = widget.repo.listNotSyncedViewItems();
  }

  void reload() {
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(_reload);
        try {
          await _hostFuture;
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyErrorText(e))));
        }
      },
      child: ListView(
        children: [
          FutureBuilder<List<LocalAttendanceViewItem>>(
            future: _pendingFuture,
            builder: (context, snap) {
              final items = snap.data ?? const [];
              final filtered = items
                  .where((p) {
                    if (p.attendance.programId != widget.programId) {
                      return false;
                    }
                    final activityId = (widget.activityId ?? '').trim();
                    if (activityId.isEmpty) return true;
                    return p.attendance.activityId == activityId;
                  })
                  .toList(growable: false);

              return ExpansionTile(
                title: Text('Pending (local) (${filtered.length})'),
                children: filtered.isEmpty
                    ? [const ListTile(title: Text('No pending records'))]
                    : filtered
                          .map(
                            (item) => ListTile(
                              title: Text(
                                (item.attendeeDisplayName ?? '').trim().isEmpty
                                    ? item.attendance.attendeeId
                                    : item.attendeeDisplayName!,
                              ),
                              subtitle: Text(
                                [
                                  [
                                        item.programName,
                                        item.activityName,
                                        item.attendance.status,
                                      ]
                                      .where(
                                        (e) => (e ?? '')
                                            .toString()
                                            .trim()
                                            .isNotEmpty,
                                      )
                                      .join(' • '),
                                  formatDateTimeYmdHm(
                                    item.attendance.checkedInAt,
                                  ),
                                ].where((s) => s.trim().isNotEmpty).join('\n'),
                              ),
                              trailing: Text(item.attendance.syncStatus.name),
                              onTap: () async {
                                final saved = await Navigator.of(context)
                                    .push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OfflineAttendanceDetailsPage(
                                              attendance: item.attendance,
                                            ),
                                      ),
                                    );
                                if (saved == true) {
                                  reload();
                                }
                              },
                              onLongPress: () async {
                                final action =
                                    await showModalBottomSheet<String>(
                                      context: context,
                                      builder: (context) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (item.attendance.syncStatus ==
                                                SyncStatus.error)
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.refresh,
                                                ),
                                                title: const Text('Resend'),
                                                onTap: () => Navigator.of(
                                                  context,
                                                ).pop('resend'),
                                              ),
                                            ListTile(
                                              leading: const Icon(Icons.delete),
                                              title: const Text('Delete'),
                                              onTap: () => Navigator.of(
                                                context,
                                              ).pop('delete'),
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.close),
                                              title: const Text('Cancel'),
                                              onTap: () => Navigator.of(
                                                context,
                                              ).pop(null),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                if (action == null) return;
                                if (!context.mounted) return;

                                if (action == 'resend') {
                                  await widget.repo.resend(
                                    localId: item.attendance.localId,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked for resend'),
                                    ),
                                  );
                                  reload();
                                  return;
                                }

                                if (action == 'delete') {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete record?'),
                                      content: const Text(
                                        'This will remove the local record.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  await widget.repo.delete(
                                    localId: item.attendance.localId,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Deleted')),
                                  );
                                  reload();
                                }
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
                  return ListTile(title: Text(friendlyErrorText(snap.error!)));
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
                            [i.activityName, i.activityScheduleId, i.status]
                                .where(
                                  (e) => (e ?? '').toString().trim().isNotEmpty,
                                )
                                .join(' • '),
                            formatDateTimeStringYmdHm(i.checkedInAt),
                          ].where((s) => s.trim().isNotEmpty).join('\n'),
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
