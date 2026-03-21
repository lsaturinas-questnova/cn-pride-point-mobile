import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entities.dart';
import '../repositories/providers.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Details')),
      body: SafeArea(
        child: repo.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (repo) {
            final a = widget.attendance;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _kv('Mobile reference', a.mobileReference),
                  _kv('Sync status', a.syncStatus.name),
                  if ((a.lastSyncError ?? '').trim().isNotEmpty) _kv('Last sync error', a.lastSyncError!),
                  _kv('Program id', a.programId),
                  _kv('Activity id', a.activityId),
                  _kv('Attendee id', a.attendeeId),
                  _kv('Checked in at', a.checkedInAt.toIso8601String()),
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

