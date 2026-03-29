import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../models/entities.dart';
import '../repositories/providers.dart';
import '../ui/error_text.dart';
import '../ui/cn_app_bar.dart';
import 'activity_details_page.dart';
import '../ui/date_format.dart';
import 'attendee_details_page.dart';
import 'activity_schedule_details_page.dart';
import 'program_details_page.dart';
import '../ui/screen_title_bar.dart';
import 'scan_page.dart';

enum EntityType {
  programs,
  activities,
  activitySchedules,
  attendees,
  sections,
  yearLevels,
}

class AttendeeViewItem {
  const AttendeeViewItem({
    required this.attendee,
    required this.yearLevelName,
    required this.sectionName,
  });

  final Attendee attendee;
  final String? yearLevelName;
  final String? sectionName;
}

class ActivityScheduleViewItem {
  const ActivityScheduleViewItem({
    required this.schedule,
    required this.programName,
    required this.activityName,
  });

  final ActivitySchedule schedule;
  final String? programName;
  final String? activityName;
}

class EntityListPage extends ConsumerStatefulWidget {
  const EntityListPage({super.key, required this.entity});

  final EntityType entity;

  @override
  ConsumerState<EntityListPage> createState() => _EntityListPageState();
}

class _EntityListPageState extends ConsumerState<EntityListPage> {
  static const _programSortKey = 'program_sort_startdate_asc_v1';
  static const _attendeeSortKey = 'attendee_sort_displayname_asc_v1';

  bool _loading = false;
  String? _error;

  List<Object> _items = const [];
  bool _programSortAsc = true;
  bool _attendeeSortAsc = true;
  String _attendeeQuery = '';
  TextEditingController? _attendeeSearchController;

  @override
  void initState() {
    super.initState();
    if (widget.entity == EntityType.attendees) {
      _attendeeSearchController = TextEditingController();
      _attendeeSearchController!.addListener(() {
        final next = _attendeeSearchController!.text;
        if (next == _attendeeQuery) return;
        setState(() => _attendeeQuery = next);
        _loadLocal();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (widget.entity == EntityType.programs) {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      _programSortAsc = prefs.getBool(_programSortKey) ?? true;
    }
    if (widget.entity == EntityType.attendees) {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      _attendeeSortAsc = prefs.getBool(_attendeeSortKey) ?? true;
    }
    await _loadLocal();
  }

  @override
  void dispose() {
    _attendeeSearchController?.dispose();
    super.dispose();
  }

  Future<void> _loadLocal() async {
    final repo = await ref.read(entitySyncRepositoryProvider.future);
    final items = await () async {
      switch (widget.entity) {
        case EntityType.programs:
          return await repo.listPrograms();
        case EntityType.activities:
          return await repo.listActivities();
        case EntityType.activitySchedules:
          final schedules = await repo.listActivitySchedules();
          final programs = await repo.listPrograms();
          final activities = await repo.listActivities();

          final programNameById = {for (final p in programs) p.id: p.name};
          final activityNameById = {for (final a in activities) a.id: a.name};

          return schedules
              .map(
                (s) => ActivityScheduleViewItem(
                  schedule: s,
                  programName: programNameById[s.programId],
                  activityName: activityNameById[s.activityId],
                ),
              )
              .toList(growable: false);
        case EntityType.attendees:
          final attendees = await repo.listAttendees();
          final yearLevels = await repo.listYearLevels();
          final sections = await repo.listSections();

          final yearLevelNameById = {for (final y in yearLevels) y.id: y.name};
          final sectionNameById = {for (final s in sections) s.id: s.name};

          final list = attendees
              .map(
                (a) => AttendeeViewItem(
                  attendee: a,
                  yearLevelName: yearLevelNameById[a.yearLevelId],
                  sectionName: sectionNameById[a.sectionId],
                ),
              )
              .toList(growable: false);

          final q = _attendeeQuery.trim().toLowerCase();
          final filtered = q.isEmpty
              ? list
              : list
                    .where((item) {
                      final name = (item.attendee.displayName ?? '')
                          .trim()
                          .toLowerCase();
                      final code = (item.attendee.code ?? '')
                          .trim()
                          .toLowerCase();
                      return name.contains(q) || code.contains(q);
                    })
                    .toList(growable: false);

          final sortable = filtered.toList(growable: true);
          sortable.sort((a, b) {
            final aName = (a.attendee.displayName ?? '').trim().isEmpty
                ? '${a.attendee.lastName ?? ''} ${a.attendee.firstName ?? ''}'
                      .trim()
                : a.attendee.displayName!.trim();
            final bName = (b.attendee.displayName ?? '').trim().isEmpty
                ? '${b.attendee.lastName ?? ''} ${b.attendee.firstName ?? ''}'
                      .trim()
                : b.attendee.displayName!.trim();
            final cmp = aName.toLowerCase().compareTo(bName.toLowerCase());
            return _attendeeSortAsc ? cmp : -cmp;
          });

          return sortable;
        case EntityType.sections:
          return await repo.listSections();
        case EntityType.yearLevels:
          return await repo.listYearLevels();
      }
    }();

    if (!mounted) return;
    setState(() {
      final list = items.cast<Object>().toList(growable: false);
      if (widget.entity == EntityType.programs) {
        final programs = list.whereType<Program>().toList(growable: true);
        programs.sort((a, b) {
          final aRaw = (a.startDate ?? '').trim();
          final bRaw = (b.startDate ?? '').trim();
          final aDt = aRaw.isEmpty ? null : DateTime.tryParse(aRaw);
          final bDt = bRaw.isEmpty ? null : DateTime.tryParse(bRaw);

          if (aDt == null && bDt == null) return a.name.compareTo(b.name);
          if (aDt == null) return 1;
          if (bDt == null) return -1;

          final cmp = aDt.compareTo(bDt);
          if (cmp != 0) return _programSortAsc ? cmp : -cmp;
          return a.name.compareTo(b.name);
        });
        _items = programs;
      } else {
        _items = list;
      }
      _error = null;
    });
  }

  Future<void> _toggleProgramSort() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final next = !_programSortAsc;
    await prefs.setBool(_programSortKey, next);
    if (!mounted) return;
    setState(() => _programSortAsc = next);
    await _loadLocal();
  }

  Future<void> _toggleAttendeeSort() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final next = !_attendeeSortAsc;
    await prefs.setBool(_attendeeSortKey, next);
    if (!mounted) return;
    setState(() => _attendeeSortAsc = next);
    await _loadLocal();
  }

  Future<void> _scanAndSearchAttendee() async {
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScanPage()));
    if (code == null || code.trim().isEmpty) return;

