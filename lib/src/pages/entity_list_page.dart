import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../models/entities.dart';
import '../repositories/providers.dart';

enum EntityType { programs, activities, attendees, sections, yearLevels }

class EntityListPage extends ConsumerStatefulWidget {
  const EntityListPage({super.key, required this.entity});

  final EntityType entity;

  @override
  ConsumerState<EntityListPage> createState() => _EntityListPageState();
}

class _EntityListPageState extends ConsumerState<EntityListPage> {
  bool _loading = false;
  String? _error;

  List<Object> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocal());
  }

  String get _title {
    return switch (widget.entity) {
      EntityType.programs => 'Programs',
      EntityType.activities => 'Activities',
      EntityType.attendees => 'Attendees',
      EntityType.sections => 'Sections',
      EntityType.yearLevels => 'Year levels',
    };
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
      _items = items.cast<Object>();
      _error = null;
    });
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
        setState(() => _error = e.toString());
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
      appBar: AppBar(
        title: Text(_title),
        actions: [
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
                          p.type ?? '',
                          if (p.startDate != null || p.endDate != null)
                            '${p.startDate ?? ''} - ${p.endDate ?? ''}',
                          p.status ?? '',
                        ].where((s) => s.trim().isNotEmpty).join(' • '),
                      ),
                    ),
                    final Activity a => ListTile(
                      title: Text(a.name),
                      subtitle: Text(
                        [
                          a.activityType ?? '',
                          if (a.startDate != null || a.endDate != null)
                            '${a.startDate ?? ''} - ${a.endDate ?? ''}',
                          a.status ?? '',
                        ].where((s) => s.trim().isNotEmpty).join(' • '),
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
