import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../models/entities.dart';
import '../repositories/providers.dart';
import '../ui/error_text.dart';
import '../ui/cn_app_bar.dart';
import 'activity_details_page.dart';
import '../ui/date_format.dart';
import 'program_details_page.dart';

enum EntityType { programs, activities, attendees, sections, yearLevels }

class EntityListPage extends ConsumerStatefulWidget {
  const EntityListPage({super.key, required this.entity});

  final EntityType entity;

  @override
  ConsumerState<EntityListPage> createState() => _EntityListPageState();
}

class _EntityListPageState extends ConsumerState<EntityListPage> {
  static const _programSortKey = 'program_sort_startdate_asc_v1';

  bool _loading = false;
  String? _error;

  List<Object> _items = const [];
  bool _programSortAsc = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (widget.entity == EntityType.programs) {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      _programSortAsc = prefs.getBool(_programSortKey) ?? true;
    }
    await _loadLocal();
  }

  Future<void> _loadLocal() async {
    final repo = await ref.read(entitySyncRepositoryProvider.future);
    final items = await switch (widget.entity) {
      EntityType.programs => repo.listPrograms(),
      EntityType.activities => repo.listActivities(),
      EntityType.attendees => repo.listAttendees(),
      EntityType.sections => repo.listSections(),
      EntityType.yearLevels => repo.listYearLevels(),
    };

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

  Future<void> _refreshFromHost() async {
    final session = ref.read(authSessionProvider).value;
    if (session == null) return;

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
          ref.read(sessionNoticeProvider.notifier).state =
              'No connection. Working offline.';
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
    return Scaffold(
      appBar: cnAppBar(
        context: context,
        onLogout: () => ref.read(authSessionProvider.notifier).logout(),
        extraActions: [
          if (widget.entity == EntityType.programs)
            IconButton(
              onPressed: _loading ? null : _toggleProgramSort,
              icon: const Icon(Icons.sort),
              tooltip: _programSortAsc
                  ? 'Sort by Startdate (ASC)'
                  : 'Sort by Startdate (DESC)',
            ),
          IconButton(
            onPressed: _loading ? null : _refreshFromHost,
            icon: const Icon(Icons.refresh),
            tooltip: 'Update from host',
          ),
        ],
      ),
      body: SafeArea(
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
                separatorBuilder: (_, __) => const Divider(height: 1),
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
                          builder: (_) => ActivityDetailsPage(activity: a),
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
                    final Attendee a => ListTile(
                      title: Text(
                        a.displayName ??
                            '${a.lastName ?? ''} ${a.firstName ?? ''}'.trim(),
                      ),
                      subtitle: Text(a.code ?? ''),
                    ),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),
      ),
    );
  }
}