    final scanned = code.trim().replaceAll('*', '');
    _attendeeSearchController?.text = scanned;
  }

  Future<void> _refreshFromHost() async {
    final session = await () async {
      try {
        return await ref.read(authSessionProvider.notifier).sessionForNetwork();
      } catch (e) {
        if (mounted) {
          setState(() => _error = friendlyErrorText(e));
        }
        rethrow;
      }
    }();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = await ref.read(entitySyncRepositoryProvider.future);
      switch (widget.entity) {
        case EntityType.programs:
          await repo.refreshPrograms(session);
        case EntityType.activities:
          await repo.refreshActivities(session);
        case EntityType.activitySchedules:
          await repo.refreshActivitySchedules(session);
        case EntityType.attendees:
          await repo.refreshAttendees(session);
        case EntityType.sections:
          await repo.refreshSections(session);
        case EntityType.yearLevels:
          await repo.refreshYearLevels(session);
      }
      await _loadLocal();
    } catch (e) {
      if (mounted) {
        setState(() => _error = friendlyErrorText(e));
        if (_error == 'No connection') {
          ref
              .read(sessionNoticeProvider.notifier)
              .set('No connection. Working offline.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.entity) {
      EntityType.programs => 'Programs',
      EntityType.activities => 'Activities',
      EntityType.activitySchedules => 'Activity schedules',
      EntityType.attendees => 'Attendees',
      EntityType.sections => 'Sections',
      EntityType.yearLevels => 'Year levels',
    };

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
              title: title,
              actions: [
                if (widget.entity == EntityType.programs)
                  IconButton(
                    onPressed: _loading ? null : _toggleProgramSort,
                    icon: const Icon(Icons.sort),
                    tooltip: _programSortAsc
                        ? 'Sort by Startdate (ASC)'
                        : 'Sort by Startdate (DESC)',
                  ),
                if (widget.entity == EntityType.attendees)
                  IconButton(
                    onPressed: _loading ? null : _toggleAttendeeSort,
                    icon: const Icon(Icons.sort_by_alpha),
                    tooltip: _attendeeSortAsc
                        ? 'Sort by Name (ASC)'
                        : 'Sort by Name (DESC)',
                  ),
                IconButton(
                  onPressed: _loading ? null : _refreshFromHost,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Update from host',
                ),
              ],
            ),
            if (widget.entity == EntityType.attendees)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _attendeeSearchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _attendeeSearchController?.clear(),
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                        ),
                        IconButton(
                          onPressed: _scanAndSearchAttendee,
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Scan ID',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Failed to load'),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _refreshFromHost,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _items.isEmpty
                  ? const Center(child: Text('No items'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return switch (item) {
                          final Program p => ListTile(
                            title: Text(p.name),
                            subtitle: Text(
                              [
                                [
                                  formatDateTimeStringYmdHm(p.startDate),
                                  p.type ?? '',
                                ].where((s) => s.trim().isNotEmpty).join(' | '),
                                p.status ?? '',
                              ].where((s) => s.trim().isNotEmpty).join('\n'),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProgramDetailsPage(program: p),
                              ),
                            ),
                          ),
                          final Activity a => ListTile(
                            title: Text(a.name),
                            subtitle: Text(
                              [
                                [
                                  formatDateTimeStringYmdHm(a.startDate),
                                  a.activityType ?? '',
                                ].where((s) => s.trim().isNotEmpty).join(' | '),
                                a.status ?? '',
                              ].where((s) => s.trim().isNotEmpty).join('\n'),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ActivityDetailsPage(activity: a),
                              ),
                            ),
                          ),
                          final ActivityScheduleViewItem s => ListTile(
                            title: Text(
                              (s.activityName ?? '').trim().isEmpty
                                  ? s.schedule.activityId
                                  : s.activityName!,
                            ),
                            subtitle: Text(
                              [
                                [
                                  formatDateTimeStringYmdHm(s.schedule.startDate),
                                  formatDateTimeStringYmdHm(s.schedule.endDate),
                                ].where((t) => t.trim().isNotEmpty).join(' - '),
                                [
                                  s.programName ?? '',
                                  s.schedule.status ?? '',
                                ].where((t) => t.trim().isNotEmpty).join(' • '),
                                if ((s.schedule.notes ?? '').trim().isNotEmpty)
                                  s.schedule.notes!.trim(),
                              ].where((t) => t.trim().isNotEmpty).join('\n'),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActivityScheduleDetailsPage(
                                  schedule: s.schedule,
                                  programName: s.programName,
                                  activityName: s.activityName,
                                ),
                              ),
                            ),
                          ),
                          final YearLevel y => ListTile(
                            title: Text(y.name),
                            subtitle: Text(y.status ?? ''),
                          ),
                          final Section s => ListTile(
                            title: Text(s.name),
                            subtitle: Text(s.status ?? ''),
                          ),
                          final AttendeeViewItem item => ListTile(
                            title: Text(
                              (item.attendee.displayName ?? '').trim().isEmpty
                                  ? '${item.attendee.lastName ?? ''} ${item.attendee.firstName ?? ''}'
                                        .trim()
                                  : item.attendee.displayName!.trim(),
                            ),
                            subtitle: Text(
                              [
                                [
                                  item.attendee.attendeeType ?? '',
                                  item.attendee.gender ?? '',
                                ].where((s) => s.trim().isNotEmpty).join(' '),
                                [
                                  item.yearLevelName ?? '',
                                  item.sectionName ?? '',
                                ].where((s) => s.trim().isNotEmpty).join(' '),
                              ].where((s) => s.trim().isNotEmpty).join('\n'),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AttendeeDetailsPage(
                                  attendee: item.attendee,
                                  yearLevelName: item.yearLevelName,
                                  sectionName: item.sectionName,
                                ),
                              ),
                            ),
                          ),
                          _ => const SizedBox.shrink(),
                        };
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
